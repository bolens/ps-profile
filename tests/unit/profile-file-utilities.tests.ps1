#
# Tests for file conversion and utility helpers.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
    . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
    Ensure-FileConversion
    Ensure-FileUtilities
}

Describe 'Profile file utility functions' {
    Context 'Conversion helpers' {
        It 'json-pretty formats JSON correctly' {
            $json = '{"name":"test","value":123}'
            $result = json-pretty $json
            $result | Should -Match '"name"\s*:\s*"test"'
            $result | Should -Match '"value"\s*:\s*123'
        }

        It 'to-base64 and from-base64 roundtrip correctly' {
            $payload = 'Hello, World!'
            $encoded = $payload | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $payload
        }

        It 'to-base64 handles empty strings' {
            $encoded = '' | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be ''
        }

        It 'to-base64 handles unicode strings' {
            $payload = 'Hello 世界'
            $encoded = $payload | to-base64
            $decoded = $encoded | from-base64
            $decoded.TrimEnd("`r", "`n") | Should -Be $payload
        }
    }

    Context 'File metadata helpers' {
        It 'file-hash calculates SHA256 correctly' {
            $tempFile = Join-Path $TestDrive 'test_hash.txt'
            Set-Content -Path $tempFile -Value 'test content' -NoNewline
            $hash = file-hash $tempFile
            $hash.Algorithm | Should -Be 'SHA256'
            $hash.Hash.Length | Should -Be 64
        }

        It 'filesize returns human-readable size' {
            $tempFile = Join-Path $TestDrive 'test_size.txt'
            Set-Content -Path $tempFile -Value ('x' * 1024) -NoNewline
            $result = filesize $tempFile
            $result | Should -Match '1\.00 KB'
        }
    }

    Context 'Error handling' {
        It 'file-hash handles non-existent files gracefully' {
            $missing = Join-Path $TestDrive 'non_existent.txt'
            {
                $originalWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'SilentlyContinue'
                    file-hash -Path $missing | Out-Null
                }
                finally {
                    $WarningPreference = $originalWarningPreference
                }
            } | Should -Not -Throw
        }
    }
}
