. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Utility Functions Edge Cases' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
        Ensure-FileConversion-Documents
        Ensure-FileConversion-Media
        Ensure-FileUtilities
    }

    Context 'Basic file utility edge cases' {
        It 'json-pretty handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json}'
            {
                $originalWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'SilentlyContinue'
                    json-pretty $invalidJson | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'to-base64 handles empty strings' {
            $empty = ''
            $encoded = $empty | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $empty
        }

        It 'to-base64 handles unicode strings' {
            $unicode = 'Hello 世界'
            $encoded = $unicode | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $unicode
        }

        It 'file-hash handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent.txt'
            {
                $originalWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'SilentlyContinue'
                    file-hash -Path $nonExistent | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }

        It 'filesize handles different file sizes' {
            $smallFile = Join-Path $TestDrive 'small.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline
            $small = filesize $smallFile
            $small | Should -Match '\d+.*B'

            $largeFile = Join-Path $TestDrive 'large.txt'
            $content = 'x' * 1048576
            Set-Content -Path $largeFile -Value $content -NoNewline
            $large = filesize $largeFile
            $large | Should -Match '\d+.*MB'
        }
    }
}
