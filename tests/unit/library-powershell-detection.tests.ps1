. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:PowerShellDetectionPath = Join-Path $script:LibPath 'runtime' 'PowerShellDetection.psm1'
    
    # Import the module under test
    Import-Module $script:PowerShellDetectionPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module PowerShellDetection -ErrorAction SilentlyContinue -Force
}

Describe 'PowerShellDetection Module Functions' {
    Context 'Get-PowerShellExecutable' {
        It 'Returns pwsh for PowerShell Core' {
            # This test verifies the function structure
            # Actual result depends on the PowerShell version running the test
            $result = Get-PowerShellExecutable
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            
            # Should be either 'pwsh' or 'powershell'
            $result | Should -Match '^(pwsh|powershell)$'
        }

        It 'Returns correct executable based on PSEdition' {
            $result = Get-PowerShellExecutable
            
            if ($PSVersionTable.PSEdition -eq 'Core') {
                $result | Should -Be 'pwsh'
            }
            else {
                $result | Should -Be 'powershell'
            }
        }

        It 'Always returns a string' {
            $result = Get-PowerShellExecutable
            $result | Should -BeOfType [string]
        }

        It 'Returns valid executable name' {
            $result = Get-PowerShellExecutable
            # Should be a valid PowerShell executable name
            $validNames = @('pwsh', 'powershell')
            $validNames | Should -Contain $result
        }
    }
}

