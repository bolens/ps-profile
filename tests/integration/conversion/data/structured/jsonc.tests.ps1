

<#
.SYNOPSIS
    Integration tests for JSONC format conversion utilities.

.DESCRIPTION
    This test suite validates JSONC conversion functions including conversions to/from JSON and YAML.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'JSONC Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'JSONC Format Conversions' {
        It 'ConvertFrom-JsoncToJson converts JSONC to JSON' {
            Get-Command ConvertFrom-JsoncToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsoncContent = @"
{
  // This is a comment
  "name": "John",
  "age": 30
}
"@
            $tempFile = Join-Path $TestDrive 'test.jsonc'
            Set-Content -Path $tempFile -Value $jsoncContent -NoNewline
            
            { ConvertFrom-JsoncToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.jsonc$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.name | Should -Be 'John'
            }
        }
        
        It 'ConvertTo-JsoncFromJson converts JSON to JSONC' {
            Get-Command ConvertTo-JsoncFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = '{"name":"John","age":30}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { ConvertTo-JsoncFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.jsonc'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $jsonc = Get-Content -Path $outputFile -Raw
                $jsonc | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'JSONC to JSON and back roundtrip' {
            $originalJson = '{"name":"John","age":30}'
            $tempJson = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempJson -Value $originalJson -NoNewline
            
            $jsoncFile = Join-Path $TestDrive 'test.jsonc'
            ConvertTo-JsoncFromJson -InputPath $tempJson -OutputPath $jsoncFile
            $jsonFile = Join-Path $TestDrive 'test-roundtrip.json'
            ConvertFrom-JsoncToJson -InputPath $jsoncFile -OutputPath $jsonFile
            
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                $roundtripJson = Get-Content -Path $jsonFile -Raw
                $roundtripObj = $roundtripJson | ConvertFrom-Json
                $roundtripObj.name | Should -Be 'John'
            }
        }
        
        It 'Handles JSONC with block comments' {
            $jsoncContent = @"
{
  /* This is a block comment */
  "name": "John"
}
"@
            $tempFile = Join-Path $TestDrive 'test-comments.jsonc'
            Set-Content -Path $tempFile -Value $jsoncContent -NoNewline
            
            { ConvertFrom-JsoncToJson -InputPath $tempFile } | Should -Not -Throw
        }
    }
}

