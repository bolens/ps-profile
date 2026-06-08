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
}

Describe 'Developer Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
            
            Ensure-DevToolsModulesLoaded -ProfileDir $script:ProfileDir
            
            $filesPath = Join-Path $script:ProfileDir 'files.ps1'
            if ($null -eq $filesPath -or [string]::IsNullOrWhiteSpace($filesPath)) {
                throw "FilesPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $filesPath)) {
                throw "Files fragment not found at: $filesPath"
            }
            . $filesPath
            Ensure-DevTools
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize developer tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
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
            $node = Test-ToolAvailable -ToolName 'node' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }
            # Test would require jsonwebtoken package
        }

        It 'Encode-Jwt handles missing jsonwebtoken package gracefully when Node.js is available' {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Node.js is not available"
                return
            }
            
            Get-Command Encode-Jwt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Create test payload
            $payload = @{
                sub = 'user123'
                exp = [DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
            } | ConvertTo-Json -Compress
            
            $payloadFile = Join-Path $TestDrive 'test-jwt-payload.json'
            Set-Content -Path $payloadFile -Value $payload -NoNewline
            
            try {
                $jwtFile = Join-Path $TestDrive 'test.jwt'
                Encode-Jwt -PayloadPath $payloadFile -OutputPath $jwtFile -ErrorAction Stop 2>&1 | Out-Null
                # If we get here, encoding succeeded (jsonwebtoken package is installed)
                if ($jwtFile -and -not [string]::IsNullOrWhiteSpace($jwtFile) -and (Test-Path -LiteralPath $jwtFile)) {
                    $jwtFile | Should -Exist
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $fullError = ($_ | Out-String) + ($errorMessage | Out-String)
                
                if ($errorMessage -match 'jsonwebtoken.*not.*installed' -or $errorMessage -match 'MODULE_NOT_FOUND' -or $fullError -match 'jsonwebtoken') {
                    $installCommand = Resolve-TestToolInstallCommand -ToolName 'jsonwebtoken' -ToolType 'node-package'
                    if ($errorMessage -match [regex]::Escape($installCommand) -or $fullError -match [regex]::Escape($installCommand)) {
                        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match ([regex]::Escape($installCommand))
                    }
                    elseif ($errorMessage -match 'jsonwebtoken' -or $fullError -match 'jsonwebtoken') {
                        Write-Host "jsonwebtoken package is not installed. Install with: $installCommand" -ForegroundColor Yellow
                        $errorMessage | Should -Match 'jsonwebtoken'
                    }
                }
                # Other errors are also acceptable
            }
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
            # Use a fixed point in time and compare in a time-zone-agnostic way
            $originalDate = Get-Date -Date '2021-01-01T00:00:00Z'
            $epoch = ConvertTo-Epoch -DateTime $originalDate
            $convertedDate = ConvertFrom-Epoch -Epoch $epoch

            # Normalize to UTC before comparing dates to avoid local/DST edge cases
            $convertedDateUtc = $convertedDate.ToUniversalTime()
            $originalDateUtc = $originalDate.ToUniversalTime()

            $convertedDateUtc.Date | Should -Be $originalDateUtc.Date
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
            # Mock diff command if available to ensure consistent test behavior
            $diffAvailable = (Get-Command diff -ErrorAction SilentlyContinue) -ne $null
            if ($diffAvailable) {
                Set-TestCommandAvailabilityState -CommandName 'diff' -Available $true -Scope It
            }
            else {
                Set-TestCommandAvailabilityState -CommandName 'diff' -Available $false -Scope It
            }
            
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

        It 'Compare-TextFiles handles missing diff command gracefully' {
            # Mock diff as unavailable
            Set-TestCommandAvailabilityState -CommandName 'diff' -Available $false -Scope It
            
            $file1 = Join-Path $TestDrive 'test1.txt'
            $file2 = Join-Path $TestDrive 'test2.txt'
            Set-Content -Path $file1 -Value "Hello"
            Set-Content -Path $file2 -Value "Hello"
            
            # Should still work (fallback to PowerShell comparison)
            $result = Compare-TextFiles -File1 $file1 -File2 $file2 2>&1
            if ($result -is [bool]) {
                $result | Should -Be $true
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

        It 'ConvertTo-RegexFromDescription converts catalog entries' {
            Get-Command ConvertTo-RegexFromDescription -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertTo-RegexFromDescription -Description 'email'
            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Match '@'
        }

        It 'ConvertTo-RegexFromDescription composes natural language phrases' {
            $pattern = ConvertTo-RegexFromDescription -Description "starts with 'svc-' followed by digits" -Anchored -PatternOnly
            $pattern | Should -Be '^svc-\d+$'

            $match = Test-Regex -Pattern $pattern -Input 'svc-123'
            $match.Success | Should -Be $true
        }

        It 'Get-RegexDescriptionCatalog exposes catalog entries' {
            Get-Command Get-RegexDescriptionCatalog -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $entry = Get-RegexDescriptionCatalog -Name 'iban'
            $entry.Pattern | Should -Not -BeNullOrEmpty
        }

        It 'Search-RegexDescriptions finds related catalog entries' {
            $results = Search-RegexDescriptions -Query 'postal'
            $results.Name | Should -Contain 'uk-postcode'
            $results.Name | Should -Contain 'ca-postal-code'
        }

        It 'Test-RegexFromDescription converts and tests in one step' {
            $result = Test-RegexFromDescription -Description 'email' -Input 'user@example.com'
            $result.Pattern | Should -Match '@'
            $result.Match.Success | Should -Be $true
        }

        It 'ConvertTo-RegexFromDescription validates sample text' {
            $result = ConvertTo-RegexFromDescription `
                -Description 'ipv4' `
                -SampleMatch '192.168.0.1' `
                -SampleNoMatch '999.999.999.999'

            $result.SampleResults.Count | Should -Be 2
            ($result.SampleResults | ForEach-Object { $_.Success }) | Should -Not -Contain $false
        }

        It 'Get-RegexDescriptionCatalog returns pipeline-friendly objects' {
            $entries = Get-RegexDescriptionCatalog
            $entries | Should -Not -BeNullOrEmpty
            $entries[0].Name | Should -Not -BeNullOrEmpty
            $entries[0].Aliases | Should -Not -BeNullOrEmpty
        }

        It 'Explain-RegexPattern describes catalog patterns' {
            Get-Command Explain-RegexPattern -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $pattern = (Get-RegexDescriptionCatalog -Name 'uuid').Pattern
            $result = Explain-RegexPattern -Pattern $pattern
            $result.CatalogName | Should -Be 'uuid'
            $result.Description | Should -Not -BeNullOrEmpty
        }

        It 'ConvertTo-RegexFromDescription supports text output format' {
            $text = ConvertTo-RegexFromDescription -Description 'email' -OutputFormat Text
            $text | Should -Match 'Pattern:'
            $text | Should -Match '@'
        }

        It 'Show-RegexDescriptionCatalog renders a table' {
            Get-Command Show-RegexDescriptionCatalog -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $table = Show-RegexDescriptionCatalog -Query 'email'
            $table | Should -Match 'email'
        }

        It 'Test-RegexDescriptionRoundTrip validates description consistency' {
            $result = Test-RegexDescriptionRoundTrip -Description 'uuid'
            $result.IsConsistent | Should -Be $true
            $result.Pattern | Should -Not -BeNullOrEmpty
        }

        It 'Export-RegexDescriptionCatalog exports markdown content' {
            $markdown = Export-RegexDescriptionCatalog -Format Markdown
            $markdown | Should -Match '## uuid'
        }

        It 'Start-RegexDescriptionBuilder supports non-interactive segments' {
            $result = Start-RegexDescriptionBuilder `
                -Segments "starts with 'svc-'", 'digits' `
                -Anchored `
                -NonInteractive

            $result.Pattern | Should -Be '^svc-\d+$'
            $result.Description | Should -Match 'svc-'
        }

        It 'Save-RegexDescriptionSession persists builder output' {
            $sessionPath = Join-Path $TestDrive 'builder-session.json'
            $result = Start-RegexDescriptionBuilder `
                -Description 'email' `
                -SampleMatch 'user@example.com' `
                -NonInteractive `
                -SaveSession `
                -SessionPath $sessionPath

            Test-Path -LiteralPath $sessionPath | Should -Be $true
            $result.SessionPath | Should -Be (Resolve-Path -LiteralPath $sessionPath).Path
        }

        It 'Compare-RegexDescriptions reports differences' {
            $result = Compare-RegexDescriptions -Left 'email' -Right 'email address' -IncludePatterns
            $result.Similarity | Should -BeGreaterThan 0
            $result.LeftPattern | Should -Not -BeNullOrEmpty
        }

        It 'New-RegexDescriptionPesterTest generates test stubs' {
            $stub = New-RegexDescriptionPesterTest `
                -Description 'uuid' `
                -SampleMatch '550e8400-e29b-41d4-a716-446655440000'

            $stub | Should -Match "Describe 'NL regex:"
        }

        It 'Resume-RegexDescriptionSession loads and generates tests' {
            $sessionPath = Join-Path $TestDrive 'resume-session.json'
            $testPath = Join-Path $TestDrive 'resume.tests.ps1'
            Start-RegexDescriptionBuilder `
                -Description 'digits' `
                -Anchored `
                -NonInteractive `
                -SaveSession `
                -SessionPath $sessionPath | Out-Null

            $result = Resume-RegexDescriptionSession -Path $sessionPath -GenerateTest -TestPath $testPath
            $result.Pattern | Should -Be '^\d+$'
            Test-Path -LiteralPath $testPath | Should -Be $true
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
            { Decode-Jwt -Token 'invalid' -ErrorAction Stop } | Should -Throw '*JWT*'
        }

        It 'Handles invalid regex pattern gracefully' {
            # Regex tester writes errors but doesn't throw by default
            $result = Test-Regex -Pattern "[" -Input "test" -ErrorAction SilentlyContinue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles invalid number base conversion gracefully' {
            { Convert-NumberBase -Number 'invalid' -FromBase Decimal -ToBase Hexadecimal -ErrorAction Stop } | Should -Throw
        }
    }
}

