. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Path Module Functions' {
    BeforeAll {
        # Import the PathResolution module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -ErrorAction Stop
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    }

    Context 'Get-RepoRoot' {
        BeforeEach {
            $script:CreatedTestFiles = @()
        }
        
        AfterEach {
            # Clean up any test files created during this test
            foreach ($file in $script:CreatedTestFiles) {
                if ($file -and (Test-Path -LiteralPath $file)) {
                    Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                }
            }
            $script:CreatedTestFiles = @()
        }
        
        It 'Returns valid repository root path' {
            # Get-RepoRoot requires script to be in a scripts/ subdirectory
            # Use test artifacts directory
            $testScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
            $script:CreatedTestFiles += $testScriptPath
            
            $result = Get-RepoRoot -ScriptPath $testScriptPath
            $result | Should -Not -BeNullOrEmpty -Because "Get-RepoRoot should return a valid path"
            if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                Test-Path -LiteralPath $result | Should -Be $true -Because "Repository root path should exist"
            }
            $result | Should -Be $script:RepoRoot -Because "Result should match cached repository root"
        }

        It 'Resolves path correctly for scripts/utils location' {
            $utilsScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
            $script:CreatedTestFiles += $utilsScriptPath
            $result = Get-RepoRoot -ScriptPath $utilsScriptPath
            if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                Test-Path -LiteralPath $result | Should -Be $true -Because "Repository root path should exist"
            }
            $result | Should -Be $script:RepoRoot -Because "Result should match cached repository root"
        }
    }
}
