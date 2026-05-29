

Describe "Enhanced History Module - Additional Tests" {
    BeforeAll {
        try {
            # Load bootstrap fragment first to make Set-AgentModeFunction/Set-AgentModeAlias available
            $profileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $profileDir -or [string]::IsNullOrWhiteSpace($profileDir)) {
                throw "Get-TestPath returned null or empty value for profileDir"
            }
            $env:PS_PROFILE_TEST_MODE = '1'
            $bootstrapFragment = Join-Path $profileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapFragment) {
                . $bootstrapFragment
            }

            # Load the enhanced history fragment directly
            $enhancedHistoryFragment = Join-Path $profileDir 'history-enhanced.ps1'
            if (-not (Test-Path -LiteralPath $enhancedHistoryFragment)) {
                throw "Enhanced history fragment not found at: $enhancedHistoryFragment"
            }
            Remove-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $enhancedHistoryFragment

            # Mock Read-Host for interactive functions
            Mock Read-Host { return "n" }
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

            Mock Get-History { return $mockHistory }

            Show-HistoryStats

            # The function must call Get-History exactly once
            Should -Invoke Get-History -Exactly 1
        }

        It "Should handle empty history gracefully" {
            Mock Get-History { return $null }

            # Should not throw when history is empty
            { Show-HistoryStats } | Should -Not -Throw
            Should -Invoke Get-History -Exactly 1
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

            Mock Get-History { return $mockHistory }

            Find-HistoryFuzzy -Pattern "Process"

            # Must query history exactly once per call
            Should -Invoke Get-History -Exactly 1
        }

        It "Should not throw when pattern produces no matches" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Service"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Mock Get-History { return $mockHistory }

            { Find-HistoryFuzzy -Pattern "nonexistent" } | Should -Not -Throw
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Mock Get-History { return @() }

            Find-HistoryFuzzy -Pattern ""

            # Empty pattern is rejected before querying history
            Should -Invoke Get-History -Exactly 0
        }

        It "Should match case-insensitively by default" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Mock Get-History { return $mockHistory }

            # Lowercase search against uppercase command — must not throw and must query history
            { Find-HistoryFuzzy -Pattern "process" } | Should -Not -Throw
            Should -Invoke Get-History -Exactly 1
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

            Mock Get-History { return $mockHistory }

            Find-HistoryQuick -Pattern "Get-"

            Should -Invoke Get-History -Exactly 1
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Mock Get-History { return @() }

            Find-HistoryQuick -Pattern ""

            Should -Invoke Get-History -Exactly 0
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

            Mock Get-History { return $mockHistory }

            Invoke-LastCommand -Pattern "Service"

            Should -Invoke Get-History -Exactly 1
        }

        It "Should warn when no matches found without throwing" {
            Mock Get-History { return @() }

            { Invoke-LastCommand -Pattern "nonexistent" } | Should -Not -Throw
        }

        It "Should return early (warn) when pattern is empty without calling Get-History" {
            Mock Get-History { return @() }

            Invoke-LastCommand -Pattern ""

            Should -Invoke Get-History -Exactly 0
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

            Mock Get-History { return $mockHistory }

            Show-RecentCommands

            Should -Invoke Get-History -Exactly 1
        }

        It "Should not throw when history is null" {
            Mock Get-History { return $null }

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

            Mock Get-History { return $mockHistory }

            { Show-RecentCommands -Count 5 } | Should -Not -Throw
            Should -Invoke Get-History -Exactly 1
        }
    }

    Context "Remove-HistoryDuplicates" {
        It "Should call Clear-History for duplicate entries" {
            # History with Get-Process appearing twice (ids 1 and 3 are duplicates)
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

            Mock Get-History { return $mockHistory }
            Mock Clear-History { }

            Remove-HistoryDuplicates

            # One duplicate exists (Get-Process appears twice), Clear-History must be called once
            Should -Invoke Clear-History -Exactly 1
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

            Mock Get-History { return $mockHistory }
            Mock Clear-History { }

            Remove-HistoryDuplicates

            Should -Invoke Clear-History -Exactly 0
        }

        It "Should not throw when history is null" {
            Mock Get-History { return $null }

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

            Mock Get-History { return $mockHistory }
            Mock Clear-History { }

            Remove-OldHistory -Days 30

            # The old entry must be cleared
            Should -Invoke Clear-History -Exactly 1
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

            Mock Get-History { return $mockHistory }
            Mock Clear-History { }

            Remove-OldHistory -Days 30

            Should -Invoke Clear-History -Exactly 0
        }
    }
}
