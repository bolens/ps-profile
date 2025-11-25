. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for data conversion error handling.

.DESCRIPTION
    This test suite validates error handling for invalid input formats
    across all conversion functions.

.NOTES
    Tests ensure graceful handling of malformed input data.
#>

Describe 'Data Conversion Error Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'Data conversion error handling' {
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

        It 'ConvertFrom-TomlToJson handles invalid TOML gracefully' {
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $invalidToml = "invalid = toml content [unclosed"
            $tempFile = Join-Path $TestDrive 'invalid.toml'
            Set-Content -Path $tempFile -Value $invalidToml
            { ConvertFrom-TomlToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertTo-SuperJsonFromJson handles invalid JSON gracefully' {
            Get-Command ConvertTo-SuperJsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            $invalidJson = '{"invalid": json'
            $tempFile = Join-Path $TestDrive 'invalid.json'
            Set-Content -Path $tempFile -Value $invalidJson
            { ConvertTo-SuperJsonFromJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-SuperJsonToJson handles invalid SuperJSON gracefully' {
            Get-Command ConvertFrom-SuperJsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            $invalidSuperJson = '{"json": "invalid", "meta": {invalid}}'
            $tempFile = Join-Path $TestDrive 'invalid.superjson'
            Set-Content -Path $tempFile -Value $invalidSuperJson
            { ConvertFrom-SuperJsonToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-BsonToJson handles invalid BSON gracefully' {
            Get-Command ConvertFrom-BsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            $invalidBson = [byte[]](0x00, 0x01, 0x02, 0xFF, 0xFE)
            $tempFile = Join-Path $TestDrive 'invalid.bson'
            Set-Content -Path $tempFile -Value $invalidBson -AsByteStream
            { ConvertFrom-BsonToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-MessagePackToJson handles invalid MessagePack gracefully' {
            Get-Command ConvertFrom-MessagePackToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            $invalidMsgpack = [byte[]](0xFF, 0xFE, 0xFD)
            $tempFile = Join-Path $TestDrive 'invalid.msgpack'
            Set-Content -Path $tempFile -Value $invalidMsgpack -AsByteStream
            { ConvertFrom-MessagePackToJson -InputPath $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-AvroToJson handles invalid Avro gracefully' {
            Get-Command ConvertFrom-AvroToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            $invalidAvro = [byte[]](0x00, 0x01, 0x02)
            $tempFile = Join-Path $TestDrive 'invalid.avro'
            Set-Content -Path $tempFile -Value $invalidAvro -AsByteStream
            $schema = '{"type": "record", "name": "TestRecord", "fields": [{"name": "name", "type": "string"}]}'
            $schemaFile = Join-Path $TestDrive 'test.avsc'
            Set-Content -Path $schemaFile -Value $schema
            { ConvertFrom-AvroToJson -InputPath $tempFile -SchemaPath $schemaFile 2>$null } | Should -Not -Throw
        }
    }
}

