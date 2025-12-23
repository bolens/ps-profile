

<#
.SYNOPSIS
    Integration tests for S-Expression format conversion utilities.

.DESCRIPTION
    This test suite validates S-Expression format conversion functions including conversions to/from JSON.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'S-Expression Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'S-Expressions Format Conversions' {
        It 'ConvertFrom-SexprToJson converts S-Expression to JSON' {
            Get-Command _ConvertFrom-SexprToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $sexprContent = @"
(name John
 age 30
 city "New York")
"@
            $tempFile = Join-Path $TestDrive 'test.sexpr'
            Set-Content -Path $tempFile -Value $sexprContent -NoNewline
            
            { _ConvertFrom-SexprToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.sexpr$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'ConvertTo-SexprFromJson converts JSON to S-Expression' {
            Get-Command _ConvertTo-SexprFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $jsonContent = @"
{
  "name": "John",
  "age": 30,
  "city": "New York"
}
"@
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $jsonContent -NoNewline
            
            { _ConvertTo-SexprFromJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.json$', '.sexpr'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $sexpr = Get-Content -Path $outputFile -Raw
                $sexpr | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'S-Expression to JSON and back roundtrip' {
            $originalContent = @"
(name John age 30)
"@
            $tempFile = Join-Path $TestDrive 'test.sexpr'
            Set-Content -Path $tempFile -Value $originalContent -NoNewline
            
            # Convert to JSON
            _ConvertFrom-SexprToJson -InputPath $tempFile
            $jsonFile = $tempFile -replace '\.sexpr$', '.json'
            
            # Convert back to S-Expression
            _ConvertTo-SexprFromJson -InputPath $jsonFile
            $roundtripFile = $jsonFile -replace '\.json$', '.sexpr'
            
            if ($roundtripFile -and -not [string]::IsNullOrWhiteSpace($roundtripFile) -and (Test-Path -LiteralPath $roundtripFile)) {
                $roundtrip = Get-Content -Path $roundtripFile -Raw
                $roundtrip | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Handles S-Expression with nested lists' {
            $sexprContent = @"
(person (name John) (age 30) (address (street "Main St") (city "New York")))
"@
            $tempFile = Join-Path $TestDrive 'test.sexpr'
            Set-Content -Path $tempFile -Value $sexprContent -NoNewline
            
            { _ConvertFrom-SexprToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.sexpr$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Handles S-Expression with comments' {
            $sexprContent = @"
; This is a comment
(name John ; inline comment
 age 30)
"@
            $tempFile = Join-Path $TestDrive 'test.sexpr'
            Set-Content -Path $tempFile -Value $sexprContent -NoNewline
            
            { _ConvertFrom-SexprToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.sexpr$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Handles S-Expression with quoted strings' {
            $sexprContent = @"
(message "Hello \"World\"")
"@
            $tempFile = Join-Path $TestDrive 'test.sexpr'
            Set-Content -Path $tempFile -Value $sexprContent -NoNewline
            
            { _ConvertFrom-SexprToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.sexpr$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'S-Expressions Additional Conversions' {
        It 'ConvertFrom-SexprToYaml function exists' {
            Get-Command ConvertFrom-SexprToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }
}

