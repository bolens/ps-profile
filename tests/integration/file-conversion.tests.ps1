. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'File utility functions edge cases' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
            Ensure-FileConversion
            Ensure-FileUtilities
        }

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

    Context 'File conversion utilities' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
            Ensure-FileConversion
        }

        It 'json-pretty handles nested JSON' {
            $nestedJson = '{"level1":{"level2":{"level3":"value"}}}'
            $result = json-pretty $nestedJson
            $result | Should -Match 'level1'
            $result | Should -Match 'level2'
            $result | Should -Match 'level3'
        }

        It 'json-pretty handles arrays' {
            $arrayJson = '{"items":[1,2,3],"count":3}'
            $result = json-pretty $arrayJson
            $result | Should -Match 'items'
            $result | Should -Match 'count'
        }

        It 'to-base64 handles binary-like data' {
            $binary = [byte[]](0x00, 0x01, 0x02, 0xFF)
            $text = [System.Text.Encoding]::UTF8.GetString($binary)
            $encoded = $text | to-base64
            $decoded = $encoded | from-base64
            $decodedBytes = [System.Text.Encoding]::UTF8.GetBytes($decoded.TrimEnd("`r", "`n"))
            $decodedBytes[0] | Should -Be $binary[0]
        }

        It 'from-base64 handles padded base64 strings' {
            $testString = 'test'
            $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($testString))
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $testString
        }
    }
}
