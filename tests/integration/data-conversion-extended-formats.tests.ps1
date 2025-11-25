. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for extended format conversion utilities (JSON5, JSONL, CBOR).

.DESCRIPTION
    This test suite validates extended format conversion functions including JSON5, JSONL, and CBOR formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    Requires Node.js and respective npm packages for some conversions.
#>

Describe 'Extended Format Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'JSON5 conversion utilities' {
        It 'ConvertFrom-Json5ToJson converts JSON5 to JSON' {
            Get-Command ConvertFrom-Json5ToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'json5')) {
                Set-ItResult -Skipped -Because "json5 package not installed. Install with: pnpm add -g json5"
                return
            }
            $json5 = @'
{
  // This is a comment
  "name": "test",
  "value": 42, // trailing comma
}
'@
            $tempFile = Join-Path $TestDrive 'test.json5'
            Set-Content -Path $tempFile -Value $json5
            $outputFile = Join-Path $TestDrive 'test-output.json'
            { ConvertFrom-Json5ToJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path $outputFile | Should -Be $true
            $result = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
            $result.name | Should -Be "test"
            $result.value | Should -Be 42
        }

        It 'ConvertTo-Json5FromJson converts JSON to JSON5' {
            Get-Command ConvertTo-Json5FromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'json5')) {
                Set-ItResult -Skipped -Because "json5 package not installed. Install with: pnpm add -g json5"
                return
            }
            $json = '{"name": "test", "value": 42}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = Join-Path $TestDrive 'test-output.json5'
            { ConvertTo-Json5FromJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path $outputFile | Should -Be $true
        }
    }

    Context 'JSONL conversion utilities' {
        It 'ConvertFrom-JsonLToJson converts JSONL to JSON' {
            Get-Command ConvertFrom-JsonLToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $jsonl = @'
{"name": "item1", "value": 1}
{"name": "item2", "value": 2}
{"name": "item3", "value": 3}
'@
            $tempFile = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempFile -Value $jsonl
            $outputFile = Join-Path $TestDrive 'test-output.json'
            { ConvertFrom-JsonLToJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path $outputFile | Should -Be $true
            $result = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
            $result | Should -HaveCount 3
            $result[0].name | Should -Be "item1"
        }

        It 'ConvertTo-JsonLFromJson converts JSON to JSONL' {
            Get-Command ConvertTo-JsonLFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $json = '[{"name": "item1", "value": 1}, {"name": "item2", "value": 2}]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = Join-Path $TestDrive 'test-output.jsonl'
            { ConvertTo-JsonLFromJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path $outputFile | Should -Be $true
            $lines = Get-Content -Path $outputFile
            $lines | Should -HaveCount 2
        }

        It 'Handles roundtrip JSONL to JSON to JSONL' {
            $jsonl = @'
{"name": "test", "value": 42}
{"name": "test2", "value": 100}
'@
            $tempFile = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempFile -Value $jsonl
            $jsonFile = Join-Path $TestDrive 'test-intermediate.json'
            $roundtripFile = Join-Path $TestDrive 'test-roundtrip.jsonl'
            ConvertFrom-JsonLToJson -InputPath $tempFile -OutputPath $jsonFile
            ConvertTo-JsonLFromJson -InputPath $jsonFile -OutputPath $roundtripFile
            $original = Get-Content -Path $tempFile
            $roundtrip = Get-Content -Path $roundtripFile
            $roundtrip | Should -HaveCount $original.Count
        }
    }

    Context 'CBOR conversion utilities' {
        It 'ConvertTo-CborFromJson converts JSON to CBOR' {
            Get-Command ConvertTo-CborFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '{"name": "test", "value": 42, "nested": {"key": "value"}}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = Join-Path $TestDrive 'test-output.cbor'
            { ConvertTo-CborFromJson -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path $outputFile | Should -Be $true
            (Get-Item $outputFile).Length | Should -BeGreaterThan 0
        }

        It 'Handles roundtrip JSON to CBOR to JSON' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            if (-not (Test-NpmPackageAvailable -PackageName 'cbor')) {
                Set-ItResult -Skipped -Because "cbor package not installed. Install with: pnpm add -g cbor"
                return
            }
            $json = '{"name": "test", "value": 42}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $cborFile = Join-Path $TestDrive 'test-output.cbor'
            $roundtripFile = Join-Path $TestDrive 'test-roundtrip.json'
            ConvertTo-CborFromJson -InputPath $tempFile -OutputPath $cborFile
            ConvertFrom-CborToJson -InputPath $cborFile -OutputPath $roundtripFile
            Test-Path $roundtripFile | Should -Be $true
            $result = Get-Content -Path $roundtripFile -Raw | ConvertFrom-Json
            $result.name | Should -Be "test"
            $result.value | Should -Be 42
        }
    }

    Context 'Error handling' {
        It 'Handles missing Node.js gracefully for JSON5' {
            $testFile = Join-Path $TestDrive 'nonexistent.json5'
            # Function writes errors but doesn't throw by default
            $result = ConvertFrom-Json5ToJson -InputPath $testFile -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles invalid JSONL gracefully' {
            $testFile = Join-Path $TestDrive 'test-invalid.jsonl'
            Set-Content -Path $testFile -Value "invalid json line{"
            $outputFile = Join-Path $TestDrive 'test-output.json'
            # Function writes errors but doesn't throw by default
            $result = ConvertFrom-JsonLToJson -InputPath $testFile -OutputPath $outputFile -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
