. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:RequirementsLoaderPath = Join-Path $script:LibPath 'utilities' 'RequirementsLoader.psm1'
    
    # Import Cache module first (dependency)
    $cachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
    if (Test-Path $cachePath) {
        Import-Module $cachePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import DataFile module (dependency)
    $dataFilePath = Join-Path $script:LibPath 'utilities' 'DataFile.psm1'
    if (Test-Path $dataFilePath) {
        Import-Module $dataFilePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:RequirementsLoaderPath -DisableNameChecking -ErrorAction Stop -Force
    $script:TestTempDir = New-TestTempDirectory -Prefix 'RequirementsLoaderTests'
}

AfterAll {
    Remove-Module RequirementsLoader -ErrorAction SilentlyContinue -Force
    Remove-Module DataFile -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
        Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'RequirementsLoader Module Functions' {
    Context 'Import-Requirements' {
        It 'Throws error when repository root cannot be detected' {
            $invalidPath = Join-Path $script:TestTempDir 'nonexistent'
            { Import-Requirements -RepoRoot $invalidPath } | Should -Throw
        }

        It 'Throws error when requirements loader does not exist' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            # Create requirements directory but no loader file
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            { Import-Requirements -RepoRoot $testRepoRoot } | Should -Throw
        }

        It 'Loads requirements from modular structure' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo2'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = "7.0"
    Modules = @{
        Pester = "5.0.0"
    }
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -Path $loaderFile -Encoding UTF8

            $result = Import-Requirements -RepoRoot $testRepoRoot
            $result | Should -Not -BeNullOrEmpty
            $result.PowerShellVersion | Should -Be '7.0'
            $result.Modules | Should -Not -BeNullOrEmpty
        }

        It 'Uses cache when UseCache is enabled' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo3'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = "7.0"
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -Path $loaderFile -Encoding UTF8

            # First call
            $result1 = Import-Requirements -RepoRoot $testRepoRoot -UseCache
            $result1 | Should -Not -BeNullOrEmpty
            
            # Second call should use cache
            $result2 = Import-Requirements -RepoRoot $testRepoRoot -UseCache
            $result2 | Should -Not -BeNullOrEmpty
            $result1.PowerShellVersion | Should -Be $result2.PowerShellVersion
        }

        It 'Bypasses cache when UseCache is disabled' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo4'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = "7.0"
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -Path $loaderFile -Encoding UTF8

            $result = Import-Requirements -RepoRoot $testRepoRoot -UseCache:$false
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Detects repository root from current location' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo5'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = "7.0"
    Modules = @{}
    ExternalTools = @{}
    PlatformRequirements = @{}
}
'@ | Set-Content -Path $loaderFile -Encoding UTF8

            # Change to a subdirectory and test detection
            $subDir = Join-Path $testRepoRoot 'subdir'
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null
            
            Push-Location $subDir
            try {
                $result = Import-Requirements
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles loader script errors gracefully' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo6'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            # Create a loader that will throw an error
            'throw "Loader error"' | Set-Content -Path $loaderFile -Encoding UTF8

            { Import-Requirements -RepoRoot $testRepoRoot } | Should -Throw
        }

        It 'Returns hashtable with expected structure' {
            $testRepoRoot = Join-Path $script:TestTempDir 'test-repo7'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $requirementsDir = Join-Path $testRepoRoot 'requirements'
            New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
            
            $loaderFile = Join-Path $requirementsDir 'load-requirements.ps1'
            @'
@{
    PowerShellVersion = "7.0"
    Modules = @{
        Pester = "5.0.0"
        PSScriptAnalyzer = "1.21.0"
    }
    ExternalTools = @{
        git = @{
            InstallCommand = "scoop install git"
        }
    }
    PlatformRequirements = @{
        Windows = @{
            PowerShell = "7.0"
        }
    }
}
'@ | Set-Content -Path $loaderFile -Encoding UTF8

            $result = Import-Requirements -RepoRoot $testRepoRoot
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [hashtable]
            $result.PowerShellVersion | Should -Be '7.0'
            $result.Modules | Should -BeOfType [hashtable]
            $result.Modules.Pester | Should -Be '5.0.0'
            $result.ExternalTools | Should -BeOfType [hashtable]
            $result.PlatformRequirements | Should -BeOfType [hashtable]
        }
    }
}

