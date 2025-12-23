

<#
.SYNOPSIS
    Integration tests for edge case handling in conversions.

.DESCRIPTION
    This test suite validates handling of edge cases and boundary conditions
    in conversion functions.

.NOTES
    Tests ensure graceful handling of edge cases and malformed binary data.
#>

Describe 'Edge Case Handling Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Edge case handling' {
        It 'ConvertFrom-BsonToJson handles invalid BSON gracefully' {
            Get-Command ConvertFrom-BsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
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

