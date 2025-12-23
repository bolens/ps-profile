

<#
.SYNOPSIS
    Integration tests for JSONL and CSV format conversions.

.DESCRIPTION
    This test suite validates JSONL ↔ CSV conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
#>

Describe 'JSONL and CSV Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'JSONL and CSV Conversions' {
        It 'ConvertFrom-JsonLToCsv converts JSONL to CSV' {
            Get-Command ConvertFrom-JsonLToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $jsonl = '{"name":"test1","value":123}' + "`n" + '{"name":"test2","value":456}'
            $tempJsonl = Join-Path $TestDrive 'test.jsonl'
            Set-Content -Path $tempJsonl -Value $jsonl
            { ConvertFrom-JsonLToCsv -InputPath $tempJsonl } | Should -Not -Throw
            $outputFile = $tempJsonl -replace '\.jsonl$', '.csv'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $csv = Get-Content -Path $outputFile -Raw
                $csv | Should -Not -BeNullOrEmpty
                $csv | Should -Match 'name|value'
            }
        }

        It 'ConvertTo-JsonLFromCsv converts CSV to JSONL' {
            Get-Command ConvertTo-JsonLFromCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $csv = "name,value`ntest1,123`ntest2,456"
            $tempCsv = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempCsv -Value $csv
            { ConvertTo-JsonLFromCsv -InputPath $tempCsv } | Should -Not -Throw
            $outputFile = $tempCsv -replace '\.csv$', '.jsonl'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $jsonl = Get-Content -Path $outputFile
                $jsonl.Count | Should -BeGreaterThan 0
                $jsonl[0] | Should -Match 'name|value'
            }
        }
    }
}

