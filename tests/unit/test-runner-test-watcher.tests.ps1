<#
tests/unit/test-runner-test-watcher.tests.ps1

.SYNOPSIS
    Unit tests for TestWatcher watch-mode utilities.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'TestWatcher.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global

    $script:ModulePath = Join-Path $modulePath 'TestWatcher.psm1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'TestWatcherTests'
}

AfterAll {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestWatcher Module' {
    AfterEach {
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
        Stop-TestWatcherResources -Watchers @()
    }
    Context 'Test-WatcherFileMatch' {
        It 'Matches configured test file patterns' {
            Test-WatcherFileMatch -FileName 'sample.tests.ps1' -FullPath '/tmp/sample.tests.ps1' |
                Should -Be $true
        }

        It 'Matches configured source file patterns' {
            Test-WatcherFileMatch -FileName 'ProfileVersion.psm1' -FullPath '/tmp/ProfileVersion.psm1' |
                Should -Be $true
        }

        It 'Uses extension fallback when explicit patterns do not match' {
            Test-WatcherFileMatch -FileName 'helper.ps1' -FullPath '/tmp/nested/helper.ps1' -TestFiles @('*.spec.ps1') -SourceFiles @('*.custom.ps1') |
                Should -Be $true
        }

        It 'Rejects files outside PowerShell test/source extensions' {
            Test-WatcherFileMatch -FileName 'README.md' -FullPath '/tmp/README.md' |
                Should -Be $false
        }

        It 'Rejects unrelated files when custom patterns exclude them' {
            Test-WatcherFileMatch -FileName 'archive.zip' -FullPath '/tmp/archive.zip' -TestFiles @('*.tests.ps1') -SourceFiles @('*.ps1') |
                Should -Be $false
        }
    }

    Context 'Stop-TestWatcherResources' {
        It 'Disposes watchers and debounce timers without throwing' {
            $watchDir = Join-Path $script:TempRoot 'cleanup-watch'
            New-Item -ItemType Directory -Path $watchDir -Force | Out-Null

            $global:TestWatcherCleanupPath = $watchDir
            $watcher = $null
            InModuleScope TestWatcher {
                $script:TestWatcherConfig = @{
                    TestFiles       = @('*.tests.ps1')
                    SourceFiles     = @('*.ps1', '*.psm1')
                    DebounceSeconds = 1
                    OnChange        = { }
                }
                $watcher = New-RegisteredTestWatcher -WatchPath $global:TestWatcherCleanupPath
                $script:TestWatcherChangeTimer = New-Object System.Timers.Timer
                $script:TestWatcherChangeTimer.Interval = 1000
                $script:TestWatcherChangeTimer.Start()
            }

            { Stop-TestWatcherResources -Watchers @($watcher) } | Should -Not -Throw

            InModuleScope TestWatcher {
                $script:TestWatcherChangeTimer | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Start-TestWatcher path validation' {
        It 'Warns and exits when all watch paths are missing' {
            $missingPath = Join-Path $script:TempRoot 'missing-watch-path'
            $startedAt = Get-Date

            { Start-TestWatcher -WatchPaths @($missingPath) -OnChange { } -MaximumDurationSeconds 2 } |
                Should -Not -Throw

            ((Get-Date) - $startedAt).TotalSeconds | Should -BeLessThan 8
        }

        It 'Registers watchers only for existing paths' {
            $validPath = Join-Path $script:TempRoot 'valid-watch-path'
            $missingPath = Join-Path $script:TempRoot 'another-missing-watch-path'
            New-Item -ItemType Directory -Path $validPath -Force | Out-Null

            $global:TestWatcherMissingPath = $missingPath
            $global:TestWatcherValidPath = $validPath

            $watchersCreated = InModuleScope TestWatcher {
                $script:watchersCreated = 0
                Mock New-RegisteredTestWatcher -MockWith {
                    param($WatchPath, $OnChange)
                    $script:watchersCreated++
                    return New-Object System.IO.FileSystemWatcher
                }

                Start-TestWatcher -WatchPaths @($global:TestWatcherMissingPath, $global:TestWatcherValidPath) -OnChange { } -MaximumDurationSeconds 1
                return $script:watchersCreated
            }

            $watchersCreated | Should -Be 1
        }
    }

    Context 'Start-TestWatcher bounded runtime' {
        It 'Exits automatically when MaximumDurationSeconds elapses' {
            $watchDir = Join-Path $script:TempRoot 'bounded-runtime'
            New-Item -ItemType Directory -Path $watchDir -Force | Out-Null
            $startedAt = Get-Date

            Start-TestWatcher -WatchPaths @($watchDir) -OnChange { } -MaximumDurationSeconds 2

            $elapsed = ((Get-Date) - $startedAt).TotalSeconds
            $elapsed | Should -BeGreaterOrEqual 2
            $elapsed | Should -BeLessThan 8
        }
    }

    Context 'Start-TestWatcher change handling' {
        It 'Invokes OnChange after a debounced test file change' {
            $watchDir = New-TestTempDirectory -Prefix 'TestWatcherChange'
            $markerPath = Join-Path $watchDir 'on-change-marker.txt'
            $testFile = Join-Path $watchDir 'sample.tests.ps1'
            Set-Content -LiteralPath $testFile -Value 'initial' -Encoding UTF8

            $writePowerShell = [powershell]::Create()
            $null = $writePowerShell.AddScript({
                    param($Path)
                    Start-Sleep -Seconds 2
                    [System.IO.File]::WriteAllText($Path, 'changed content')
                }).AddArgument($testFile)
            $writeHandle = $writePowerShell.BeginInvoke()

            try {
                Start-TestWatcher `
                    -WatchPaths @($watchDir) `
                    -DebounceSeconds 1 `
                    -MaximumDurationSeconds 10 `
                    -OnChange {
                        Set-Content -LiteralPath $markerPath -Value 'triggered' -Encoding UTF8
                    }

                Test-Path -LiteralPath $markerPath | Should -Be $true
                (Get-Content -LiteralPath $markerPath -Raw).Trim() | Should -Be 'triggered'
            }
            finally {
                if ($writeHandle -and -not $writeHandle.IsCompleted) {
                    $writeHandle.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(5)) | Out-Null
                }

                try {
                    if ($writeHandle) {
                        $writePowerShell.EndInvoke($writeHandle) | Out-Null
                    }
                }
                catch {
                    # Background writer may already be disposed after watcher exit.
                }

                $writePowerShell.Dispose()
                Remove-Item -LiteralPath $watchDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Ignores changes to files outside watch patterns' {
            $watchDir = New-TestTempDirectory -Prefix 'TestWatcherIgnore'
            $markerPath = Join-Path $watchDir 'ignored-change-marker.txt'
            $ignoredFile = Join-Path $watchDir 'notes.txt'
            Set-Content -LiteralPath $ignoredFile -Value 'initial' -Encoding UTF8

            $writePowerShell = [powershell]::Create()
            $null = $writePowerShell.AddScript({
                    param($Path)
                    Start-Sleep -Seconds 1
                    [System.IO.File]::WriteAllText($Path, 'changed notes')
                }).AddArgument($ignoredFile)
            $writeHandle = $writePowerShell.BeginInvoke()

            try {
                Start-TestWatcher `
                    -WatchPaths @($watchDir) `
                    -TestFiles @('*.tests.ps1') `
                    -SourceFiles @('*.ps1', '*.psm1') `
                    -DebounceSeconds 1 `
                    -MaximumDurationSeconds 6 `
                    -OnChange {
                        Set-Content -LiteralPath $markerPath -Value 'triggered' -Encoding UTF8
                    }

                Test-Path -LiteralPath $markerPath | Should -Be $false
            }
            finally {
                if ($writeHandle -and -not $writeHandle.IsCompleted) {
                    $writeHandle.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(5)) | Out-Null
                }

                try {
                    if ($writeHandle) {
                        $writePowerShell.EndInvoke($writeHandle) | Out-Null
                    }
                }
                catch {
                    # Background writer may already be disposed after watcher exit.
                }

                $writePowerShell.Dispose()
                Remove-Item -LiteralPath $watchDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
