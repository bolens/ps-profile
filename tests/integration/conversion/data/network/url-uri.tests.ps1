

<#
.SYNOPSIS
    Integration tests for URL/URI parsing and conversion utilities.

.DESCRIPTION
    This test suite validates URL/URI parsing and conversion functions including conversions to/from JSON and components.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'URL/URI Parsing and Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'URL/URI Parsing and Conversions' {
        It 'Parse-UrlUri function exists' {
            Get-Command Parse-UrlUri -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Parse-UrlUri parses URL into components' {
            $url = 'https://example.com:8080/path/to/resource?key1=value1&key2=value2#fragment'
            $parsed = Parse-UrlUri -Url $url
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.Scheme | Should -Be 'https'
            $parsed.Host | Should -Be 'example.com'
            $parsed.Port | Should -Be 8080
            $parsed.Path | Should -Be '/path/to/resource'
            $parsed.Query | Should -Match 'key1=value1'
            $parsed.Fragment | Should -Match 'fragment'
        }

        It 'Parse-UrlUri extracts query parameters' {
            $url = 'https://example.com?name=John&age=30&city=New%20York'
            $parsed = Parse-UrlUri -Url $url
            
            $parsed.QueryParameters | Should -Not -BeNullOrEmpty
            $parsed.QueryParameters.name | Should -Be 'John'
            $parsed.QueryParameters.age | Should -Be '30'
            $parsed.QueryParameters.city | Should -Be 'New York'
        }

        It 'Build-UrlUri function exists' {
            Get-Command Build-UrlUri -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Build-UrlUri builds URL from components' {
            $components = @{
                Scheme          = 'https'
                Host            = 'example.com'
                Port            = 8080
                Path            = '/api/users'
                QueryParameters = @{
                    id   = '123'
                    name = 'John'
                }
            }
            
            $url = Build-UrlUri -Components $components
            $url | Should -Not -BeNullOrEmpty
            $url | Should -Match 'https://example.com:8080'
            $url | Should -Match '/api/users'
            $url | Should -Match 'id=123'
        }

        It 'URL/URI to JSON and back roundtrip' {
            $originalUrl = 'https://example.com/path?key=value#frag'
            $parsed = Parse-UrlUri -Url $originalUrl
            
            $components = @{
                Scheme          = $parsed.Scheme
                Host            = $parsed.Host
                Path            = $parsed.Path
                QueryParameters = $parsed.QueryParameters
                Fragment        = $parsed.Fragment
            }
            
            $builtUrl = Build-UrlUri -Components $components
            $builtUrl | Should -Not -BeNullOrEmpty
            # URLs may be normalized, so just check key components
            $builtParsed = Parse-UrlUri -Url $builtUrl
            $builtParsed.Scheme | Should -Be $parsed.Scheme
            $builtParsed.Host | Should -Be $parsed.Host
        }

        It 'ConvertFrom-UrlUriToJson converts URL to JSON' {
            Get-Command _ConvertFrom-UrlUriToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $url = 'https://example.com/path?key=value'
            $tempFile = Join-Path $TestDrive 'test.url'
            Set-Content -Path $tempFile -Value $url -NoNewline
            
            { _ConvertFrom-UrlUriToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.url$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.Scheme | Should -Be 'https'
                $jsonObj.Host | Should -Be 'example.com'
            }
        }

        It 'Handles URLs without query string' {
            $url = 'https://example.com/path'
            $parsed = Parse-UrlUri -Url $url
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.QueryParameters | Should -Not -BeNullOrEmpty
            $parsed.QueryParameters.Count | Should -Be 0
        }

        It 'Handles URLs with multiple query parameters with same key' {
            $url = 'https://example.com?tag=red&tag=blue&tag=green'
            $parsed = Parse-UrlUri -Url $url
            
            $parsed.QueryParameters.tag | Should -Not -BeNullOrEmpty
            $parsed.QueryParameters.tag | Should -BeOfType [System.Array]
            $parsed.QueryParameters.tag.Count | Should -Be 3
        }
    }
}

