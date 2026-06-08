<#
tests/unit/library-write-missing-tool-warning-message-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Write-MissingToolWarning custom message handling.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -Force

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'MissingToolWarnings.ps1')
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
}

Describe 'Write-MissingToolWarning message extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Write-MissingToolWarning' {
        It 'Uses the Message parameter verbatim instead of the default format' {
            Write-MissingToolWarning `
                -Tool 'message-tool' `
                -Message 'Fully custom warning text'

            $global:CollectedMissingToolWarnings[0].Message | Should -Be 'Fully custom warning text'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -BeNullOrEmpty
        }

        It 'Trims the tool display name while preserving the normalized key' {
            Write-MissingToolWarning -Tool '  spaced-tool  ' -InstallHint 'Install manually'

            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'spaced-tool'
            $global:MissingToolWarnings.ContainsKey('spaced-tool') | Should -Be $true
        }

        It 'Updates an existing collected entry when Force is specified' {
            Write-MissingToolWarning -Tool 'force-tool' -InstallHint 'first hint'
            Write-MissingToolWarning -Tool 'force-tool' -InstallHint 'second hint' -Force

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Be 'second hint'
        }

        It 'Suppresses platform-specific tools on unsupported hosts' {
            if ((Get-Platform).IsLinux) {
                Write-MissingToolWarning -Tool 'winget' -InstallHint 'Install with: winget install example'

                $global:CollectedMissingToolWarnings.Count | Should -Be 0
            }
            else {
                Set-ItResult -Inconclusive -Because 'This assertion targets Linux hosts'
            }
        }

        It 'Clears all warning cache entries when Clear-MissingToolWarnings is called without parameters' {
            Write-MissingToolWarning -Tool 'cache-tool-a' -InstallHint 'a'
            Write-MissingToolWarning -Tool 'cache-tool-b' -InstallHint 'b'

            Clear-MissingToolWarnings | Should -Be $true

            $global:MissingToolWarnings.Count | Should -Be 0
        }
    }
}
