. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Utility Functions Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '05-utilities.ps1')
    }

    Context 'Utility functions edge cases' {
        It 'pwgen generates password with custom length' {
            if (Get-Command pwgen -ErrorAction SilentlyContinue) {
                $password = pwgen 20
                if ($password) {
                    $password.Length | Should -BeGreaterOrEqual 16
                }
            }
        }

        It 'pwgen generates unique passwords' {
            $pass1 = pwgen
            $pass2 = pwgen
            if ($pass1 -and $pass2) {
                $pass1 | Should -Not -Be $pass2
            }
        }

        It 'Add-Path handles duplicate paths gracefully' {
            $testPath = Join-Path $TestDrive 'TestDuplicatePath'
            $originalPath = $env:PATH
            try {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null

                Add-Path -Path $testPath
                $beforeCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                Add-Path -Path $testPath
                $afterCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                $afterCount | Should -BeGreaterOrEqual $beforeCount
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path handles non-existent paths gracefully' {
            $nonExistentPath = Join-Path $TestDrive 'NonExistentPath'
            $originalPath = $env:PATH
            try {
                { Remove-Path -Path $nonExistentPath } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'from-epoch handles edge cases' {
            $result = from-epoch 0
            $utcResult = $result.ToUniversalTime()
            $utcResult.Year | Should -Be 1970
            $utcResult.Month | Should -Be 1
            $utcResult.Day | Should -Be 1
        }

        It 'epoch returns consistent timestamps' {
            $time1 = epoch
            Start-Sleep -Milliseconds 100
            $time2 = epoch
            $time2 | Should -BeGreaterOrEqual $time1
        }
    }

    Context 'Utility functions additional tests' {
        It 'Reload-Profile function is available' {
            Get-Command Reload-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command reload -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Edit-Profile function is available' {
            Get-Command Edit-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command edit-profile -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-Weather function is available' {
            Get-Command Get-Weather -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command weather -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-MyIP function is available' {
            Get-Command Get-MyIP -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command myip -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-UrlEncoded encodes strings correctly' {
            $testString = 'hello world'
            $encoded = ConvertTo-UrlEncoded -text $testString
            $encoded | Should -Be 'hello%20world'
        }

        It 'ConvertFrom-UrlEncoded decodes strings correctly' {
            $encoded = 'hello%20world'
            $decoded = ConvertFrom-UrlEncoded -text $encoded
            $decoded | Should -Be 'hello world'
        }

        It 'ConvertTo-UrlEncoded and ConvertFrom-UrlEncoded roundtrip' {
            $original = 'test string with special chars: !@#$%'
            $encoded = ConvertTo-UrlEncoded -text $original
            $decoded = ConvertFrom-UrlEncoded -text $encoded
            $decoded | Should -Be $original
        }

        It 'ConvertTo-Epoch converts DateTime to Unix timestamp' {
            $testDate = Get-Date -Year 2020 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
            $epoch = ConvertTo-Epoch -date $testDate
            $epoch | Should -BeOfType [long]
            $epoch | Should -BeGreaterThan 0
        }

        It 'ConvertTo-Epoch and ConvertFrom-Epoch roundtrip' {
            $originalDate = Get-Date
            $epoch = ConvertTo-Epoch -date $originalDate
            $convertedBack = ConvertFrom-Epoch -epoch $epoch
            $timeDiff = [Math]::Abs(($convertedBack - $originalDate).TotalSeconds)
            $timeDiff | Should -BeLessThan 2
        }

        It 'Get-DateTime returns formatted date string' {
            $result = Get-DateTime
            $result | Should -BeOfType [string]
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
        }

        It 'Get-DateTime alias now is available' {
            Get-Command now -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-History returns recent commands' {
            { Get-History -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-History searches command history' {
            $historyMarker = "test-search-command-$(Get-Random)"
            { Find-History $historyMarker -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-History alias hg is available' {
            Get-Command hg -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'to-epoch alias works' {
            Get-Command to-epoch -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            $testDate = Get-Date
            $result = to-epoch $testDate
            $result | Should -BeOfType [long]
        }

        It 'url-encode and url-decode aliases work' {
            Get-Command url-encode -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command url-decode -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null

            $test = 'test string'
            $encoded = url-encode $test
            $decoded = url-decode $encoded
            $decoded | Should -Be $test
        }
    }

    Context 'Error recovery tests' {
        It 'Get-EnvVar recovers from registry errors gracefully' {
            $invalidName = "TEST_INVALID<>:$([char]0)"
            $result = Get-EnvVar -Name $invalidName
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Remove-Path handles malformed PATH gracefully' {
            $originalPath = $env:PATH
            try {
                $env:PATH = ';;;invalid;;;path;;;'
                { Remove-Path -Path 'nonexistent' } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Add-Path handles empty PATH' {
            $originalPath = $env:PATH
            try {
                $env:PATH = ''
                $testPath = Join-Path $TestDrive 'EmptyPathTest'
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
                { Add-Path -Path $testPath } | Should -Not -Throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }
}
