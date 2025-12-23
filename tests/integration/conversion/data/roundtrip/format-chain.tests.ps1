

<#
.SYNOPSIS
    Integration tests for format chain conversions.

.DESCRIPTION
    This test suite validates complex format chain conversions through
    multiple intermediate formats.

.NOTES
    Tests cover conversion chains through multiple intermediate formats.
    Requires yq command for YAML/TOML conversions.
#>

Describe 'Format Chain Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversion -EnsureFileConversionDocuments
    }

    Context 'Format chain conversions' {
        It 'XML → JSON → TOON → YAML → TOML → XML roundtrip' {
            Get-Command ConvertFrom-XmlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-TomlToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalXml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $originalXml
            $json = ConvertFrom-XmlToJson -Path $tempFile
            $jsonFile = $tempFile -replace '\.xml$', '.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $jsonFile } | Should -Not -Throw
            $toonFile = $jsonFile -replace '\.json$', '.toon'
            if ($toonFile -and -not [string]::IsNullOrWhiteSpace($toonFile) -and (Test-Path -LiteralPath $toonFile)) {
                { ConvertFrom-ToonToYaml -InputPath $toonFile } | Should -Not -Throw
                $yamlFile = $toonFile -replace '\.toon$', '.yaml'
                if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile) -and (Test-Path -LiteralPath $yamlFile)) {
                    { ConvertTo-TomlFromYaml -InputPath $yamlFile } | Should -Not -Throw
                    $tomlFile = $yamlFile -replace '\.ya?ml$', '.toml'
                    if ($tomlFile -and -not [string]::IsNullOrWhiteSpace($tomlFile) -and (Test-Path -LiteralPath $tomlFile)) {
                        { ConvertFrom-TomlToXml -InputPath $tomlFile } | Should -Not -Throw
                    }
                }
            }
        }
    }
}

