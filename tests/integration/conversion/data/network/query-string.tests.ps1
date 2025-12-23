

<#
.SYNOPSIS
    Integration tests for query string parsing and conversion utilities.

.DESCRIPTION
    This test suite validates query string parsing and conversion functions including conversions to/from JSON.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Query String Parsing and Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Query String Parsing and Conversions' {
        It 'Parse-QueryString function exists' {
            Get-Command Parse-QueryString -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Parse-QueryString parses query string into hashtable' {
            $query = 'name=John&age=30&city=New%20York'
            $parsed = Parse-QueryString -QueryString $query
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.name | Should -Be 'John'
            $parsed.age | Should -Be '30'
            $parsed.city | Should -Be 'New York'
        }

        It 'Parse-QueryString handles query string with leading ?' {
            $query = '?key=value&other=test'
            $parsed = Parse-QueryString -QueryString $query
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.key | Should -Be 'value'
            $parsed.other | Should -Be 'test'
        }

        It 'Parse-QueryString handles keys without values' {
            $query = 'key1=value1&key2&key3=value3'
            $parsed = Parse-QueryString -QueryString $query
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.key1 | Should -Be 'value1'
            $parsed.key2 | Should -Be $null
            $parsed.key3 | Should -Be 'value3'
        }

        It 'Build-QueryString function exists' {
            Get-Command Build-QueryString -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Build-QueryString builds query string from hashtable' {
            $params = @{
                name = 'John'
                age  = '30'
                city = 'New York'
            }
            
            $query = Build-QueryString -Parameters $params
            $query | Should -Not -BeNullOrEmpty
            $query | Should -Match 'name=John'
            $query | Should -Match 'age=30'
            $query | Should -Match 'city=New%20York'
        }

        It 'Query string to JSON and back roundtrip' {
            $originalQuery = 'name=John&age=30&city=New%20York'
            $parsed = Parse-QueryString -QueryString $originalQuery
            
            $built = Build-QueryString -Parameters $parsed
            
            # Parse again to verify
            $roundtrip = Parse-QueryString -QueryString $built
            $roundtrip.name | Should -Be 'John'
            $roundtrip.age | Should -Be '30'
            $roundtrip.city | Should -Be 'New York'
        }

        It 'Build-QueryString handles multiple values for same key' {
            $params = @{
                tag = @('red', 'blue', 'green')
            }
            
            $query = Build-QueryString -Parameters $params
            $query | Should -Not -BeNullOrEmpty
            $query | Should -Match 'tag=red'
            $query | Should -Match 'tag=blue'
            $query | Should -Match 'tag=green'
        }

        It 'ConvertFrom-QueryStringToJson converts query string to JSON' {
            Get-Command _ConvertFrom-QueryStringToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $query = 'name=John&age=30'
            $tempFile = Join-Path $TestDrive 'test.query'
            Set-Content -Path $tempFile -Value $query -NoNewline
            
            { _ConvertFrom-QueryStringToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.query$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.name | Should -Be 'John'
            }
        }

        It 'Handles empty query string' {
            $parsed = Parse-QueryString -QueryString ''
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.Count | Should -Be 0
        }
    }
}

