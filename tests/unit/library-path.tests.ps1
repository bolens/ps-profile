. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Path Module Functions' {
    BeforeAll {
        # Import the PathResolution module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'PathResolution.psm1') -DisableNameChecking -ErrorAction Stop
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    }

    Context 'Get-RepoRoot' {
        It 'Returns valid repository root path' {
            # Get-RepoRoot requires script to be in a scripts/ subdirectory
            # Use an actual script path from the repository
            $testScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test.ps1'
            if (-not (Test-Path $testScriptPath)) {
                # Create a temporary script file for testing
                $testScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test-repo-root.ps1'
                Set-Content -Path $testScriptPath -Value '# Test script' -ErrorAction SilentlyContinue
            }
            
            $result = Get-RepoRoot -ScriptPath $testScriptPath
            $result | Should -Not -BeNullOrEmpty
            Test-Path $result | Should -Be $true
            $result | Should -Be $script:RepoRoot
        }

        It 'Resolves path correctly for scripts/utils location' {
            $utilsScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test.ps1'
            if (-not (Test-Path $utilsScriptPath)) {
                $utilsScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test-repo-root.ps1'
                Set-Content -Path $utilsScriptPath -Value '# Test script' -ErrorAction SilentlyContinue
            }
            $result = Get-RepoRoot -ScriptPath $utilsScriptPath
            Test-Path $result | Should -Be $true
            $result | Should -Be $script:RepoRoot
        }
    }
}
