. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'File Utility Functions Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'File utility functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '02-files-utilities.ps1')
        }

        It 'Get-FileHead (head) function is available' {
            Get-Command head -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileHead -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileTail (tail) function is available' {
            Get-Command tail -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileTail -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'head function shows first 10 lines of file' {
            $testFile = Join-Path $TestDrive 'test_head.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = head $testFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Line 1'
            $result[9] | Should -Be 'Line 10'
        }

        It 'head function shows custom number of lines' {
            $testFile = Join-Path $TestDrive 'test_head_custom.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = head $testFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'Line 1'
            $result[4] | Should -Be 'Line 5'
        }

        It 'head function works with pipeline input' {
            $inputData = 1..15 | ForEach-Object { "Item $_" }
            $result = $inputData | head
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Item 1'
            $result[9] | Should -Be 'Item 10'
        }

        It 'tail function shows last 10 lines of file' {
            $testFile = Join-Path $TestDrive 'test_tail.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = tail $testFile
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Line 11'
            $result[9] | Should -Be 'Line 20'
        }

        It 'tail function shows custom number of lines' {
            $testFile = Join-Path $TestDrive 'test_tail_custom.txt'
            $content = 1..20 | ForEach-Object { "Line $_" }
            Set-Content -Path $testFile -Value $content

            $result = tail $testFile -Lines 5
            $result.Count | Should -Be 5
            $result[0] | Should -Be 'Line 16'
            $result[4] | Should -Be 'Line 20'
        }

        It 'tail function works with pipeline input' {
            $inputData = 1..15 | ForEach-Object { "Item $_" }
            $result = $inputData | tail
            $result.Count | Should -Be 10
            $result[0] | Should -Be 'Item 6'
            $result[9] | Should -Be 'Item 15'
        }

        It 'Get-FileHashValue (file-hash) function is available' {
            Get-Command file-hash -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileHashValue -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileHashValue calculates SHA256 hash' {
            $testFile = Join-Path $TestDrive 'test_hash.txt'
            Set-Content -Path $testFile -Value 'test content for hashing'

            $result = Get-FileHashValue -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Algorithm | Should -Be 'SHA256'
            $result.Hash | Should -Match '^[A-F0-9]{64}$'
            $result.Path | Should -Be $testFile
        }

        It 'Get-FileHashValue supports different algorithms' {
            $testFile = Join-Path $TestDrive 'test_hash_algo.txt'
            Set-Content -Path $testFile -Value 'test content'

            $md5Result = Get-FileHashValue -Path $testFile -Algorithm MD5
            $md5Result.Algorithm | Should -Be 'MD5'
            $md5Result.Hash | Should -Match '^[A-F0-9]{32}$'

            $sha1Result = Get-FileHashValue -Path $testFile -Algorithm SHA1
            $sha1Result.Algorithm | Should -Be 'SHA1'
            $sha1Result.Hash | Should -Match '^[A-F0-9]{40}$'
        }

        It 'Get-FileHashValue handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent_hash.txt'
            $result = Get-FileHashValue -Path $nonExistent 3>$null
            $result | Should -Be $null
        }

        It 'Get-FileSize (filesize) function is available' {
            Get-Command filesize -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-FileSize -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-FileSize returns human-readable sizes' {
            $smallFile = Join-Path $TestDrive 'small_size.txt'
            Set-Content -Path $smallFile -Value 'x' -NoNewline

            $result = Get-FileSize -Path $smallFile
            $result | Should -Match '\d+ bytes'
        }

        It 'Get-FileSize handles different file sizes' {
            $mediumFile = Join-Path $TestDrive 'medium_size.txt'
            $content = 'x' * 2048  # 2KB
            Set-Content -Path $mediumFile -Value $content -NoNewline

            $result = Get-FileSize -Path $mediumFile
            $result | Should -Match '\d+\.\d+ KB'
        }

        It 'Get-FileSize handles non-existent files' {
            $nonExistent = Join-Path $TestDrive 'non_existent_size.txt'
            $result = Get-FileSize -Path $nonExistent 2>$null
            $result | Should -Be $null
        }

        It 'Get-HexDump (hex-dump) function is available' {
            Get-Command hex-dump -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-HexDump -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-HexDump displays hex representation' {
            $testFile = Join-Path $TestDrive 'test_hex.txt'
            Set-Content -Path $testFile -Value 'AB' -NoNewline

            $result = Get-HexDump -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            # Should contain hex values
            $resultString = $result | Out-String
            $resultString | Should -Match '[0-9A-F]{2}'
        }
    }
}
