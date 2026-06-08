<#
tests/unit/test-runner-test-config-file-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestConfigFile serialization edge cases.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestConfigFile.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestConfigFileExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestConfigFile extended scenarios' {
    Context 'ConvertTo-Hashtable' {
        It 'Converts nested objects while preserving scalar properties' {
            $input = [pscustomobject]@{
                Suite  = 'Unit'
                Nested = [pscustomobject]@{
                    Quiet     = $true
                    MaxRetries = 2
                }
            }

            $hash = ConvertTo-Hashtable -InputObject $input

            $hash.Suite | Should -Be 'Unit'
            $hash.Nested.Quiet | Should -Be $true
            $hash.Nested.MaxRetries | Should -Be 2
        }

        It 'Returns hashtables unchanged' {
            $original = @{
                Suite = 'Unit'
                Quiet = $true
            }

            (ConvertTo-Hashtable -InputObject $original) | Should -Be $original
        }

        It 'Returns scalar values unchanged' {
            ConvertTo-Hashtable -InputObject 'plain-string' | Should -Be 'plain-string'
            ConvertTo-Hashtable -InputObject 42 | Should -Be 42
        }
    }

    Context 'Save-TestConfig and Load-TestConfig' {
        It 'Creates parent directories when saving nested config paths' {
            $configPath = Join-Path $script:TempDir 'nested/runner/config.json'
            Save-TestConfig -ConfigPath $configPath -Parameters @{ Suite = 'Integration' }

            Test-Path -LiteralPath $configPath | Should -Be $true
            (Load-TestConfig -ConfigPath $configPath).Suite | Should -Be 'Integration'
        }

        It 'Round-trips numeric and boolean parameters through JSON' {
            $configPath = Join-Path $script:TempDir 'typed-params.json'
            $parameters = @{
                Suite      = 'Integration'
                MaxRetries = 4
                Quiet      = [switch]::Present
            }

            Save-TestConfig -ConfigPath $configPath -Parameters $parameters
            $loaded = Load-TestConfig -ConfigPath $configPath

            $loaded.Suite | Should -Be 'Integration'
            $loaded.MaxRetries | Should -Be 4
            $loaded.Quiet | Should -Be $true
        }

        It 'Throws when configuration JSON is malformed' {
            $configPath = Join-Path $script:TempDir 'broken.json'
            Set-Content -LiteralPath $configPath -Value '{ not valid json' -Encoding UTF8

            { Load-TestConfig -ConfigPath $configPath } | Should -Throw
        }
    }
}
