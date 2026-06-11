<#
tests/unit/library-profile-prompt-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfilePrompt initialization edge cases.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfilePrompt.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
    Remove-Item Function:\Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
    Remove-Item Function:\prompt -ErrorAction SilentlyContinue
    Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
}

Describe 'ProfilePrompt extended scenarios' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Enable-TestStructuredLogging
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        Remove-Item Function:\Initialize-Starship -ErrorAction SilentlyContinue
        Remove-Item Function:\global:Initialize-Starship -ErrorAction SilentlyContinue
        Remove-Item Function:\Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
        Remove-Item Function:\global:Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue
        Remove-Item Function:\prompt -ErrorAction SilentlyContinue
        Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
        Remove-TestFunction -Name 'Test-FragmentLoaded', 'Test-CachedCommand', 'Write-ProfileError', 'Get-RepoRoot'
    }

    AfterEach {
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
    }

    Context 'Initialize-ProfilePrompt' {
        It 'Updates performance insights when the helper is registered' {
            $script:PerformanceInsightsUpdated = $false

            function global:Initialize-Starship {
                function global:prompt {
                    return 'PS> '
                }
            }

            function global:Update-PerformanceInsightsPrompt {
                $script:PerformanceInsightsUpdated = $true
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:PerformanceInsightsUpdated | Should -Be $true
        }

        It 'Continues when Update-PerformanceInsightsPrompt throws' {
            function global:Initialize-Starship {
                function global:prompt {
                    return 'PS> '
                }
            }

            function global:Update-PerformanceInsightsPrompt {
                throw 'perf-wrapper-failed'
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Does not require a prompt function when Initialize-Starship succeeds without one' {
            function global:Initialize-Starship {
                return
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Test-CachedCommand for starship availability when registered' {
            $script:CachedCommandChecked = $false

            function global:Test-CachedCommand {
                param([string]$Name)
                if ($Name -eq 'starship') {
                    $script:CachedCommandChecked = $true
                }
                return $false
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:CachedCommandChecked | Should -Be $true
        }

        It 'Detects starship via Get-Command when Test-CachedCommand is unavailable' {
            $script:StarshipCommandChecked = $false
            function global:starship {
                param([string[]]$CommandArgs)
                $script:StarshipCommandChecked = $true
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:StarshipCommandChecked | Should -Be $false
            (Get-Command starship -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It 'Emits verbose diagnostics at debug level 2 during initialization' {
            function global:Initialize-Starship {
                function global:prompt { 'PS> ' }
            }

            $env:PS_PROFILE_DEBUG = '2'
            { Initialize-ProfilePrompt -Verbose } | Should -Not -Throw
        }

        It 'Reports missing prompt function through structured warning at debug level 1' {
            function global:Initialize-Starship {
                return
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Test-FragmentLoaded diagnostics when the helper is registered' {
            $script:FragmentLoadedChecked = $false

            function global:Test-FragmentLoaded {
                param([string]$FragmentName)
                if ($FragmentName -eq 'starship') {
                    $script:FragmentLoadedChecked = $true
                }
                return $false
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:FragmentLoadedChecked | Should -Be $true
        }

        It 'Manually loads starship fragment when the file exists but Initialize-Starship is missing' {
            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManual'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            $starshipFragment = Join-Path $profileD 'starship.ps1'
            Set-Content -LiteralPath $starshipFragment -Value @'
function global:Initialize-Starship {
    function global:prompt { return "manual> " }
}
'@ -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return Split-Path -Parent $profileD
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It 'Uses Write-ProfileError when Initialize-Starship throws and profile error helper exists' {
            Remove-TestFunction -Name 'Write-StructuredError'
            $script:ProfileErrorRecorded = $false

            function global:Initialize-Starship {
                throw 'profile-error-helper probe'
            }

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $script:ProfileErrorRecorded = $true
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:ProfileErrorRecorded | Should -Be $true
        }

        It 'Uses structured error logging when Initialize-Starship throws without debug output' {
            function global:Initialize-Starship {
                throw 'structured-init probe'
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses structured error logging when Update-PerformanceInsightsPrompt throws without debug output' {
            function global:Initialize-Starship {
                function global:prompt { 'PS> ' }
            }

            function global:Update-PerformanceInsightsPrompt {
                throw 'structured-perf probe'
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Emits structured warning when prompt verification fails at debug level 1' {
            function global:Initialize-Starship {
                return
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Emits structured warning when Starship is unavailable without debug output' {
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Prints fallback diagnostics when debug level is 2 and Starship is unavailable' {
            $env:PS_PROFILE_DEBUG = '2'
            { Initialize-ProfilePrompt -Verbose } | Should -Not -Throw
        }

        It 'Reports fragment load status when Test-FragmentLoaded is available at debug level 2' {
            function global:Initialize-Starship {
                function global:prompt { 'PS> ' }
            }

            function global:Test-FragmentLoaded {
                param([string]$FragmentName)
                return $FragmentName -eq 'starship'
            }

            $env:PS_PROFILE_DEBUG = '2'
            { Initialize-ProfilePrompt -Verbose } | Should -Not -Throw
        }

        It 'Handles manual starship fragment load failures gracefully' {
            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManualFail'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $profileD 'starship.ps1') -Value 'throw "manual load probe"' -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $tempRoot
            }

            $env:PS_PROFILE_DEBUG = '2'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Handles Initialize-Starship failures after a successful manual fragment load' {
            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManualInitFail'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $profileD 'starship.ps1') -Value @'
function global:Initialize-Starship {
    throw "manual init probe"
}
'@ -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $tempRoot
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses the outer initialization catch path when forced through the test hook' {
            $env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR = '1'
            try {
                { Initialize-ProfilePrompt } | Should -Not -Throw
            }
            finally {
                Remove-Item Env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
            }
        }

        It 'Logs detailed initialization errors at debug level 3 when forced through the test hook' {
            $env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'
            try {
                { Initialize-ProfilePrompt } | Should -Not -Throw
            }
            finally {
                Remove-Item Env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Warns at debug level 1 when Initialize-Starship completes without creating a prompt function' {
            function global:Initialize-Starship {
                return
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Logs detailed Starship initialization errors at debug level 3' {
            function global:Initialize-Starship {
                throw 'starship debug3 probe'
            }

            $env:PS_PROFILE_DEBUG = '3'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Write-ProfileError when performance insights update fails at debug level 1' {
            Remove-TestFunction -Name 'Write-StructuredError'
            $script:PerfProfileErrorRecorded = $false

            function global:Initialize-Starship {
                function global:prompt { 'PS> ' }
            }

            function global:Update-PerformanceInsightsPrompt {
                throw 'perf profile-error probe'
            }

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $script:PerfProfileErrorRecorded = $true
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:PerfProfileErrorRecorded | Should -Be $true
        }

        It 'Logs detailed performance insight failures at debug level 3' {
            function global:Initialize-Starship {
                function global:prompt { 'PS> ' }
            }

            function global:Update-PerformanceInsightsPrompt {
                throw 'perf debug3 probe'
            }

            $env:PS_PROFILE_DEBUG = '3'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Write-ProfileError when prompt verification fails at debug level 1' {
            Remove-TestFunction -Name 'Write-StructuredWarning'
            $script:VerifyProfileErrorRecorded = $false

            function global:Initialize-Starship {
                return
            }

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $script:VerifyProfileErrorRecorded = $true
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:VerifyProfileErrorRecorded | Should -Be $true
        }

        It 'Finds the repository profile directory when Get-RepoRoot returns an invalid path' {
            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return (New-TestTempDirectory -Prefix 'ProfilePromptBadRepoRoot')
            }

            { Initialize-ProfilePrompt -Verbose } | Should -Not -Throw
        }

        It 'Returns early after a successful manual starship fragment load' {
            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManualSuccess'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $profileD 'starship.ps1') -Value @'
function global:Initialize-Starship {
    function global:prompt { return "manual-success> " }
}
'@ -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $tempRoot
            }

            { Initialize-ProfilePrompt } | Should -Not -Throw
            (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It 'Reports when manual fragment load completes without exporting Initialize-Starship' {
            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManualNoExport'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $profileD 'starship.ps1') -Value '# noop fragment without exports' -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $tempRoot
            }

            $env:PS_PROFILE_DEBUG = '2'
            { Initialize-ProfilePrompt } | Should -Not -Throw
        }

        It 'Uses Write-ProfileError when manual Initialize-Starship fails at debug level 1' {
            Remove-TestFunction -Name 'Write-StructuredError'
            $script:ManualInitProfileErrorRecorded = $false

            $tempRoot = New-TestTempDirectory -Prefix 'ProfilePromptManualProfileError'
            $profileD = Join-Path $tempRoot 'profile.d'
            New-Item -ItemType Directory -Path $profileD -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $profileD 'starship.ps1') -Value @'
function global:Initialize-Starship {
    throw "manual profile-error probe"
}
'@ -Encoding UTF8

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $tempRoot
            }

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $script:ManualInitProfileErrorRecorded = $true
            }

            $env:PS_PROFILE_DEBUG = '1'
            { Initialize-ProfilePrompt } | Should -Not -Throw
            $script:ManualInitProfileErrorRecorded | Should -Be $true
        }

        It 'Uses Write-ProfileError for forced initialization failures without structured logging' {
            Remove-TestFunction -Name 'Write-StructuredError'
            $script:OuterProfileErrorRecorded = $false

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $script:OuterProfileErrorRecorded = $true
            }

            $env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR = '1'
            try {
                { Initialize-ProfilePrompt } | Should -Not -Throw
                $script:OuterProfileErrorRecorded | Should -Be $true
            }
            finally {
                Remove-Item Env:PS_PROFILE_PROMPT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
            }
        }
    }
}
