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

    It 'Returns empty results for unknown extensions and MIME types' {
        Get-MimeTypeFromExtension -Extension 'not-a-real-ext' | Should -Be ''
        Get-MimeTypeFromExtension -Extension '' | Should -Be ''
        @(Get-ExtensionFromMimeType -MimeType 'application/x-unknown-type') | Should -BeNullOrEmpty
        @(Get-ExtensionFromMimeType -MimeType '') | Should -BeNullOrEmpty
    }

    It 'Strips MIME parameters before resolving extensions' {
        Get-ExtensionFromMimeType -MimeType 'text/html; charset=utf-8' | Should -Be 'html'
    }

    It 'Supports pipeline input for extension helpers' {
        'json' | Get-MimeTypeFromExtension | Should -Be 'application/json'
        'image/png' | Get-ExtensionFromMimeType | Should -Be 'png'
    }
}

Describe 'network-mime-types.ps1 - file conversions' {
    It 'ConvertFrom-MimeTypeToJson writes structured JSON for a MIME file' {
        $workDir = New-TestTempDirectory -Prefix 'MimeJson'
        $mimePath = Join-Path $workDir 'sample.mime'
        Set-Content -LiteralPath $mimePath -Value 'application/json; charset=utf-8' -Encoding UTF8 -NoNewline

        { ConvertFrom-MimeTypeToJson -InputPath $mimePath -ErrorAction Stop } | Should -Not -Throw

        $jsonPath = Join-Path $workDir 'sample.json'
        Test-Path -LiteralPath $jsonPath | Should -Be $true

        $parsed = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
        $parsed.Type | Should -Be 'application'
        $parsed.Subtype | Should -Be 'json'
        $parsed.Parameters.charset | Should -Be 'utf-8'
        $parsed.Extensions | Should -Contain 'json'
    }

    It 'ConvertTo-MimeTypeFromJson rebuilds MIME text from JSON components' {
        $workDir = New-TestTempDirectory -Prefix 'JsonMime'
        $jsonPath = Join-Path $workDir 'sample.json'
        $outputPath = Join-Path $workDir 'sample.mime'

        @{
            Type       = 'text'
            Subtype    = 'plain'
            Parameters = @{ charset = 'utf-8' }
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

        { ConvertTo-MimeTypeFromJson -InputPath $jsonPath -OutputPath $outputPath -ErrorAction Stop } | Should -Not -Throw

        $mimeText = Get-Content -LiteralPath $outputPath -Raw
        $mimeText | Should -Match 'text/plain'
        $mimeText | Should -Match 'charset=utf-8'
    }

    It 'Round-trips MIME content through JSON file conversion helpers' {
        $workDir = New-TestTempDirectory -Prefix 'MimeRoundTrip'
        $mimePath = Join-Path $workDir 'roundtrip.mime'
        $jsonPath = Join-Path $workDir 'roundtrip.json'
        $restoredPath = Join-Path $workDir 'roundtrip-restored.mime'
        $original = 'application/pdf'

        Set-Content -LiteralPath $mimePath -Value $original -Encoding UTF8 -NoNewline
        ConvertFrom-MimeTypeToJson -InputPath $mimePath -OutputPath $jsonPath -ErrorAction Stop
        ConvertTo-MimeTypeFromJson -InputPath $jsonPath -OutputPath $restoredPath -ErrorAction Stop

        (Get-Content -LiteralPath $restoredPath -Raw).Trim() | Should -Be $original
    }

    It 'Does not create JSON output when the MIME input file is missing' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'MimeMissing') 'missing.mime'

        { ConvertFrom-MimeTypeToJson -InputPath $missingPath -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
        Test-Path -LiteralPath ($missingPath -replace '\.mime$', '.json') | Should -Be $false
    }
}
