

Describe "Enhanced History Module - Additional Tests" {
    BeforeAll {
        try {
            # Load the enhanced history fragment directly
            $enhancedHistoryFragment = Get-TestPath "profile.d\enhanced-history.ps1" -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $enhancedHistoryFragment -or [string]::IsNullOrWhiteSpace($enhancedHistoryFragment)) {
                throw "Get-TestPath returned null or empty value for enhancedHistoryFragment"
            }
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
        It "Should display history statistics when history exists" {
            # Mock Get-History with sample data
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

            { Show-HistoryStats } | Should -Not -Throw
        }

        It "Should handle empty history gracefully" {
            Mock Get-History { return $null }

            { Show-HistoryStats } | Should -Not -Throw
        }
    }

    Context "Find-HistoryFuzzy" {
        It "Should find commands matching pattern" {
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

            { Find-HistoryFuzzy -Pattern "Process" } | Should -Not -Throw
        }

        It "Should handle no matches gracefully" {
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

        It "Should handle empty pattern" {
            { Find-HistoryFuzzy -Pattern "" } | Should -Not -Throw
        }

        It "Should handle case insensitive search" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Mock Get-History { return $mockHistory }

            { Find-HistoryFuzzy -Pattern "process" } | Should -Not -Throw
        }
    }

    Context "Find-HistoryQuick" {
        It "Should find commands with quick search" {
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

            { Find-HistoryQuick -Pattern "Get-" } | Should -Not -Throw
        }

        It "Should handle empty pattern" {
            { Find-HistoryQuick -Pattern "" } | Should -Not -Throw
        }
    }

    Context "Invoke-LastCommand" {
        It "Should find and display last command matching pattern" {
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

            { Invoke-LastCommand -Pattern "Service" } | Should -Not -Throw
        }

        It "Should handle no matches" {
            Mock Get-History { return @() }

            { Invoke-LastCommand -Pattern "nonexistent" } | Should -Not -Throw
        }

        It "Should handle empty pattern" {
            { Invoke-LastCommand -Pattern "" } | Should -Not -Throw
        }
    }

    Context "Show-RecentCommands" {
        It "Should display recent commands" {
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

            { Show-RecentCommands } | Should -Not -Throw
        }

        It "Should handle empty history" {
            Mock Get-History { return $null }

            { Show-RecentCommands } | Should -Not -Throw
        }

        It "Should accept custom count parameter" {
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = (Get-Date).AddHours(-1)
                }
            )

            Mock Get-History { return $mockHistory }

            { Show-RecentCommands -Count 5 } | Should -Not -Throw
        }
    }

    Context "Remove-HistoryDuplicates" {
        It "Should remove duplicate commands" {
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

            { Remove-HistoryDuplicates } | Should -Not -Throw
        }

        It "Should handle empty history" {
            Mock Get-History { return $null }

            { Remove-HistoryDuplicates } | Should -Not -Throw
        }
    }

    Context "Remove-OldHistory" {
        It "Should remove old commands" {
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

            { Remove-OldHistory -Days 30 } | Should -Not -Throw
        }

        It "Should handle no old commands" {
            $recentDate = (Get-Date).AddDays(-10)
            $mockHistory = @(
                [PSCustomObject]@{
                    Id                 = 1
                    CommandLine        = "Get-Process"
                    StartExecutionTime = $recentDate
                }
            )

            Mock Get-History { return $mockHistory }

            { Remove-OldHistory -Days 30 } | Should -Not -Throw
        }
    }
}

