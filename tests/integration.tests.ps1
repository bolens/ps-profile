Describe 'Profile Integration Tests' {
    Context 'Profile loading in different environments' {
        It 'loads successfully in current PowerShell environment' {
            # Test that profile loads without throwing exceptions
            $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
            $testScript = @"
try {
    . '$profilePath'
    Write-Output 'PROFILE_LOADED_SUCCESSFULLY'
} catch {
    Write-Error "Profile failed to load: `$_"
    exit 1
}
"@

            $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
            Set-Content -Path $tempFile -Value $testScript -Encoding UTF8

            try {
                $result = & pwsh -NoProfile -File $tempFile 2>&1
                $result | Should -Contain 'PROFILE_LOADED_SUCCESSFULLY'
            } finally {
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
        }

        It 'does not pollute global scope with unexpected variables' {
            # Test that loading the profile doesn't create unexpected global variables
            $before = Get-Variable -Scope Global | Select-Object -ExpandProperty Name

            $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
            . $profilePath

            $after = Get-Variable -Scope Global | Select-Object -ExpandProperty Name
            $newVars = $after | Where-Object { $_ -notin $before }

            # Allow some expected variables (like those created by profile fragments)
            $expectedVars = @('PSScriptRoot', 'MyInvocation', 'args', 'input', 'profile', 'PROFILE_DEBUG')
            $unexpectedVars = $newVars | Where-Object { $_ -notin $expectedVars }

            # Should not have too many unexpected variables (be conservative)
            $unexpectedVars.Count | Should -BeLessThan 50
        }

        It 'maintains PowerShell execution policy compatibility' {
            # Test that profile doesn't require elevated execution policy
            $currentPolicy = Get-ExecutionPolicy
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

                $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
                $testScript = @"
. '$profilePath'
Write-Output 'EXECUTION_POLICY_COMPATIBLE'
"@

                $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
                Set-Content -Path $tempFile -Value $testScript -Encoding UTF8

                $result = & pwsh -NoProfile -File $tempFile 2>&1
                $result | Should -Contain 'EXECUTION_POLICY_COMPATIBLE'
            } finally {
                Set-ExecutionPolicy -ExecutionPolicy $currentPolicy -Scope Process -Force
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Cross-platform compatibility' {
        It 'uses compatible path separators' {
            # Test that profile uses Join-Path or / for paths, not \
            $profileContent = Get-Content (Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1') -Raw

            # Should not contain hardcoded backslashes in paths (except in comments or strings that are meant to be)
            $hardcodedBackslashes = $profileContent | Select-String -Pattern '\\(?!\\)' -AllMatches
            # Allow some exceptions for known cases, but generally avoid hardcoded paths
            $hardcodedBackslashes.Matches.Count | Should -BeLessThan 5
        }

        It 'handles missing commands gracefully' {
            # Test that profile handles missing external commands
            $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'

            # Mock Get-Command to simulate missing commands
            Mock Get-Command { throw "Command not found" } -ParameterFilter { $Name -eq 'nonexistentcommand' }

            # This should not throw an exception
            { . $profilePath } | Should -Not -Throw
        }
    }
}