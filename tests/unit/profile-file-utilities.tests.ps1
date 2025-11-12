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

        It 'Convert-XmlToJsonObject handles nested elements and text nodes' {
            $xml = [xml] '<root><parent><child>value</child><child>value2</child>text</parent></root>'
            $obj = Convert-XmlToJsonObject $xml.DocumentElement
            # Expect parent to contain children array and text node
            $obj.parent | Should -Not -Be $null
            $obj.parent.child | Should -BeOfType System.Object
            # child should be an array of two items
            $obj.parent.child.Count | Should -Be 2
            $obj.parent.'#text' | Should -Be 'text'
        }

        It 'ConvertFrom-XmlToJson produces valid JSON for nested XML' {
            $xml = '<root><items><item>one</item><item>two</item></items></root>'
            $tempFile = Join-Path $TestDrive 'test_nested.xml'
            Set-Content -Path $tempFile -Value $xml
            $result = ConvertFrom-XmlToJson -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            $parsed = $result | ConvertFrom-Json
            $parsed.root.items.item.Count | Should -Be 2
            $parsed.root.items.item[0].'#text' | Should -Be 'one'
        }

        It 'Get-FileHead returns first N lines from file' {
            $content = "line1`nline2`nline3`nline4`nline5`nline6`nline7`nline8`nline9`nline10`nline11`nline12"
            $tempFile = Join-Path $TestDrive 'test_head.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileHead -Path $tempFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'line1'
            $result[4] | Should -Be 'line5'
        }

        It 'Get-FileHead returns first 10 lines by default' {
            $content = (1..15 | ForEach-Object { "line$_" }) -join "`n"
            $tempFile = Join-Path $TestDrive 'test_head_default.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileHead -Path $tempFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'line1'
            $result[9] | Should -Be 'line10'
        }

        It 'Get-FileTail returns last N lines from file' {
            $content = "line1`nline2`nline3`nline4`nline5`nline6`nline7`nline8`nline9`nline10`nline11`nline12"
            $tempFile = Join-Path $TestDrive 'test_tail.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileTail -Path $tempFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'line8'
            $result[4] | Should -Be 'line12'
        }

        It 'Get-FileTail returns last 10 lines by default' {
            $content = (1..15 | ForEach-Object { "line$_" }) -join "`n"
            $tempFile = Join-Path $TestDrive 'test_tail_default.txt'
            Set-Content -Path $tempFile -Value $content
            $result = Get-FileTail -Path $tempFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'line6'
            $result[9] | Should -Be 'line15'
        }

        It 'Get-FileHashValue calculates SHA256 hash correctly' {
            $tempFile = Join-Path $TestDrive 'test_hash.txt'
            Set-Content -Path $tempFile -Value 'test content for hashing' -NoNewline
            $hash = Get-FileHashValue -Path $tempFile
            $hash.Algorithm | Should -Be 'SHA256'
            $hash.Hash.Length | Should -Be 64
            $hash.Path | Should -Be $tempFile
        }

        It 'Get-FileHashValue supports different algorithms' {
            $tempFile = Join-Path $TestDrive 'test_hash_md5.txt'
            Set-Content -Path $tempFile -Value 'test content' -NoNewline
            $hash = Get-FileHashValue -Path $tempFile -Algorithm MD5
            $hash.Algorithm | Should -Be 'MD5'
            $hash.Hash.Length | Should -Be 32
        }

        It 'Get-FileSize returns human-readable size for small file' {
            $tempFile = Join-Path $TestDrive 'test_size_small.txt'
            Set-Content -Path $tempFile -Value 'x' -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+ bytes'
        }

        It 'Get-FileSize returns human-readable size for KB file' {
            $tempFile = Join-Path $TestDrive 'test_size_kb.txt'
            $content = 'x' * 2048
            Set-Content -Path $tempFile -Value $content -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+\.\d+ KB'
        }

        It 'Get-FileSize returns human-readable size for MB file' {
            $tempFile = Join-Path $TestDrive 'test_size_mb.txt'
            $content = 'x' * (1024 * 1024 * 2)
            Set-Content -Path $tempFile -Value $content -NoNewline
            $result = Get-FileSize -Path $tempFile
            $result | Should -Match '\d+\.\d+ MB'
        }

        It 'Get-HexDump produces hex output for file' {
            $tempFile = Join-Path $TestDrive 'test_hex.txt'
            Set-Content -Path $tempFile -Value 'AB' -NoNewline
            $result = Get-HexDump -Path $tempFile
            $result | Should -Not -BeNullOrEmpty
            # Should contain hex representation
            $result.ToString() | Should -Match '41 42'
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
