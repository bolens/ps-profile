<#
tests/unit/test-runner-test-config-file.tests.ps1

.SYNOPSIS
    Unit tests for TestConfigFile module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestConfigFile.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'TestConfigFileTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestConfigFile Module' {
    Context 'ConvertTo-Hashtable' {
        It 'Converts PSCustomObject graphs to hashtables' {
            $input = [pscustomobject]@{
                Suite  = 'Unit'
                Nested = [pscustomobject]@{ Quiet = $true }
            }

            $hash = ConvertTo-Hashtable -InputObject $input

            $hash.Suite | Should -Be 'Unit'
            $hash.Nested.Quiet | Should -Be $true
        }
    }

    Context 'Save-TestConfig and Load-TestConfig' {
        It 'Round-trips runner parameters through JSON' {
            $configPath = Join-Path $script:TempDir 'runner-config.json'
            $parameters = @{
                Suite     = 'Unit'
                Quiet     = [switch]::Present
                MaxRetries = 2
                Disabled  = $false
                EmptyList = @()
                NullValue = $null
            }

            Save-TestConfig -ConfigPath $configPath -Parameters $parameters
            Test-Path -LiteralPath $configPath | Should -Be $true

            $loaded = Load-TestConfig -ConfigPath $configPath
            $loaded.Suite | Should -Be 'Unit'
            $loaded.Quiet | Should -Be $true
            $loaded.MaxRetries | Should -Be 2
            $loaded.ContainsKey('Disabled') | Should -Be $false
            $loaded.ContainsKey('EmptyList') | Should -Be $false
            $loaded.ContainsKey('NullValue') | Should -Be $false
        }

        It 'Throws when configuration file is missing' {
            $missing = Join-Path $script:TempDir 'missing-config.json'
            { Load-TestConfig -ConfigPath $missing } | Should -Throw '*Configuration file not found*'
        }
    }
}
