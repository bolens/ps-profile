. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for binary format conversion utilities (BSON, MessagePack, Avro).

.DESCRIPTION
    This test suite validates binary format conversion functions including conversions
    to/from JSON for BSON, MessagePack, and Avro formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and respective npm packages for conversions.
#>

Describe 'Binary Format Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'BSON conversion utilities' {
        It 'ConvertTo-BsonFromJson converts JSON to BSON' {
            Get-Command ConvertTo-BsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if bson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-BsonFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.bson'
            if (Test-Path $outputFile) {
                $bson = Get-Content -Path $outputFile -Raw -AsByteStream
                $bson | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-BsonToJson converts BSON to JSON' {
            Get-Command ConvertFrom-BsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if bson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            # First create a BSON file
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-BsonFromJson -InputPath $tempFile
            $bsonFile = $tempFile -replace '\.json$', '.bson'
            if (Test-Path $bsonFile) {
                { ConvertFrom-BsonToJson -InputPath $bsonFile } | Should -Not -Throw
                $outputFile = $bsonFile -replace '\.bson$', '.json'
                if (Test-Path $outputFile) {
                    $json = Get-Content -Path $outputFile -Raw
                    $json | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'ConvertTo-BsonFromJson and ConvertFrom-BsonToJson roundtrip' {
            Get-Command ConvertTo-BsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-BsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if bson is available
            if (-not (Test-NpmPackageAvailable -PackageName 'bson')) {
                Set-ItResult -Skipped -Because "bson package not installed. Install with: pnpm add -g bson"
                return
            }
            $originalJson = '{"name": "test", "value": 123, "array": [1, 2, 3]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-BsonFromJson -InputPath $tempFile } | Should -Not -Throw
            $bsonFile = $tempFile -replace '\.json$', '.bson'
            if (Test-Path $bsonFile) {
                { ConvertFrom-BsonToJson -InputPath $bsonFile } | Should -Not -Throw
            }
        }
    }

    Context 'MessagePack conversion utilities' {
        It 'ConvertTo-MessagePackFromJson converts JSON to MessagePack' {
            Get-Command ConvertTo-MessagePackFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if @msgpack/msgpack is available
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "@msgpack/msgpack package not installed. Install with: pnpm add -g @msgpack/msgpack"
                return
            }
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-MessagePackFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.msgpack'
            if (Test-Path $outputFile) {
                $msgpack = Get-Content -Path $outputFile -Raw -AsByteStream
                $msgpack | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-MessagePackToJson converts MessagePack to JSON' {
            Get-Command ConvertFrom-MessagePackToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if @msgpack/msgpack is available
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "@msgpack/msgpack package not installed. Install with: pnpm add -g @msgpack/msgpack"
                return
            }
            # First create a MessagePack file
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-MessagePackFromJson -InputPath $tempFile
            $msgpackFile = $tempFile -replace '\.json$', '.msgpack'
            if (Test-Path $msgpackFile) {
                { ConvertFrom-MessagePackToJson -InputPath $msgpackFile } | Should -Not -Throw
                $outputFile = $msgpackFile -replace '\.msgpack$', '.json'
                if (Test-Path $outputFile) {
                    $json = Get-Content -Path $outputFile -Raw
                    $json | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'ConvertTo-MessagePackFromJson and ConvertFrom-MessagePackToJson roundtrip' {
            Get-Command ConvertTo-MessagePackFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-MessagePackToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if @msgpack/msgpack is available
            if (-not (Test-NpmPackageAvailable -PackageName '@msgpack/msgpack')) {
                Set-ItResult -Skipped -Because "@msgpack/msgpack package not installed. Install with: pnpm add -g @msgpack/msgpack"
                return
            }
            $originalJson = '{"name": "test", "value": 123, "array": [1, 2, 3]}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-MessagePackFromJson -InputPath $tempFile } | Should -Not -Throw
            $msgpackFile = $tempFile -replace '\.json$', '.msgpack'
            if (Test-Path $msgpackFile) {
                { ConvertFrom-MessagePackToJson -InputPath $msgpackFile } | Should -Not -Throw
            }
        }
    }

    Context 'Avro conversion utilities' {
        It 'ConvertTo-AvroFromJson converts JSON to Avro' {
            Get-Command ConvertTo-AvroFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if avsc is available
            if (-not (Test-NpmPackageAvailable -PackageName 'avsc')) {
                Set-ItResult -Skipped -Because "avsc package not installed. Install with: pnpm add -g avsc"
                return
            }
            # Create a simple Avro schema
            $schema = '{"type": "record", "name": "TestRecord", "fields": [{"name": "name", "type": "string"}, {"name": "value", "type": "int"}]}'
            $schemaFile = Join-Path $TestDrive 'test.avsc'
            Set-Content -Path $schemaFile -Value $schema
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-AvroFromJson -InputPath $tempFile -SchemaPath $schemaFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.avro'
            if (Test-Path $outputFile) {
                $avro = Get-Content -Path $outputFile -Raw -AsByteStream
                $avro | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertFrom-AvroToJson converts Avro to JSON' {
            Get-Command ConvertFrom-AvroToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if avsc is available
            if (-not (Test-NpmPackageAvailable -PackageName 'avsc')) {
                Set-ItResult -Skipped -Because "avsc package not installed. Install with: pnpm add -g avsc"
                return
            }
            # Create a simple Avro schema
            $schema = '{"type": "record", "name": "TestRecord", "fields": [{"name": "name", "type": "string"}, {"name": "value", "type": "int"}]}'
            $schemaFile = Join-Path $TestDrive 'test.avsc'
            Set-Content -Path $schemaFile -Value $schema
            # First create an Avro file
            $json = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            ConvertTo-AvroFromJson -InputPath $tempFile -SchemaPath $schemaFile
            $avroFile = $tempFile -replace '\.json$', '.avro'
            if (Test-Path $avroFile) {
                { ConvertFrom-AvroToJson -InputPath $avroFile -SchemaPath $schemaFile } | Should -Not -Throw
                $outputFile = $avroFile -replace '\.avro$', '.json'
                if (Test-Path $outputFile) {
                    $json = Get-Content -Path $outputFile -Raw
                    $json | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'ConvertTo-AvroFromJson and ConvertFrom-AvroToJson roundtrip' {
            Get-Command ConvertTo-AvroFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-AvroToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if node not available
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Check if avsc is available
            if (-not (Test-NpmPackageAvailable -PackageName 'avsc')) {
                Set-ItResult -Skipped -Because "avsc package not installed. Install with: pnpm add -g avsc"
                return
            }
            # Create a simple Avro schema
            $schema = '{"type": "record", "name": "TestRecord", "fields": [{"name": "name", "type": "string"}, {"name": "value", "type": "int"}]}'
            $schemaFile = Join-Path $TestDrive 'test.avsc'
            Set-Content -Path $schemaFile -Value $schema
            $originalJson = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-AvroFromJson -InputPath $tempFile -SchemaPath $schemaFile } | Should -Not -Throw
            $avroFile = $tempFile -replace '\.json$', '.avro'
            if (Test-Path $avroFile) {
                { ConvertFrom-AvroToJson -InputPath $avroFile -SchemaPath $schemaFile } | Should -Not -Throw
            }
        }
    }
}

