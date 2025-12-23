

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
    Integration tests for TOML (Tom's Obvious, Minimal Language) conversion utilities.

.DESCRIPTION
    This test suite validates TOML conversion functions including conversions
    to/from JSON, YAML, TOON, and XML formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires yq command for TOML conversions.
#>

Describe 'TOML Conversion Integration Tests' {
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
        
        # Load required helper modules (TOML depends on these for XML/TOON conversions)
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
        
        # Load TOML module directly (bypass Ensure pattern for faster test startup)
        $tomlModulePath = Join-Path $script:ProfileDir 'conversion-modules' 'data' 'structured' 'toml.ps1'
        if (Test-Path -LiteralPath $tomlModulePath) {
            . $tomlModulePath
        }
        else {
            throw "TOML module not found at: $tomlModulePath"
        }
    }

    Context 'TOML conversion utilities' {
        It 'ConvertFrom-TomlToJson converts TOML to JSON' {
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertFrom-TomlToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.toml$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-TomlFromJson converts JSON to TOML' {
            Get-Command ConvertTo-TomlFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-TomlFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.toml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $toml = Get-Content -Path $outputFile -Raw
                $toml | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-TomlToJson and ConvertTo-TomlFromJson roundtrip' {
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123`narray = [1, 2, 3]"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertFrom-TomlToJson -InputPath $tempFile } | Should -Not -Throw
            $jsonFile = $tempFile -replace '\.toml$', '.json'
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                { ConvertTo-TomlFromJson -InputPath $jsonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-TomlToYaml converts TOML to YAML' {
            Get-Command ConvertFrom-TomlToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertFrom-TomlToYaml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-TomlFromYaml converts YAML to TOML' {
            Get-Command ConvertTo-TomlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $yaml = "name: test`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            { ConvertTo-TomlFromYaml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-TomlToToon converts TOML to TOON' {
            Get-Command ConvertFrom-TomlToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertFrom-TomlToToon -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-TomlFromToon converts TOON to TOML' {
            Get-Command ConvertTo-TomlFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $toon = "name `"test`"`nvalue 123"
            $tempFile = Join-Path $TestDrive 'test.toon'
            Set-Content -Path $tempFile -Value $toon
            { ConvertTo-TomlFromToon -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-TomlToXml converts TOML to XML' {
            Get-Command ConvertFrom-TomlToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $toml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $toml
            { ConvertFrom-TomlToXml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-TomlFromXml converts XML to TOML' {
            Get-Command ConvertTo-TomlFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $xml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            { ConvertTo-TomlFromXml -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-TomlToYaml and ConvertTo-TomlFromYaml roundtrip' {
            Get-Command ConvertFrom-TomlToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertFrom-TomlToYaml -InputPath $tempFile } | Should -Not -Throw
            $yamlFile = $tempFile -replace '\.toml$', '.yaml'
            if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile) -and (Test-Path -LiteralPath $yamlFile)) {
                { ConvertTo-TomlFromYaml -InputPath $yamlFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-TomlToToon and ConvertTo-TomlFromToon roundtrip' {
            Get-Command ConvertFrom-TomlToToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertFrom-TomlToToon -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.toml$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                { ConvertTo-TomlFromToon -InputPath $toonFile } | Should -Not -Throw
            }
        }

        It 'ConvertFrom-TomlToXml and ConvertTo-TomlFromXml roundtrip' {
            Get-Command ConvertFrom-TomlToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalToml = "name = `"test`"`nvalue = 123"
            $tempFile = Join-Path $TestDrive 'test.toml'
            Set-Content -Path $tempFile -Value $originalToml
            { ConvertFrom-TomlToXml -InputPath $tempFile } | Should -Not -Throw
            $xmlFile = $tempFile -replace '\.toml$', '.xml'
            if ($xmlFile -and -not [string]::IsNullOrWhiteSpace($xmlFile) -and (Test-Path -LiteralPath $xmlFile)) {
                { ConvertTo-TomlFromXml -InputPath $xmlFile } | Should -Not -Throw
            }
        }
    }
}

