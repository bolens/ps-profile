

<#
.SYNOPSIS
    Integration tests for JSONL format conversion utilities.

.DESCRIPTION
    This test suite validates JSONL format conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'JSONL Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile)) {
                Test-Path -LiteralPath $outputFile | Should -Be $true
            }
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
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile)) {
                Test-Path -LiteralPath $outputFile | Should -Be $true
            }
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

