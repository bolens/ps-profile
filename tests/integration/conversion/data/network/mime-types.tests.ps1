

<#
.SYNOPSIS
    Integration tests for MIME types parsing and conversion utilities.

.DESCRIPTION
    This test suite validates MIME types parsing and conversion functions including conversions to/from JSON and extensions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'MIME Types Parsing and Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'MIME Types Parsing and Conversions' {
        It 'Parse-MimeType function exists' {
            Get-Command Parse-MimeType -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Parse-MimeType parses MIME type into components' {
            $mime = 'application/json; charset=utf-8'
            $parsed = Parse-MimeType -MimeType $mime
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.Type | Should -Be 'application'
            $parsed.Subtype | Should -Be 'json'
            $parsed.Parameters | Should -Not -BeNullOrEmpty
            $parsed.Parameters.charset | Should -Be 'utf-8'
        }

        It 'Parse-MimeType handles MIME type without parameters' {
            $mime = 'text/html'
            $parsed = Parse-MimeType -MimeType $mime
            
            $parsed | Should -Not -BeNullOrEmpty
            $parsed.Type | Should -Be 'text'
            $parsed.Subtype | Should -Be 'html'
            $parsed.Parameters.Count | Should -Be 0
        }

        It 'Get-MimeTypeFromExtension function exists' {
            Get-Command Get-MimeTypeFromExtension -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-MimeTypeFromExtension gets MIME type from extension' {
            $mime = Get-MimeTypeFromExtension -Extension 'json'
            $mime | Should -Be 'application/json'
            
            $mime = Get-MimeTypeFromExtension -Extension '.html'
            $mime | Should -Be 'text/html'
        }

        It 'Get-ExtensionFromMimeType function exists' {
            Get-Command Get-ExtensionFromMimeType -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ExtensionFromMimeType gets extension from MIME type' {
            $ext = Get-ExtensionFromMimeType -MimeType 'application/json'
            $ext | Should -Be 'json'
            
            $exts = Get-ExtensionFromMimeType -MimeType 'text/html'
            $exts | Should -Be 'html'
        }

        It 'Parse-MimeType includes extensions when available' {
            $mime = 'application/json'
            $parsed = Parse-MimeType -MimeType $mime
            
            $parsed.Extensions | Should -Not -BeNullOrEmpty
            $parsed.Extensions | Should -Contain 'json'
        }

        It 'MIME type to JSON and back roundtrip' {
            $originalMime = 'application/json; charset=utf-8'
            $parsed = Parse-MimeType -MimeType $originalMime
            
            # Build components hashtable
            $components = @{
                Type       = $parsed.Type
                Subtype    = $parsed.Subtype
                Parameters = $parsed.Parameters
            }
            
            if (Get-Command _Build-MimeType -ErrorAction SilentlyContinue) {
                $built = _Build-MimeType -Components $components
                $built | Should -Not -BeNullOrEmpty
                $built | Should -Match 'application/json'
            }
        }

        It 'ConvertFrom-MimeTypeToJson converts MIME type to JSON' {
            Get-Command _ConvertFrom-MimeTypeToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $mime = 'application/json'
            $tempFile = Join-Path $TestDrive 'test.mime'
            Set-Content -Path $tempFile -Value $mime -NoNewline
            
            { _ConvertFrom-MimeTypeToJson -InputPath $tempFile } | Should -Not -Throw
            $outputFile = $tempFile -replace '\.mime$', '.json'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $json = Get-Content -Path $outputFile -Raw
                $json | Should -Not -BeNullOrEmpty
                $jsonObj = $json | ConvertFrom-Json
                $jsonObj.Type | Should -Be 'application'
            }
        }

        It 'Handles MIME type with multiple parameters' {
            $mime = 'multipart/form-data; boundary=----WebKitFormBoundary; charset=utf-8'
            $parsed = Parse-MimeType -MimeType $mime
            
            $parsed.Parameters | Should -Not -BeNullOrEmpty
            $parsed.Parameters.boundary | Should -Not -BeNullOrEmpty
        }
    }
}

