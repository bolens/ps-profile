

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

Describe "Enhanced History Module - Additional Tests" {
    BeforeAll {
        try {
            $profileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $profileDir -or [string]::IsNullOrWhiteSpace($profileDir)) {
                throw "Get-TestPath returned null or empty value for profileDir"
            }
            $env:PS_PROFILE_TEST_MODE = '1'
            $bootstrapFragment = Join-Path $profileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapFragment) {
                . $bootstrapFragment
            }

            $enhancedHistoryFragment = Join-Path $profileDir 'history-enhanced.ps1'
            if (-not (Test-Path -LiteralPath $enhancedHistoryFragment)) {
                throw "Enhanced history fragment not found at: $enhancedHistoryFragment"
            }
            Remove-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $enhancedHistoryFragment

            Set-TestReadHostResponse -Response 'n'
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize enhanced history extended tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    AfterAll {
        if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
            Restore-TestTerminalStubs
        }
    }

    Context "Show-HistoryStats" {
        It "Should call Get-History to retrieve history data" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-2)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                },
                [PSCustomObject]@{
                    Id                 = 3
                    CommandLine        = "Get-Process -Name notepad"
                    StartExecutionTime = (Get-Date).AddMinutes(-30)
                },
                [PSCustomObject]@{
                    Id                 = 4
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddMinutes(-15)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            Show-HistoryStats

            Assert-TestGetHistoryInvoked -Times 1
        }

        It "Should handle empty history gracefully" {
            Register-TestGetHistoryStub -ReturnValue $null

            { Show-HistoryStats } | Should -Not -Throw
            Assert-TestGetHistoryInvoked -Times 1
        }
    }

    Context "Find-HistoryFuzzy" {
        It "Should call Get-History and not throw when pattern matches" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddMinutes(-30)
                },
                [PSCustomObject]@{
                    Id                 = 3
                    CommandLine        = "Get-Process -Name notepad"
                    StartExecutionTime = (Get-Date).AddMinutes(-15)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            Find-HistoryFuzzy -Pattern "Process"

            Assert-TestGetHistoryInvoked -Times 1
        }

        It "Should not throw when pattern produces no matches" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            { Find-HistoryFuzzy -Pattern "nonexistent" } | Should -Not -Throw
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Register-TestGetHistoryStub -ReturnValue @()

            Find-HistoryFuzzy -Pattern ""

            Assert-TestGetHistoryInvoked -Times 0
        }

        It "Should match case-insensitively by default" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            { Find-HistoryFuzzy -Pattern "process" } | Should -Not -Throw
            Assert-TestGetHistoryInvoked -Times 1
        }
    }

    Context "Find-HistoryQuick" {
        It "Should call Get-History when pattern is provided" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddMinutes(-30)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            Find-HistoryQuick -Pattern "Get-"

            Assert-TestGetHistoryInvoked -Times 1
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Register-TestGetHistoryStub -ReturnValue @()

            Find-HistoryQuick -Pattern ""

            Assert-TestGetHistoryInvoked -Times 0
        }
    }

    Context "Invoke-LastCommand" {
        It "Should call Get-History when pattern is provided" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-2)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            Invoke-LastCommand -Pattern "Service"

            Assert-TestGetHistoryInvoked -Times 1
        }

        It "Should warn when no matches found without throwing" {
            Register-TestGetHistoryStub -ReturnValue @()

            { Invoke-LastCommand -Pattern "nonexistent" } | Should -Not -Throw
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Register-TestGetHistoryStub -ReturnValue @()

            Invoke-LastCommand -Pattern ""

            Assert-TestGetHistoryInvoked -Times 0
        }
    }

    Context "Show-RecentCommands" {
        It "Should call Get-History to retrieve recent commands" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddMinutes(-30)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            Show-RecentCommands

            Assert-TestGetHistoryInvoked -Times 1
        }

        It "Should not throw when history is null" {
            Register-TestGetHistoryStub -ReturnValue $null

            { Show-RecentCommands } | Should -Not -Throw
        }

        It "Should accept custom count parameter and pass it to history query" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory

            { Show-RecentCommands -Count 5 } | Should -Not -Throw
            Assert-TestGetHistoryInvoked -Times 1
        }
    }

    Context "Remove-HistoryDuplicates" {
        It "Should call Clear-History for duplicate entries" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-2)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                },
                [PSCustomObject]@{
                    Id                 = 3
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddMinutes(-30)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory
            Register-TestClearHistoryStub

            Remove-HistoryDuplicates

            Assert-TestClearHistoryInvoked -Times 1
        }

        It "Should not call Clear-History when history has no duplicates" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-2)
                },
                [PSCustomObject]@{
                    Id                 = 2
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory
            Register-TestClearHistoryStub

            Remove-HistoryDuplicates

            Assert-TestClearHistoryInvoked -Times 0
        }

        It "Should not throw when history is null" {
            Register-TestGetHistoryStub -ReturnValue $null

            { Remove-HistoryDuplicates } | Should -Not -Throw
        }
    }

    Context "Remove-OldHistory" {
        It "Should call Clear-History for entries older than the cutoff date" {
            $oldDate = (Get-Date).AddDays(-40)
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = $oldDate
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory
            Register-TestClearHistoryStub

            Remove-OldHistory -Days 30

            Assert-TestClearHistoryInvoked -Times 1
        }

        It "Should not call Clear-History when all entries are within the retention window" {
            $recentDate = (Get-Date).AddDays(-10)
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = $recentDate
                }
            )

            Register-TestGetHistoryStub -ReturnValue $mockHistory
            Register-TestClearHistoryStub

            Remove-OldHistory -Days 30

            Assert-TestClearHistoryInvoked -Times 0
        }
    }
}
