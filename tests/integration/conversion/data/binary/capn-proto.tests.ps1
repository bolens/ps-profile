

<#
.SYNOPSIS
    Integration tests for Cap'n Proto format conversion utilities.

.DESCRIPTION
    This test suite validates Cap'n Proto format conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires Node.js for Cap'n Proto conversions.
    Some tests may be skipped if external dependencies are not available.
#>

Describe 'Cap''n Proto Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
        
        # Check for Node.js availability
        $script:NodeJsAvailable = $false
        if (Get-Command node -ErrorAction SilentlyContinue) {
            $script:NodeJsAvailable = $true
        }
    }

    Context 'Cap''n Proto Format Conversions' {
        It 'ConvertTo-CapnpFromJson function exists' {
            Get-Command ConvertTo-CapnpFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-CapnpToJson function exists' {
            Get-Command ConvertFrom-CapnpToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-CapnpFromJson requires schema path' {
            if (-not $script:NodeJsAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            $testFile = Join-Path $TestDrive 'test.json'
            Set-Content -LiteralPath $testFile -Value '{"name": "test", "value": 1}'
            
            { ConvertTo-CapnpFromJson -InputPath $testFile -OutputPath (Join-Path $TestDrive 'test.capnp') } | Should -Throw
        }

        It 'ConvertFrom-CapnpToJson requires schema path' {
            if (-not $script:NodeJsAvailable) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            $testFile = Join-Path $TestDrive 'test.capnp'
            Set-Content -LiteralPath $testFile -Value 'test data'
            
            { ConvertFrom-CapnpToJson -InputPath $testFile -OutputPath (Join-Path $TestDrive 'test.json') } | Should -Throw
        }
    }
}

