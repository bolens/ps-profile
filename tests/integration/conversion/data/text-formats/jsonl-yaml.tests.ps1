

<#
.SYNOPSIS
    Integration tests for JSONL and YAML format conversions.

.DESCRIPTION
    This test suite validates JSONL ↔ YAML conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires yq command for conversions.
#>

Describe 'JSONL and YAML Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'JSONL and YAML Conversions' {
        It 'ConvertFrom-JsonLToYaml converts JSONL to YAML' {
            Get-Command ConvertFrom-JsonLToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $jsonl = '{"name":"test1","value":123}' + "`n" + '{"name":"test2","value":456}'
            $tempJsonl = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempJsonl -Value $jsonl
            { ConvertFrom-JsonLToYaml -InputPath $tempJsonl } | Should -Not -Throw
            $outputFile = $tempJsonl -replace '\.jsonl$', '.yaml'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $yaml = Get-Content -Path $outputFile -Raw
                $yaml | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-JsonLFromYaml converts YAML to JSONL' {
            Get-Command ConvertTo-JsonLFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq not available"
                return
            }
            $yaml = "- name: test1`n  value: 123`n- name: test2`n  value: 456"
            $tempYaml = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempYaml -Value $yaml
            { ConvertTo-JsonLFromYaml -InputPath $tempYaml } | Should -Not -Throw
            $outputFile = $tempYaml -replace '\.yaml$', '.jsonl'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $jsonl = Get-Content -Path $outputFile
                $jsonl.Count | Should -BeGreaterThan 0
            }
        }
    }
}

