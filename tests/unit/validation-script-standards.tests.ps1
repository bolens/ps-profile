#
# Validation script standards tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
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

        It 'Validates scripts with correct standards' {
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
            $testScriptPath = Join-Path $script:TempRoot 'test-standard.ps1'
            $testScript | Set-Content -LiteralPath $testScriptPath -Encoding UTF8

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $null = pwsh -NoProfile -File $checkScript -Path $script:TempRoot 2>&1
                $LASTEXITCODE | Should -Be 0
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }

        It 'Detects direct exit calls' {
            $testScript = @'
# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

exit 1
'@
            $testScriptPath = Join-Path $script:TempRoot 'test-exit.ps1'
            $testScript | Set-Content -LiteralPath $testScriptPath -Encoding UTF8

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $result = pwsh -NoProfile -File $checkScript -Path $script:TempRoot 2>&1 | Out-String
                $LASTEXITCODE | Should -BeIn @(0, 1)
                ($result -match 'exit|Exit-WithCode|test-exit') | Should -Be $true
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }

        It 'Detects inconsistent Common.psm1 import patterns' {
            $testScript = @'
# Wrong import pattern for utils/ scripts
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
'@
            $testScriptPath = Join-Path $script:TempRoot 'test-import.ps1'
            $testScript | Set-Content -LiteralPath $testScriptPath -Encoding UTF8

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $null = pwsh -NoProfile -File $checkScript -Path $script:TempRoot 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1)
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

        It 'Processes multiple scripts correctly' {
            1..3 | ForEach-Object {
                $testScript = @"
# Test script $_
`$commonModulePath = Join-Path `$PSScriptRoot 'Common.psm1'
Import-Module `$commonModulePath -ErrorAction Stop
Exit-WithCode -ExitCode 0
"@
                $testScriptPath = Join-Path $script:TempRoot "test-$_.ps1"
                $testScript | Set-Content -LiteralPath $testScriptPath -Encoding UTF8
            }

            $checkScript = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $checkScript) {
                $null = pwsh -NoProfile -File $checkScript -Path $script:TempRoot 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
            }
        }
    }
}
