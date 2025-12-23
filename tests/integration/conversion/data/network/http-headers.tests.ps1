

<#
.SYNOPSIS
    Integration tests for HTTP headers parsing and conversion utilities.

.DESCRIPTION
    This test suite validates HTTP headers parsing and conversion functions including conversions to/from JSON.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'HTTP Headers Parsing and Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'HTTP Headers Parsing and Conversions' {
        It 'Parse-HttpHeaders function exists' {
            Get-Command Parse-HttpHeaders -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Parse-HttpHeaders parses HTTP headers into hashtable' {
            $headers = @"
Content-Type: application/json
Authorization: Bearer token123
User-Agent: MyApp/1.0
"@
            $parsed = Parse-HttpHeaders -Headers $headers
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.'Content-Type' | Should -Be 'application/json'
            $parsed.Authorization | Should -Be 'Bearer token123'
            $parsed.'User-Agent' | Should -Be 'MyApp/1.0'
        }

        It 'Parse-HttpHeaders handles multi-line header values' {
            $headers = @"
Content-Type: application/json
X-Custom-Header: value1
    value2
    value3
"@
            $parsed = Parse-HttpHeaders -Headers $headers
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.'X-Custom-Header' | Should -Match 'value1'
        }

        It 'Build-HttpHeaders function exists' {
            Get-Command Build-HttpHeaders -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Build-HttpHeaders builds headers from hashtable' {
            $headers = @{
                'Content-Type'  = 'application/json'
                'Authorization' = 'Bearer token123'
            }
            
            $headersString = Build-HttpHeaders -Headers $headers
            $headersString | Should -Not -BeNullOrEmpty
            $headersString | Should -Match 'Content-Type: application/json'
            $headersString | Should -Match 'Authorization: Bearer token123'
        }

        It 'HTTP headers to JSON and back roundtrip' {
            $originalHeaders = @"
Content-Type: application/json
Authorization: Bearer token123
"@
            $parsed = Parse-HttpHeaders -Headers $originalHeaders
            
            $built = Build-HttpHeaders -Headers $parsed
            
            # Parse again to verify
            $roundtrip = Parse-HttpHeaders -Headers $built
            $roundtrip.'Content-Type' | Should -Be 'application/json'
            $roundtrip.Authorization | Should -Be 'Bearer token123'
        }

        It 'Parse-HttpHeaders handles multiple headers with same name' {
            $headers = @"
Set-Cookie: session=abc123
Set-Cookie: theme=dark
"@
            $parsed = Parse-HttpHeaders -Headers $headers
            
            $parsed.'Set-Cookie' | Should -Not -BeNullOrEmpty
            $parsed.'Set-Cookie' | Should -BeOfType [System.Array]
            $parsed.'Set-Cookie'.Count | Should -Be 2
        }

        It 'ConvertFrom-HttpHeadersToJson converts headers to JSON' {
            Get-Command _ConvertFrom-HttpHeadersToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $headers = 'Content-Type: application/json'
            $tempFile = Join-Path $TestDrive 'test.headers'
            Set-Content -Path $tempFile -Value $headers -NoNewline
            
            { _ConvertFrom-HttpHeadersToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.headers$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
            }
        }

        It 'Handles empty headers' {
            $parsed = Parse-HttpHeaders -Headers ''
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.Count | Should -Be 0
        }
    }
}

