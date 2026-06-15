

BeforeAll {
    try {
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

Describe "Oh My Posh Module" {
    Context "Initialize-OhMyPosh" {
        BeforeEach {
            $bootstrapFragment = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($bootstrapFragment -and -not [string]::IsNullOrWhiteSpace($bootstrapFragment) -and (Test-Path -LiteralPath $bootstrapFragment)) {
                . $bootstrapFragment
            }

            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

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
            $global:OhMyPoshInitialized = $true

            { Initialize-OhMyPosh } | Should -Not -Throw

            $global:OhMyPoshInitialized | Should -Be $true
        }

        It "Should handle oh-my-posh not available gracefully" {
            Mark-TestCommandsUnavailable -CommandNames @('oh-my-posh')
            Set-TestCommandAvailabilityState -CommandName 'oh-my-posh' -Available $false
            { Initialize-OhMyPosh } | Should -Not -Throw
        }
    }

    Context "prompt function" {
        BeforeEach {
            $bootstrapFragment = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($bootstrapFragment -and -not [string]::IsNullOrWhiteSpace($bootstrapFragment) -and (Test-Path -LiteralPath $bootstrapFragment)) {
                . $bootstrapFragment
            }

            Mark-TestCommandsUnavailable -CommandNames @('oh-my-posh')
            Set-TestCommandAvailabilityState -CommandName 'oh-my-posh' -Available $false

            if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            }
            Remove-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue

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
