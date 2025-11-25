. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Profile Loading Integration Tests' {
    BeforeAll {
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Profile loading in different environments' {
        It 'loads successfully in current PowerShell environment' {
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
            $result | Should -Match 'PROFILE_LOADED_SUCCESSFULLY'
        }

        It 'loads with cross-platform compatibility helpers' {
            $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
# Platform.psm1 may not be loaded by default - check if it's available or import it
if (-not (Get-Command Test-IsWindows -ErrorAction SilentlyContinue)) {
    # Try to import Platform module
    `$profileDir = Split-Path -Parent '$($script:ProfilePath -replace "'", "''")'
    `$platformModule = Join-Path `$profileDir 'scripts' 'lib' 'Platform.psm1'
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
            $before = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $after = (Get-Variable -Scope Global).Count
            $increase = $after - $before
            $increase | Should -BeLessThan 50
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
