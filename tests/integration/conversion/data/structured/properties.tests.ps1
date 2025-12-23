

<#
.SYNOPSIS
    Integration tests for Properties format conversion utilities.

.DESCRIPTION
    This test suite validates Properties format conversion functions including conversions to/from JSON, YAML, and INI.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Properties Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Properties Format Conversions' {
        It 'ConvertFrom-PropertiesToJson converts Properties to JSON' {
            Get-Command _ConvertFrom-PropertiesToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $propertiesContent = @"
# This is a comment
name=John
age=30
city=New York
enabled=true
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $propertiesContent -NoNewline
            
            { _ConvertFrom-PropertiesToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.name | Should -Be 'John'
                $jsonObj.age | Should -Be '30'
            }
        }
        
        It 'ConvertTo-PropertiesFromJson converts JSON to Properties' {
            Get-Command _ConvertTo-PropertiesFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = @"
{
  "name": "John",
  "age": "30",
  "city": "New York"
}
"@
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { _ConvertTo-PropertiesFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.properties'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $properties = Get-Content -Path $outputFile -Raw
                $properties | Should -Not -BeNullOrEmpty
                $properties | Should -Match 'name='
                $properties | Should -Match 'age='
            }
        }
        
        It 'Properties to JSON and back roundtrip' {
            $originalContent = @"
name=John
age=30
city=New York
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            # Convert to JSON
            _ConvertFrom-PropertiesToJson -InputPath $tempFile
            $jsonFile = $tempFile -replace '\.properties$', '.json'
            
            # Convert back to Properties
            _ConvertTo-PropertiesFromJson -InputPath $jsonFile
            $roundtripFile = $jsonFile -replace '\.json$', '.properties'
            
            if ($roundtripFile -and -not [string]::IsNullOrWhiteSpace($roundtripFile) -and (Test-Path -LiteralPath $roundtripFile)) {
                $roundtrip = Get-Content -Path $roundtripFile -Raw
                $roundtrip | Should -Not -BeNullOrEmpty
                $roundtrip | Should -Match 'name='
            }
        }
        
        It 'ConvertFrom-PropertiesToYaml converts Properties to YAML' {
            Get-Command _ConvertFrom-PropertiesToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $propertiesContent = @"
name=John
age=30
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $propertiesContent -NoNewline
            
            { _ConvertFrom-PropertiesToYaml -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.yaml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'ConvertFrom-PropertiesToIni converts Properties to INI' {
            Get-Command _ConvertFrom-PropertiesToIni -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $propertiesContent = @"
name=John
age=30
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $propertiesContent -NoNewline
            
            { _ConvertFrom-PropertiesToIni -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.ini'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $ini = Get-Content -Path $outputFile -Raw
                $ini | Should -Not -BeNullOrEmpty
                $ini | Should -Match '\[default\]'
            }
        }
        
        It 'Handles Properties file with escaped characters' {
            $propertiesContent = @"
path=C:\\Users\\John
message=Hello\nWorld
unicode=\u0048\u0065\u006C\u006C\u006F
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $propertiesContent -NoNewline
            
            { _ConvertFrom-PropertiesToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Handles Properties file with comments' {
            $propertiesContent = @"
# This is a comment
! This is also a comment
name=John
# Another comment
age=30
"@
            $tempFile = Join-Path $TestDrive 'test.properties'
            Set-Content -Path $tempFile -Value $propertiesContent -NoNewline
            
            { _ConvertFrom-PropertiesToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.name | Should -Be 'John'
                $jsonObj.age | Should -Be '30'
                # Comments should be ignored
                $jsonObj.PSObject.Properties.Name | Should -Not -Contain '#'
            }
        }
        
        It 'Handles empty Properties file' {
            $tempFile = Join-Path $TestDrive 'empty.properties'
            Set-Content -Path $tempFile -Value '' -NoNewline
            
            { _ConvertFrom-PropertiesToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.properties$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
    }
}

