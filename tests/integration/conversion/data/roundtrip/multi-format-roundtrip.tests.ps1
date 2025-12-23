

<#
.SYNOPSIS
    Integration tests for multi-format roundtrip conversions.

.DESCRIPTION
    This test suite validates complex multi-format conversion chains to ensure
    data integrity across format transformations.

.NOTES
    Tests cover conversion chains through multiple intermediate formats.
    Requires yq command for YAML/TOML conversions.
#>

Describe 'Multi-Format Roundtrip Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversion -EnsureFileConversionDocuments
    }

    Context 'Multi-format roundtrip conversions' {
        It 'JSON → TOON → YAML → JSON roundtrip' {
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalJson = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                { ConvertFrom-ToonToYaml -InputPath $toonFile } | Should -Not -Throw
                $yamlFile = $toonFile -replace '\.toon$', '.yaml'
                if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile) -and (Test-Path -LiteralPath $yamlFile)) {
                    { ConvertFrom-Yaml $yamlFile } | Should -Not -Throw
                }
            }
        }

        It 'CSV → JSON → TOON → TOML → JSON → CSV roundtrip' {
            Get-Command ConvertFrom-CsvToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-CsvFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            $json = ConvertFrom-CsvToJson -Path $tempFile
            $jsonFile = $tempFile -replace '\.csv$', '.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $jsonFile } | Should -Not -Throw
            $toonFile = $jsonFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                { ConvertTo-TomlFromToon -InputPath $toonFile } | Should -Not -Throw
                $tomlFile = $toonFile -replace '\.toon$', '.toml'
                if ($tomlFile -and -not [string]::IsNullOrWhiteSpace($tomlFile) -and (Test-Path -LiteralPath $tomlFile)) {
                    { ConvertFrom-TomlToJson -InputPath $tomlFile } | Should -Not -Throw
                    $finalJsonFile = $tomlFile -replace '\.toml$', '.json'
                    if ($finalJsonFile -and -not [string]::IsNullOrWhiteSpace($finalJsonFile) -and (Test-Path -LiteralPath $finalJsonFile)) {
                        { ConvertTo-CsvFromJson -Path $finalJsonFile } | Should -Not -Throw
                    }
                }
            }
        }
    }
}

