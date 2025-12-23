

Describe "Oh My Posh Module" {
    BeforeAll {
        try {
            # Source the test support
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize oh-my-posh tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context "Initialize-OhMyPosh" {
        BeforeEach {
            # Load bootstrap fragment first to make Test-HasCommand available
            $bootstrapFragment = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($bootstrapFragment -and -not [string]::IsNullOrWhiteSpace($bootstrapFragment) -and (Test-Path -LiteralPath $bootstrapFragment)) {
                . $bootstrapFragment
            }

            # Remove any existing prompt function and variables
            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

            # Load the oh-my-posh fragment directly
            $ohMyPoshFragment = Get-TestPath "profile.d\oh-my-posh.ps1" -StartPath $PSScriptRoot -EnsureExists
            . $ohMyPoshFragment
        }

        It "Should exist and be callable" {
            try {
                { Get-Command Initialize-OhMyPosh -ErrorAction Stop } | Should -Not -Throw -Because "Initialize-OhMyPosh function should be available"
                { Initialize-OhMyPosh } | Should -Not -Throw -Because "Initialize-OhMyPosh should execute without errors"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Initialize-OhMyPosh availability test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It "Should skip initialization if already initialized" {
            # Set the global variable first
            $global:OhMyPoshInitialized = $true

            { Initialize-OhMyPosh } | Should -Not -Throw

            # Global variable should still be true
            $global:OhMyPoshInitialized | Should -Be $true
        }

        It "Should handle oh-my-posh not available gracefully" {
            # Mock oh-my-posh as unavailable using standardized mocking pattern
            Mock-CommandAvailabilityPester -CommandName 'oh-my-posh' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'oh-my-posh' } -MockWith { $false }
            { Initialize-OhMyPosh } | Should -Not -Throw
        }
    }

    Context "prompt function" {
        BeforeEach {
            # Load bootstrap fragment first to make Test-HasCommand available
            $bootstrapFragment = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($bootstrapFragment -and -not [string]::IsNullOrWhiteSpace($bootstrapFragment) -and (Test-Path -LiteralPath $bootstrapFragment)) {
                . $bootstrapFragment
            }

            # Mock oh-my-posh as unavailable using standardized mocking pattern
            Mock-CommandAvailabilityPester -CommandName 'oh-my-posh' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'oh-my-posh' } -MockWith { $false }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'oh-my-posh' } -MockWith { $null }

            # Remove any existing prompt function and variables
            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

            # Load the oh-my-posh fragment directly
            $ohMyPoshFragment = Get-TestPath "profile.d\oh-my-posh.ps1" -StartPath $PSScriptRoot -EnsureExists
            . $ohMyPoshFragment
        }

        It "Should exist and be callable" {
            { Get-Command prompt -ErrorAction Stop } | Should -Not -Throw
            { prompt } | Should -Not -Throw
            $result = prompt
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return a string" {
            $result = prompt
            $result | Should -BeOfType [string]
        }
    }
}

