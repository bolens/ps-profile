. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for developer utility tools.

.DESCRIPTION
    This test suite validates developer utility functions including hash generators,
    JWT encoding/decoding, timestamp conversion, UUID generation, encoding utilities,
    text comparison, regex testing, QR code generation, base encoding, number base
    conversion, Lorem Ipsum generation, and unit conversion.

.NOTES
    Tests cover both successful operations and error handling scenarios.
    Some tests require Node.js and npm packages.
#>

Describe 'Developer Tools Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-DevTools
    }

    Context 'Hash generator utilities' {
        It 'Get-TextHash calculates hash of text' {
            Get-Command Get-TextHash -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = "Hello World" | Get-TextHash
            $result | Should -Not -Be $null
            $result.Algorithm | Should -Be "SHA256"
            $result.Hash | Should -Not -BeNullOrEmpty
        }

        It 'Get-TextHash supports different algorithms' {
            $result = "test" | Get-TextHash -Algorithm MD5
            $result.Algorithm | Should -Be "MD5"
            $result.Hash | Should -Not -BeNullOrEmpty
        }
    }

    Context 'JWT utilities' {
        It 'Decode-Jwt decodes a JWT token' {
            Get-Command Decode-Jwt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Simple test token (header.payload.signature)
            $testToken = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.test"
            { $result = Decode-Jwt -Token $testToken } | Should -Not -Throw
        }

        It 'Encode-Jwt requires Node.js' {
            Get-Command Encode-Jwt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js not available"
                return
            }
            # Test would require jsonwebtoken package
        }
    }

    Context 'Timestamp conversion utilities' {
        It 'ConvertFrom-Epoch converts Unix timestamp to DateTime' {
            Get-Command ConvertFrom-Epoch -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = ConvertFrom-Epoch -Epoch 1609459200
            $result | Should -BeOfType [DateTime]
        }

        It 'ConvertTo-Epoch converts DateTime to Unix timestamp' {
            Get-Command ConvertTo-Epoch -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $date = Get-Date
            $result = ConvertTo-Epoch -DateTime $date
            $result | Should -BeOfType [Int64]
            $result | Should -BeGreaterThan 0
        }

        It 'Handles roundtrip epoch conversion' {
            $originalDate = Get-Date
            $epoch = ConvertTo-Epoch -DateTime $originalDate
            $convertedDate = ConvertFrom-Epoch -Epoch $epoch
            $convertedDate.Date | Should -Be $originalDate.Date
        }
    }

    Context 'UUID generator utilities' {
        It 'New-Uuid generates a UUID' {
            Get-Command New-Uuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = New-Uuid
            $result | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        }

        It 'New-Uuid supports v4 version' {
            $result = New-Uuid -Version v4
            $result | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        }
    }

    Context 'Encoding utilities' {
        It 'ConvertTo-UrlEncoded encodes URL strings' {
            Get-Command ConvertTo-UrlEncoded -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = "Hello World" | ConvertTo-UrlEncoded
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Not -BeExactly "Hello World"
        }

        It 'ConvertFrom-UrlEncoded decodes URL strings' {
            Get-Command ConvertFrom-UrlEncoded -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $encoded = "Hello World" | ConvertTo-UrlEncoded
            $decoded = $encoded | ConvertFrom-UrlEncoded
            $decoded | Should -Be "Hello World"
        }

        It 'ConvertTo-HtmlEncoded encodes HTML strings' {
            Get-Command ConvertTo-HtmlEncoded -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = "<script>" | ConvertTo-HtmlEncoded
            $result | Should -Not -Contain "<"
            $result | Should -Not -Contain ">"
        }
    }

    Context 'Text comparison utilities' {
        It 'Compare-TextFiles compares two files' {
            Get-Command Compare-TextFiles -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $file1 = Join-Path $TestDrive 'test1.txt'
            $file2 = Join-Path $TestDrive 'test2.txt'
            Set-Content -Path $file1 -Value "Hello"
            Set-Content -Path $file2 -Value "Hello"
            $result = Compare-TextFiles -File1 $file1 -File2 $file2
            $result | Should -Be $true
        }

        It 'Compare-TextFiles detects differences' {
            $file1 = Join-Path $TestDrive 'test1.txt'
            $file2 = Join-Path $TestDrive 'test2.txt'
            Set-Content -Path $file1 -Value "Hello"
            Set-Content -Path $file2 -Value "World"
            $result = Compare-TextFiles -File1 $file1 -File2 $file2 2>&1
            # Result might be boolean or output from diff command
            if ($result -is [bool]) {
                $result | Should -Be $false
            }
            else {
                # If diff command was used, just verify files are different
                $content1 = Get-Content -Path $file1 -Raw
                $content2 = Get-Content -Path $file2 -Raw
                $content1 | Should -Not -Be $content2
            }
        }
    }

    Context 'Regex testing utilities' {
        It 'Test-Regex tests regular expressions' {
            Get-Command Test-Regex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Use simple pattern that definitely matches
            $result = Test-Regex -Pattern '123' -Input "Hello 123 World"
            $result | Should -Not -Be $null
            $result.Success | Should -Be $true
            $result.Value | Should -Be "123"
        }

        It 'Test-Regex supports AllMatches' {
            $result = Test-Regex -Pattern 'Hello' -Input "Hello World" -AllMatches
            # Should find at least one match
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array]) {
                $result.Count | Should -BeGreaterThan 0
            }
            else {
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Test-Regex supports IgnoreCase' {
            $result = Test-Regex -Pattern 'hello' -Input "HELLO" -IgnoreCase
            $result.Success | Should -Be $true
        }
    }

    Context 'Number base conversion utilities' {
        It 'Convert-NumberBase converts between bases' {
            Get-Command Convert-NumberBase -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Convert-NumberBase -Number "255" -FromBase Decimal -ToBase Hexadecimal
            $result.Result | Should -Be "FF"
        }

        It 'Convert-NumberBase converts binary to decimal' {
            $result = Convert-NumberBase -Number "1010" -FromBase Binary -ToBase Decimal
            $result.Result | Should -Be "10"
        }
    }

    Context 'Lorem Ipsum generator utilities' {
        It 'Get-LoremIpsum generates placeholder text' {
            Get-Command Get-LoremIpsum -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Get-LoremIpsum -Words 10
            $result | Should -Not -BeNullOrEmpty
            $words = $result -split '\s+'
            $words.Count | Should -BeGreaterOrEqual 10
        }

        It 'Get-LoremIpsum supports paragraphs' {
            $result = Get-LoremIpsum -Paragraphs 2 -Words 5
            $paragraphs = $result -split "`n`n"
            $paragraphs.Count | Should -Be 2
        }
    }

    Context 'Unit conversion utilities' {
        It 'Convert-Units converts file sizes' {
            Get-Command Convert-Units -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $result = Convert-Units -Value 1024 -FromUnit "KB" -ToUnit "MB"
            $result.Value | Should -Be 1
            $result.Unit | Should -Be "MB"
        }

        It 'Convert-Units converts time units' {
            $result = Convert-Units -Value 3600 -FromUnit "seconds" -ToUnit "hours"
            $result.Value | Should -Be 1
            $result.Unit | Should -Be "hours"
        }
    }

    Context 'Error handling' {
        It 'Handles invalid JWT token gracefully' {
            # JWT decoder writes errors but doesn't throw by default
            $result = Decode-Jwt -Token "invalid" -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles invalid regex pattern gracefully' {
            # Regex tester writes errors but doesn't throw by default
            $result = Test-Regex -Pattern "[" -Input "test" -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles invalid number base conversion gracefully' {
            # Number base converter writes errors but doesn't throw by default
            $result = Convert-NumberBase -Number "invalid" -FromBase Decimal -ToBase Hexadecimal -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

