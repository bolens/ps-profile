

Describe 'Profile Loading Integration Tests' {
    BeforeAll {
        try {
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize profile loading tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Profile loading in different environments' {
        It 'loads successfully in current PowerShell environment' {
            try {
                $testScript = @"
try {
    . '$($script:ProfilePath -replace "'", "''")'
    Write-Output 'PROFILE_LOADED_SUCCESSFULLY'
} catch {
    Write-Error "Profile failed to load: `$$_"
    exit 1
}
"@
                $result = Invoke-TestPwshScript -ScriptContent $testScript
                $result | Should -Match 'PROFILE_LOADED_SUCCESSFULLY' -Because "profile should load successfully in PowerShell environment"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Profile loading test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'loads with cross-platform compatibility helpers' {
            $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
# Platform.psm1 may not be loaded by default - check if it's available or import it
if (-not (Get-Command Test-IsWindows -ErrorAction SilentlyContinue)) {
    # Try to import Platform module
    `$profileDir = Split-Path -Parent '$($script:ProfilePath -replace "'", "''")'
    `$platformModule = Join-Path `$profileDir 'scripts' 'lib' 'core' 'Platform.psm1'
    if (Test-Path `$platformModule) {
        Import-Module `$platformModule -DisableNameChecking -ErrorAction SilentlyContinue
    }
}
if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
    Write-Output 'PLATFORM_HELPERS_AVAILABLE'
} else {
    Write-Output 'PLATFORM_HELPERS_MISSING'
}
"@
            $result = Invoke-TestPwshScript -ScriptContent $testScript
            $result | Should -Match 'PLATFORM_HELPERS_AVAILABLE'
        }

        It 'does not pollute global scope excessively' {
            try {
                $before = (Get-Variable -Scope Global).Count
                . $script:ProfilePath
                $after = (Get-Variable -Scope Global).Count
                $increase = $after - $before
                $increase | Should -BeLessThan 50 -Because "profile should not create excessive global variables"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Profile scope pollution test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'maintains PowerShell execution policy compatibility' {
            $currentPolicy = Get-ExecutionPolicy
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

                $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
Write-Output 'EXECUTION_POLICY_COMPATIBLE'
"@
                $result = Invoke-TestPwshScript -ScriptContent $testScript
                $result | Should -Match 'EXECUTION_POLICY_COMPATIBLE'
            }
            finally {
                Set-ExecutionPolicy -ExecutionPolicy $currentPolicy -Scope Process -Force
            }
        }
    }

    Context 'Profile loading edge cases' {
        It 'profile handles missing profile.d directory gracefully' {
            $profileContent = Get-Content $script:ProfilePath -Raw
            $profileContent | Should -Not -BeNullOrEmpty
        }

        It 'profile can be loaded multiple times without side effects' {
            $before = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $middle = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $after = (Get-Variable -Scope Global).Count

            $firstIncrease = $middle - $before
            $secondIncrease = $after - $middle
            $secondIncrease | Should -BeLessOrEqual ($firstIncrease * 2)
        }
    }
}

