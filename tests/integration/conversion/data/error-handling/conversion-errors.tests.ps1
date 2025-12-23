

<#
.SYNOPSIS
    Integration tests for conversion error handling.

.DESCRIPTION
    This test suite validates error handling for conversion functions
    when encountering invalid or malformed input.

.NOTES
    Tests ensure graceful handling of conversion errors.
#>

Describe 'Conversion Error Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Conversion error handling' {
        It 'ConvertFrom-CsvToJson handles invalid CSV gracefully' {
            $invalidCsv = '"unclosed quote,name,value'
            $tempFile = Join-Path $TestDrive 'invalid.csv'
            Set-Content -Path $tempFile -Value $invalidCsv
            { ConvertFrom-CsvToJson -Path $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertTo-CsvFromJson handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json'
            $tempFile = Join-Path $TestDrive 'invalid.json'
            Set-Content -Path $tempFile -Value $invalidJson
            { ConvertTo-CsvFromJson -Path $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-XmlToJson handles invalid XML gracefully' {
            $invalidXml = '<root><unclosed><tag></root>'
            $tempFile = Join-Path $TestDrive 'invalid.xml'
            Set-Content -Path $tempFile -Value $invalidXml
            { ConvertFrom-XmlToJson -Path $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-ToonToJson handles invalid TOON gracefully' {
            Get-Command ConvertFrom-ToonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $invalidToon = "invalid: toon: content: [unclosed"
            $tempFile = Join-Path $TestDrive 'invalid.toon'
            Set-Content -Path $tempFile -Value $invalidToon
            { ConvertFrom-ToonToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }
    }
}

