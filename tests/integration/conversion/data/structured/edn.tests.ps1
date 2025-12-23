

<#
.SYNOPSIS
    Integration tests for EDN format conversion utilities.

.DESCRIPTION
    This test suite validates EDN format conversion functions including conversions to/from JSON and YAML.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    EDN conversions use pure PowerShell implementation.
#>

Describe 'EDN Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'EDN Format Conversions' {
        It 'ConvertFrom-EdnToJson function exists' {
            Get-Command ConvertFrom-EdnToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-EdnFromJson function exists' {
            Get-Command ConvertTo-EdnFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EdnToYaml function exists' {
            Get-Command ConvertFrom-EdnToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EdnToJson converts simple EDN map to JSON' {
            $ednContent = @"
{:name "test"
 :value 123
 :active true}
"@
            $ednFile = Join-Path $TestDrive 'test.edn'
            Set-Content -LiteralPath $ednFile -Value $ednContent -Encoding UTF8
            
            $jsonFile = Join-Path $TestDrive 'test.json'
            ConvertFrom-EdnToJson -InputPath $ednFile -OutputPath $jsonFile
            
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile)) {
                Test-Path -LiteralPath $jsonFile | Should -Be $true
            }
            $jsonContent = Get-Content -LiteralPath $jsonFile -Raw
            $jsonContent | Should -Match '"name"'
            $jsonContent | Should -Match '"test"'
        }

        It 'ConvertFrom-EdnToJson converts EDN vector to JSON' {
            $ednContent = '[1 2 3 "four" true]'
            $ednFile = Join-Path $TestDrive 'test.edn'
            Set-Content -LiteralPath $ednFile -Value $ednContent -Encoding UTF8
            
            $jsonFile = Join-Path $TestDrive 'test.json'
            ConvertFrom-EdnToJson -InputPath $ednFile -OutputPath $jsonFile
            
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile)) {
                Test-Path -LiteralPath $jsonFile | Should -Be $true
            }
            $jsonContent = Get-Content -LiteralPath $jsonFile -Raw
            $jsonContent | Should -Match '\['
        }

        It 'ConvertTo-EdnFromJson converts JSON to EDN' {
            $jsonContent = '{"name": "test", "value": 123, "active": true}'
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -LiteralPath $jsonFile -Value $jsonContent -Encoding UTF8
            
            $ednFile = Join-Path $TestDrive 'test.edn'
            ConvertTo-EdnFromJson -InputPath $jsonFile -OutputPath $ednFile
            
            if ($ednFile -and -not [string]::IsNullOrWhiteSpace($ednFile)) {
                Test-Path -LiteralPath $ednFile | Should -Be $true
            }
            $ednContent = Get-Content -LiteralPath $ednFile -Raw
            $ednContent | Should -Match ':name'
        }

        It 'ConvertFrom-EdnToYaml converts EDN to YAML' {
            $ednContent = '{:name "test" :value 123}'
            $ednFile = Join-Path $TestDrive 'test.edn'
            Set-Content -LiteralPath $ednFile -Value $ednContent -Encoding UTF8
            
            $yamlFile = Join-Path $TestDrive 'test.yaml'
            ConvertFrom-EdnToYaml -InputPath $ednFile -OutputPath $yamlFile
            
            if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile)) {
                Test-Path -LiteralPath $yamlFile | Should -Be $true
            }
        }

        It 'ConvertFrom-EdnToJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.edn'
            { ConvertFrom-EdnToJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'ConvertTo-EdnFromJson handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.json'
            { ConvertTo-EdnFromJson -InputPath $nonExistentFile } | Should -Throw
        }

        It 'EDN roundtrip conversion (EDN → JSON → EDN)' {
            $originalEdn = '{:name "test" :value 123}'
            $ednFile = Join-Path $TestDrive 'original.edn'
            Set-Content -LiteralPath $ednFile -Value $originalEdn -Encoding UTF8
            
            # EDN to JSON
            $jsonFile = Join-Path $TestDrive 'intermediate.json'
            ConvertFrom-EdnToJson -InputPath $ednFile -OutputPath $jsonFile
            
            # JSON to EDN
            $backToEdnFile = Join-Path $TestDrive 'back.edn'
            ConvertTo-EdnFromJson -InputPath $jsonFile -OutputPath $backToEdnFile
            
            if ($backToEdnFile -and -not [string]::IsNullOrWhiteSpace($backToEdnFile)) {
                Test-Path -LiteralPath $backToEdnFile | Should -Be $true
            }
        }

        It 'EDN conversion functions require InputPath parameter' {
            $testCases = @(
                'ConvertFrom-EdnToJson'
                'ConvertTo-EdnFromJson'
                'ConvertFrom-EdnToYaml'
            )
            
            foreach ($funcName in $testCases) {
                $func = Get-Command $funcName -ErrorAction SilentlyContinue
                if ($func) {
                    { & $funcName } | Should -Throw
                }
            }
        }
    }
}

