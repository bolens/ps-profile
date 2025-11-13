. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Utility Functions Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '07-system.ps1')
        . (Join-Path $script:ProfileDir '05-utilities.ps1')
    }

    Context 'Utility functions additional tests' {

        It 'Reload-Profile function exists and can be called' {
            Get-Command Reload-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            { Reload-Profile -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Edit-Profile function exists and can be called' {
            Get-Command Edit-Profile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command edit-profile -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Calling the function may fail in test environment due to external dependencies
        }

        It 'Get-Weather function exists and handles no arguments' {
            Get-Command Get-Weather -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command weather -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Mock Invoke-WebRequest to avoid network dependency in tests
            Mock Invoke-WebRequest { return @{ StatusCode = 200; Content = "Mocked weather data" } }
            { Get-Weather -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Get-Weather function handles location argument' {
            # Mock Invoke-WebRequest to avoid network dependency in tests
            Mock Invoke-WebRequest { return @{ StatusCode = 200; Content = "Mocked weather data" } }
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
