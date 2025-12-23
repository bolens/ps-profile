

<#
.SYNOPSIS
    Integration tests for HJSON format conversion utilities.

.DESCRIPTION
    This test suite validates HJSON conversion functions including conversions to/from JSON and YAML.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'HJSON Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'HJSON Format Conversions' {
        It 'ConvertFrom-HjsonToJson converts HJSON to JSON' {
            Get-Command ConvertFrom-HjsonToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $hjsonContent = @"
{
  // This is a comment
  name: John
  age: 30
  city: "New York"
}
"@
            $tempFile = Join-Path $TestDrive 'test.hjson'
            Set-Content -Path $tempFile -Value $hjsonContent -NoNewline
            
            { ConvertFrom-HjsonToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.hjson$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.name | Should -Be 'John'
            }
        }
        
        It 'ConvertTo-HjsonFromJson converts JSON to HJSON' {
            Get-Command ConvertTo-HjsonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = '{"name":"John","age":30,"city":"New York"}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { ConvertTo-HjsonFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.hjson'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $hjson = Get-Content -Path $outputFile -Raw
                $hjson | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'HJSON to JSON and back roundtrip' {
            $originalJson = '{"name":"John","age":30}'
            $tempJson = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempJson -Value $originalJson -NoNewline
            
            $hjsonFile = Join-Path $TestDrive 'test.hjson'
            ConvertTo-HjsonFromJson -InputPath $tempJson -OutputPath $hjsonFile
            $jsonFile = Join-Path $TestDrive 'test-roundtrip.json'
            ConvertFrom-HjsonToJson -InputPath $hjsonFile -OutputPath $jsonFile
            
            if ($jsonFile -and -not [string]::IsNullOrWhiteSpace($jsonFile) -and (Test-Path -LiteralPath $jsonFile)) {
                $roundtripJson = Get-Content -Path $jsonFile -Raw
                $roundtripObj = $roundtripJson | ConvertFrom-Json
                $roundtripObj.name | Should -Be 'John'
            }
        }
        
        It 'Handles HJSON with block comments' {
            $hjsonContent = @"
{
  /* This is a block comment */
  name: John
}
"@
            $tempFile = Join-Path $TestDrive 'test-comments.hjson'
            Set-Content -Path $tempFile -Value $hjsonContent -NoNewline
            
            { ConvertFrom-HjsonToJson -InputPath $tempFile } | Should -Not -Throw
        }
    }
}

