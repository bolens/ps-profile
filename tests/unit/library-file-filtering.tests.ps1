. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'FileFiltering Module Functions' {
    BeforeAll {
        # Import the FileFiltering module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'FileFiltering.psm1') -DisableNameChecking -ErrorAction Stop
        $script:TestTempDir = New-TestTempDirectory -Prefix 'FileFilteringTests'
        
        # Create test directory structure
        $testDir = Join-Path $script:TestTempDir 'test'
        $gitDir = Join-Path $script:TestTempDir '.git'
        $nodeModulesDir = Join-Path $script:TestTempDir 'node_modules'
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
        New-Item -ItemType Directory -Path $nodeModulesDir -Force | Out-Null
        
        # Create test files
        $script:TestFiles = @(
            (New-Item -ItemType File -Path (Join-Path $script:TestTempDir 'script1.ps1') -Force),
            (New-Item -ItemType File -Path (Join-Path $testDir 'script2.ps1') -Force),
            (New-Item -ItemType File -Path (Join-Path $gitDir 'script3.ps1') -Force),
            (New-Item -ItemType File -Path (Join-Path $nodeModulesDir 'script4.ps1') -Force),
            (New-Item -ItemType File -Path (Join-Path $script:TestTempDir 'Common.psm1') -Force)
        )
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Filter-Files' {
        It 'Filters out test directories by default' {
            $filtered = $script:TestFiles | Filter-Files -ExcludeTests
            $filtered | Where-Object { $_.FullName -match '[\\/]tests?[\\/]' } | Should -BeNullOrEmpty
        }

        It 'Filters out git directories by default' {
            $filtered = $script:TestFiles | Filter-Files -ExcludeGit
            $filtered | Where-Object { $_.FullName -match '[\\/]\.git[\\/]' } | Should -BeNullOrEmpty
        }

        It 'Filters out node_modules by default' {
            $filtered = $script:TestFiles | Filter-Files -ExcludeNodeModules
            $filtered | Where-Object { $_.FullName -like '*\node_modules\*' -or $_.FullName -like '*/node_modules/*' } | Should -BeNullOrEmpty
        }

        It 'Filters by exclude names' {
            $filtered = $script:TestFiles | Filter-Files -ExcludeNames 'Common.psm1'
            $filtered | Where-Object { $_.Name -eq 'Common.psm1' } | Should -BeNullOrEmpty
        }

        It 'Filters by exclude patterns' {
            $filtered = $script:TestFiles | Filter-Files -ExcludePatterns '\.psm1$'
            $filtered | Where-Object { $_.Name -like '*.psm1' } | Should -BeNullOrEmpty
        }

        It 'Includes all files when exclusions are disabled' {
            $filtered = $script:TestFiles | Filter-Files -ExcludeTests:$false -ExcludeGit:$false -ExcludeNodeModules:$false
            $filtered.Count | Should -BeGreaterOrEqual $script:TestFiles.Count
        }

        It 'Handles null input gracefully' {
            $nullInput = @($null, $script:TestFiles[0], $null)
            # Use -ExcludeTests:$false to ensure the test file isn't filtered out
            $filtered = $nullInput | Filter-Files -ExcludeTests:$false -ExcludeGit:$false -ExcludeNodeModules:$false
            # Verify nulls are filtered out
            $nullCount = ($filtered | Where-Object { $null -eq $_ }).Count
            $nullCount | Should -Be 0
            # Verify valid files are still present
            $filtered.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-DefaultExclusionPatterns' {
        It 'Returns compiled regex patterns' {
            $patterns = Get-DefaultExclusionPatterns
            $patterns | Should -Not -BeNullOrEmpty
            $patterns.Tests | Should -BeOfType [regex]
            $patterns.Git | Should -BeOfType [regex]
            $patterns.NodeModules | Should -BeOfType [regex]
        }

        It 'Patterns match expected paths' {
            $patterns = Get-DefaultExclusionPatterns
            'C:\project\tests\script.ps1' | Should -Match $patterns.Tests
            'C:\project\.git\config' | Should -Match $patterns.Git
            'C:\project\node_modules\package\index.js' | Should -Match $patterns.NodeModules
        }
    }
}

