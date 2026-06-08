<#
tests/unit/library-json-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for JsonUtilities read/write edge cases.
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
    Import-Module (Join-Path $libPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'JsonUtilitiesExtended'
}

AfterAll {
    Remove-Module JsonUtilities -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'JsonUtilities extended scenarios' {
    Context 'Read-JsonFile' {
        It 'Reads JSON arrays from disk' {
            $file = Join-Path $script:TempRoot 'array.json'
            Set-Content -LiteralPath $file -Value '["alpha","beta","gamma"]' -Encoding UTF8

            $result = @(Read-JsonFile -Path $file)

            @($result).Count | Should -Be 3
            $result | Should -Contain 'alpha'
        }

        It 'Reads nested objects with null values' {
            $file = Join-Path $script:TempRoot 'nested-null.json'
            @'
{
  "Name": "sample",
  "Optional": null
}
'@ | Set-Content -LiteralPath $file -Encoding UTF8

            $result = Read-JsonFile -Path $file

            $result.Name | Should -Be 'sample'
            $result.Optional | Should -BeNullOrEmpty
        }

        It 'Throws for missing files when ErrorAction is Stop' {
            $missing = Join-Path $script:TempRoot 'missing.json'

            { Read-JsonFile -Path $missing -ErrorAction Stop } | Should -Throw '*JSON file not found*'
        }
    }

    Context 'Write-JsonFile' {
        It 'Persists Unicode text without corruption' {
            $file = Join-Path $script:TempRoot 'unicode.json'
            $payload = @{
                Greeting = 'héllo 世界'
                Symbol   = '✓'
            }

            Write-JsonFile -Path $file -InputObject $payload
            $result = Read-JsonFile -Path $file

            $result.Greeting | Should -Be 'héllo 世界'
            $result.Symbol | Should -Be '✓'
        }

        It 'Honors custom serialization depth for deeply nested objects' {
            $file = Join-Path $script:TempRoot 'depth.json'
            $payload = @{
                Level1 = @{
                    Level2 = @{
                        Level3 = @{
                            Value = 'deep'
                        }
                    }
                }
            }

            Write-JsonFile -Path $file -InputObject $payload -Depth 2
            $raw = Get-Content -LiteralPath $file -Raw

            $raw | Should -Match 'Level1'
            $raw | Should -Not -Match '"Value": "deep"'
        }
    }
}
