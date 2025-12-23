# Load TestSupport.ps1 - ensure it's loaded before using its functions
$testSupportPath = Join-Path $PSScriptRoot '..\..\..\..\TestSupport.ps1'
if (Test-Path $testSupportPath) {
    . $testSupportPath
}
else {
    throw "TestSupport.ps1 not found at: $testSupportPath"
}

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
        
        # Load bootstrap for core functions
        $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
        if (Test-Path -LiteralPath $bootstrapPath) {
            . $bootstrapPath
        }
        
        # Load files fragment for conversion module infrastructure
        $filesPath = Join-Path $script:ProfileDir 'files.ps1'
        if (Test-Path -LiteralPath $filesPath) {
            . $filesPath
        }
        
        # Load required helper modules (TOON depends on helpers-xml.ps1 and helpers-toon.ps1)
        $helpersXmlPath = Join-Path $script:ProfileDir 'conversion-modules' 'helpers' 'helpers-xml.ps1'
        if (Test-Path -LiteralPath $helpersXmlPath) {
            . $helpersXmlPath
        }
        else {
            throw "Required helper module not found: helpers-xml.ps1"
        }
        
        $helpersToonPath = Join-Path $script:ProfileDir 'conversion-modules' 'helpers' 'helpers-toon.ps1'
        if (Test-Path -LiteralPath $helpersToonPath) {
            . $helpersToonPath
        }
        else {
            throw "Required helper module not found: helpers-toon.ps1"
        }
        
        # Load TOON module directly (bypass Ensure pattern for faster test startup)
        $toonModulePath = Join-Path $script:ProfileDir 'conversion-modules' 'data' 'structured' 'toon.ps1'
        if (Test-Path -LiteralPath $toonModulePath) {
            . $toonModulePath
        }
        else {
            throw "TOON module not found at: $toonModulePath"
        }
    }

    Context 'TOON conversion utilities' {
        It 'ConvertTo-ToonFromJson converts JSON to TOON' {
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.toon'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
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
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
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
            $outputFile = $tempFile -replace '\.toon$', '.xml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $xml = Get-Content -Path $outputFile -Raw
                $xml | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-ToonFromXml converts XML to TOON' {
            Get-Command ConvertTo-ToonFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $xmlContent = '<?xml version="1.0"?><root><name>test</name><value>123</value></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xmlContent
            { ConvertTo-ToonFromXml -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.xml$', '.toon'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $toon = Get-Content -Path $outputFile -Raw
                $toon | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-ToonFromYaml converts YAML to TOON' {
            Get-Command ConvertTo-ToonFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            
            $yamlContent = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yamlContent
            { ConvertTo-ToonFromYaml -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.ya?ml$', '.toon'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $toon = Get-Content -Path $outputFile -Raw
                $toon | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-ToonFromCsv converts CSV to TOON' {
            Get-Command ConvertTo-ToonFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $csvContent = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csvContent
            { ConvertTo-ToonFromCsv -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.csv$', '.toon'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $toon = Get-Content -Path $outputFile -Raw
                $toon | Should -Not -BeNullOrEmpty
            }
        }

        It 'TOON handles nested structures' {
            $json = '{"parent": {"child": {"key": "value"}}}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                $toon = Get-Content -Path $toonFile -Raw
                $toon | Should -Not -BeNullOrEmpty
                { ConvertFrom-ToonToJson -InputPath $toonFile } | Should -Not -Throw
            }
        }

        It 'TOON handles arrays' {
            $json = '{"items": [1, 2, 3], "names": ["alice", "bob"]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                $toon = Get-Content -Path $toonFile -Raw
                $toon | Should -Not -BeNullOrEmpty
                { ConvertFrom-ToonToJson -InputPath $toonFile } | Should -Not -Throw
            }
        }

        It 'TOON handles empty values' {
            $json = '{"key1": "", "key2": null, "key3": "value"}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                $toon = Get-Content -Path $toonFile -Raw
                $toon | Should -Not -BeNullOrEmpty
            }
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
            if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile) -and (Test-Path -LiteralPath $yamlFile)) {
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
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
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
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                { ConvertFrom-ToonToXml -InputPath $toonFile } | Should -Not -Throw
            }
        }
    }
}

