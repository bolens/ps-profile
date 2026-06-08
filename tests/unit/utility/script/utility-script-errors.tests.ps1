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

            try {
                $null = pwsh -NoProfile -File $scriptPath 2>&1
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}