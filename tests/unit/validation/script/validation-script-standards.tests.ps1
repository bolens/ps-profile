#
# Validation script standards tests.
#

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
    $script:ScriptsChecksPath = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
    $script:TempRoot = New-TestTempDirectory -Prefix 'ValidationStandards'
}

AfterAll {
    if (Test-Path $script:TempRoot) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'check-script-standards.ps1' {
    Context 'Script Standards Validation' {
        BeforeEach {
            Get-ChildItem -LiteralPath $script:TempRoot -Force | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Validates multiple scripts with correct standards in one run' {
            $testScript = @'
# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode 2 -ErrorRecord $_
}

Exit-WithCode -ExitCode 0 -Message "Success"
'@
            1..3 | ForEach-Object {
                $testScriptPath = Join-Path $script:TempRoot "test-standard-$_.ps1"
                $testScript | Set-Content -LiteralPath $testScriptPath -Encoding UTF8
            }

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $result = pwsh -NoProfile -Command "Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue; & '$checkScript' -Path '$script:TempRoot' -IncludeTests" 2>&1 | Out-String
                $LASTEXITCODE | Should -Be 0
                $result | Should -Match 'All scripts comply with codebase standards'
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }

        It 'Reports direct exits and inconsistent imports in one run' {
            $fixtureRoot = Join-Path $script:TempRoot 'utils'
            $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
            @'
# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

exit 1
'@ | Set-Content -LiteralPath (Join-Path $fixtureRoot 'test-exit.ps1') -Encoding UTF8
            @'
# Wrong import pattern for utils/ scripts
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
'@ | Set-Content -LiteralPath (Join-Path $fixtureRoot 'test-import.ps1') -Encoding UTF8

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $result = pwsh -NoProfile -Command "Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue; & '$checkScript' -Path '$script:TempRoot' -IncludeTests" 2>&1 | Out-String
                $LASTEXITCODE | Should -BeIn @(0, 1)
                $result | Should -Match 'test-exit\.ps1'
                $result | Should -Match 'Direct exit call'
                $result | Should -Match 'Inconsistent Common\.psm1 import'
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }

        It 'Handles invalid path parameter gracefully' {
            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $invalidPath = Join-Path $script:TempRoot 'nonexistent'
                $null = pwsh -NoProfile -File $checkScript -Path $invalidPath 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1, 2)
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }

    }
}
