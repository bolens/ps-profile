#
# Utility script dependency error handling tests.
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
    $script:TempRoot = New-TestTempDirectory -Prefix 'ScriptError'
}

AfterAll {
    if (Test-Path $script:TempRoot) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Utility Script Error Handling' {
    Context 'Missing Common module' {
        It 'Exits with expected code when Common.psm1 import fails' {
            $scriptPath = Join-Path $script:TempRoot 'missing-common.ps1'
            @'
try {
    $commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
    Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
}
catch {
    Write-Error "Failed to import Common module: $($_.Exception.Message)"
    exit 2
}
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

                        $null = pwsh -NoProfile -File $scriptPath 2>&1
            $LASTEXITCODE | Should -Be 2
        }
        finally {
            Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Exit-WithCode pattern' {
        It 'Exits with validation failure code when Exit-WithCode is invoked' {
            $scriptPath = Join-Path $script:TempRoot 'exit-with-code.ps1'
            @'
enum ExitCode { Success = 0; ValidationFailure = 1; SetupError = 2; OtherError = 3 }
$EXIT_VALIDATION_FAILURE = [ExitCode]::ValidationFailure
function Exit-WithCode {
    param([object]$ExitCode, [string]$Message)
    if ($Message) { Write-Host $Message }
    exit [int]$ExitCode
}
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'validation failed'
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

                        $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 1
            $output | Should -Match 'validation failed'
        }
        finally {
            Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'ModuleImport bootstrap pattern' {
        It 'Exits with setup error when ModuleImport.psm1 is missing from scripts/lib' {
            $scriptPath = Join-Path $script:TempRoot 'missing-moduleimport.ps1'
            @'
$ErrorActionPreference = 'Stop'
$moduleImportPath = Join-Path $PSScriptRoot 'lib' 'ModuleImport.psm1'
if (-not (Test-Path -LiteralPath $moduleImportPath)) {
    Write-Error "ModuleImport.psm1 not found at: $moduleImportPath"
    exit 2
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

                        $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
            $LASTEXITCODE | Should -BeIn @(1, 2)
            $output | Should -Match 'ModuleImport\.psm1 not found'
        }
        finally {
            Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
        }
    }
}