

<#
.SYNOPSIS
    Integration tests for Apache Avro schema evolution utilities.

.DESCRIPTION
    This test suite validates Apache Avro schema evolution functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js for Avro conversions.
    Some tests may be skipped if external dependencies are not available.
#>

Describe 'Apache Avro Schema Evolution Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check for Node.js availability
        $script:NodeJsAvailable = $false
        if (Get-Command node -ErrorAction SilentlyContinue) {
            $script:NodeJsAvailable = $true
        }
    }

    Context 'Apache Avro Schema Evolution' {
        It 'ConvertFrom-AvroToJsonWithSchemaEvolution function exists' {
            Get-Command ConvertFrom-AvroToJsonWithSchemaEvolution -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-AvroSchemaCompatibility function exists' {
            Get-Command Test-AvroSchemaCompatibility -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AvroToJsonWithSchemaEvolution requires at least one schema' {
            if (-not $script:NodeJsAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            $testFile = Join-Path $TestDrive 'test.avro'
            Set-Content -LiteralPath $testFile -Value 'test data'
            
            { ConvertFrom-AvroToJsonWithSchemaEvolution -InputPath $testFile -OutputPath (Join-Path $TestDrive 'test.json') } | Should -Throw
        }

        It 'Test-AvroSchemaCompatibility requires both schemas' {
            if (-not $script:NodeJsAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            $schemaFile = Join-Path $TestDrive 'schema.avsc'
            Set-Content -LiteralPath $schemaFile -Value '{"type": "record", "name": "Test", "fields": []}'
            
            { Test-AvroSchemaCompatibility -WriterSchemaPath $schemaFile } | Should -Throw
            { Test-AvroSchemaCompatibility -ReaderSchemaPath $schemaFile } | Should -Throw
        }
    }
}

