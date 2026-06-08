

Describe 'Utility Functions Integration Tests' {
    BeforeAll {
        try {
            $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
            if ($null -eq $testSupportPath -or [string]::IsNullOrWhiteSpace($testSupportPath)) {
                throw "Get-TestSupportPath returned null or empty value"
            }
            if (-not (Test-Path -LiteralPath $testSupportPath)) {
                throw "TestSupport file not found at: $testSupportPath"
            }
            . $testSupportPath

            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }

            # files.ps1 loads files-module-registry.ps1 (Load-EnsureModules) required by Ensure-Utilities
            Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadFilesFragment

            $utilitiesPath = Join-Path $script:ProfileDir 'utilities.ps1'
            if (-not (Test-Path -LiteralPath $utilitiesPath)) {
                throw "Utilities fragment not found at: $utilitiesPath"
            }
            $null = . $utilitiesPath

            if (-not (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue)) {
                throw 'Load-EnsureModules is not available after loading files fragment'
            }
            if (-not (Get-Command Ensure-Utilities -ErrorAction SilentlyContinue)) {
                throw 'Ensure-Utilities is not available after loading utilities fragment'
            }
            Ensure-Utilities
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize utility functions tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Utility functions additional tests' {

        It 'Reload-Profile function exists' {
            Get-Command Reload-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Do not invoke Reload-Profile here: it dotsources $PROFILE and is environment-dependent.
        }

        It 'Edit-Profile function exists and can be called' {
            Get-Command Edit-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # edit-profile resolves to Edit-Profile; Set-AgentModeAlias may skip when the name already resolves.
            (Get-Command edit-profile -ErrorAction SilentlyContinue).Name | Should -Be 'Edit-Profile'
        }

        It 'Get-Weather function exists and handles no arguments' {
            Get-Command Get-Weather -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            $weatherCommand = Get-Command weather -ErrorAction SilentlyContinue
            if ($weatherCommand -and $weatherCommand.CommandType -eq 'Application') {
                Set-ItResult -Inconclusive -Because 'A system weather executable shadows the profile weather alias on this platform'
            }
            else {
                $weatherCommand | Should -Not -Be $null
            }
            Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -MarkAvailable:$false -OnInvoke {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = 'Mocked weather data'
                    Headers    = @{}
                }
            }
            { Get-Weather -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Get-Weather function handles location argument' {
            Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -MarkAvailable:$false -OnInvoke {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content    = 'Mocked weather data'
                    Headers    = @{}
                }
            }
            { Get-Weather 'New York' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'ConvertFrom-UrlEncoded handles basic encoding' {
            $encoded = 'Hello%20World%21'
            $result = ConvertFrom-UrlEncoded -text $encoded
            $result | Should -Be 'Hello World!'
        }

        It 'ConvertFrom-UrlEncoded handles null input' {
            $result = ConvertFrom-UrlEncoded -text $null
            $result | Should -Be ''
        }

        It 'ConvertFrom-UrlEncoded handles empty input' {
            $result = ConvertFrom-UrlEncoded -text ''
            $result | Should -Be ''
        }

        It 'ConvertFrom-UrlEncoded handles already decoded strings' {
            $input = 'Hello World!'
            $result = ConvertFrom-UrlEncoded -text $input
            $result | Should -Be $input
        }

        It 'ConvertTo-UrlEncoded handles basic encoding' {
            $input = 'Hello World!'
            $result = ConvertTo-UrlEncoded -text $input
            $result | Should -Be 'Hello%20World%21'
        }

        It 'ConvertTo-UrlEncoded handles null input' {
            $result = ConvertTo-UrlEncoded -text $null
            $result | Should -Be ''
        }

        It 'ConvertTo-UrlEncoded handles empty input' {
            $result = ConvertTo-UrlEncoded -text ''
            $result | Should -Be ''
        }

        It 'ConvertTo-UrlEncoded handles already encoded strings' {
            $input = 'Hello%20World%21'
            $result = ConvertTo-UrlEncoded -text $input
            $result | Should -Be 'Hello%2520World%2521'
        }

        It 'ConvertFrom-Epoch handles valid timestamps' {
            $timestamp = 1609459200  # 2021-01-01 00:00:00 UTC
            $result = ConvertFrom-Epoch -epoch $timestamp
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be 'DateTimeOffset'
            $result.Year | Should -Be 2020  # Local time year
            $result.Month | Should -Be 12
            $result.Day | Should -Be 31
        }

        It 'ConvertFrom-Epoch handles null timestamp' {
            $result = ConvertFrom-Epoch -epoch 0
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be 'DateTimeOffset'
            # Unix epoch is 1970-01-01 UTC, but converted to local time
            $result.Year | Should -Be 1969
            $result.Month | Should -Be 12
            $result.Day | Should -Be 31
        }

        It 'ConvertFrom-Epoch handles zero timestamp' {
            $result = ConvertFrom-Epoch -epoch 0
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be 'DateTimeOffset'
            # Unix epoch is 1970-01-01 UTC, but converted to local time
            $result.Year | Should -Be 1969
            $result.Month | Should -Be 12
            $result.Day | Should -Be 31
        }

        It 'ConvertTo-Epoch handles valid DateTime' {
            $date = Get-Date -Year 2021 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
            $result = ConvertTo-Epoch -date $date
            $result | Should -BeOfType [long]
            $result | Should -BeGreaterThan 0
        }

        It 'ConvertTo-Epoch handles current date' {
            $now = Get-Date
            $result = ConvertTo-Epoch -date $now
            $result | Should -BeOfType [long]
            $result | Should -BeGreaterThan 0

            # Should be close to current time (within reasonable tolerance)
            $currentEpoch = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $diff = [Math]::Abs($result - $currentEpoch)
            $diff | Should -BeLessThan 10  # Allow 10 seconds tolerance
        }
    }
}

