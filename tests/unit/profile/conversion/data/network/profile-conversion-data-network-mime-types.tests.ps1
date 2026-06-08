# ===============================================
# profile-conversion-data-network-mime-types.tests.ps1
# Behavioral unit tests for MIME type parsing utilities
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
    Ensure-FileConversion-Data
}

Describe 'network-mime-types.ps1 - Parse-MimeType' {
    It 'Parses MIME type and parameters into structured components' {
        $parsed = Parse-MimeType -MimeType 'application/json; charset=utf-8'

        $parsed.Type | Should -Be 'application'
        $parsed.Subtype | Should -Be 'json'
        $parsed.Parameters.charset | Should -Be 'utf-8'
        $parsed.Extensions | Should -Contain 'json'
    }

    It 'Parses MIME types without parameters' {
        $parsed = Parse-MimeType -MimeType 'text/html'

        $parsed.Type | Should -Be 'text'
        $parsed.Subtype | Should -Be 'html'
        $parsed.Parameters.Count | Should -Be 0
        $parsed.Extensions | Should -Contain 'html'
    }

    It 'Returns null for blank MIME type input' {
        Parse-MimeType -MimeType '' | Should -BeNullOrEmpty
        Parse-MimeType -MimeType '   ' | Should -BeNullOrEmpty
    }

    It 'Handles quoted parameter values' {
        $parsed = Parse-MimeType -MimeType 'text/plain; filename="report final.txt"'

        $parsed.Parameters.filename | Should -Be 'report final.txt'
    }

    It 'Marks invalid type-only strings without a subtype separator' {
        $parsed = Parse-MimeType -MimeType 'invalid-mime'

        $parsed.Type | Should -Be 'invalid-mime'
        $parsed.Subtype | Should -Be ''
    }
}

Describe 'network-mime-types.ps1 - extension mapping' {
    It 'Get-MimeTypeFromExtension prefers application/json for .json' {
        Get-MimeTypeFromExtension -Extension 'json' | Should -Be 'application/json'
        Get-MimeTypeFromExtension -Extension '.json' | Should -Be 'application/json'
    }

    It 'Get-ExtensionFromMimeType returns a primary extension' {
        Get-ExtensionFromMimeType -MimeType 'text/html' | Should -Be 'html'
        Get-ExtensionFromMimeType -MimeType 'image/png' | Should -Be 'png'
    }

    It 'Round-trips common MIME types through extension helpers' {
        $mime = 'application/pdf'
        $ext = Get-ExtensionFromMimeType -MimeType $mime
        Get-MimeTypeFromExtension -Extension $ext | Should -Be $mime
    }
}
