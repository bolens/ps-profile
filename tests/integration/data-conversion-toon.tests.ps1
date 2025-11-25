. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for TOON (Token-Oriented Object Notation) conversion utilities.

.DESCRIPTION
    This test suite validates TOON conversion functions including conversions
    to/from JSON, YAML, CSV, and XML formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'TOON Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'TOON conversion utilities' {
        It 'ConvertTo-ToonFromJson converts JSON to TOON' {
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.toon'
            if (Test-Path $outputFile) {
                $toon = Get-Content -Path $outputFile -Raw
                $toon | Should -Not -BeNullOrEmpty
                $toon | Should -Match 'name'
                $toon | Should -Match 'value'
            }
        }

        It 'ConvertFrom-ToonToJson converts TOON to JSON' {
            Get-Command ConvertFrom-ToonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertFrom-ToonToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.toon$', '.json'
            if (Test-Path $outputFile) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-ToonFromJson and ConvertFrom-ToonToJson roundtrip' {
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-ToonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $originalJson = '{"test": "value", "number": 42, "array": [1, 2, 3]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertFrom-ToonToJson -InputPath $toonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-ToonToYaml converts TOON to YAML' {
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertFrom-ToonToYaml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-ToonToCsv converts TOON to CSV' {
            Get-Command ConvertFrom-ToonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $toon = "-`n  name `"alice`"`n  value 123`n-`n  name `"bob`"`n  value 456"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertFrom-ToonToCsv -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-ToonToXml converts TOON to XML' {
            Get-Command ConvertFrom-ToonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertFrom-ToonToXml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-ToonFromYaml converts YAML to TOON' {
            Get-Command ConvertTo-ToonFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $yaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            { ConvertTo-ToonFromYaml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-ToonFromCsv converts CSV to TOON' {
            Get-Command ConvertTo-ToonFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $csv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertTo-ToonFromCsv -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-ToonFromXml converts XML to TOON' {
            Get-Command ConvertTo-ToonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $xml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            { ConvertTo-ToonFromXml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-ToonToYaml and ConvertTo-ToonFromYaml roundtrip' {
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalToon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $originalToon
            { ConvertFrom-ToonToYaml -InputPath $tempFile } | Should -Not -Throw
            $yamlFile = $tempFile -replace '\.toon$', '.yaml'
            if (Test-Path $yamlFile) {
                { ConvertTo-ToonFromYaml -InputPath $yamlFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-ToonToCsv and ConvertTo-ToonFromCsv roundtrip' {
            Get-Command ConvertFrom-ToonToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            { ConvertTo-ToonFromCsv -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.csv$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertFrom-ToonToCsv -InputPath $toonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-ToonToXml and ConvertTo-ToonFromXml roundtrip' {
            Get-Command ConvertFrom-ToonToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $originalXml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $originalXml
            { ConvertTo-ToonFromXml -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.xml$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertFrom-ToonToXml -InputPath $toonFile } | Should -Not -Throw
            }
        }
    }
}

