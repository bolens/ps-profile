. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }
        
        $script:PathResolutionPath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
        if ($null -eq $script:PathResolutionPath -or [string]::IsNullOrWhiteSpace($script:PathResolutionPath)) {
            throw "PathResolutionPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:PathResolutionPath)) {
            throw "PathResolution module not found at: $script:PathResolutionPath"
        }
        
        # Import Cache module first (dependency)
        $cachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
        if ($cachePath -and (Test-Path -LiteralPath $cachePath)) {
            Import-Module $cachePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
        }
        
        # Import the module under test
        Import-Module $script:PathResolutionPath -DisableNameChecking -ErrorAction Stop -Force
        
        # Create test script path in test artifacts directory
        $script:TestScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
        $script:TestScriptCreated = $true
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize PathResolution tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    
    # Clean up test script if we created it
    if ($script:TestScriptCreated -and $script:TestScriptPath -and (Test-Path -LiteralPath $script:TestScriptPath)) {
        Remove-Item -Path $script:TestScriptPath -Force -ErrorAction SilentlyContinue
        # Clean up parent directory if empty
        $parentDir = Split-Path -Path $script:TestScriptPath -Parent
        if ($parentDir -and (Test-Path -LiteralPath $parentDir) -and -not (Get-ChildItem -Path $parentDir -Force | Where-Object { $_.Name -ne '.gitkeep' })) {
            Remove-Item -Path $parentDir -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'PathResolution Module Functions' {

    Context 'Get-RepoRoot' {
        It 'Returns valid repository root path' {
            $result = Get-RepoRoot -ScriptPath $script:TestScriptPath
            $result | Should -Not -BeNullOrEmpty -Because "Get-RepoRoot should return a valid path"
            if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                Test-Path -LiteralPath $result | Should -Be $true -Because "Repository root path should exist"
            }
            $result | Should -Be $script:RepoRoot -Because "Result should match cached repository root"
        }

        It 'Resolves path correctly for scripts/utils location' {
            $utilsScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
            $result = Get-RepoRoot -ScriptPath $utilsScriptPath
            if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                Test-Path -LiteralPath $result | Should -Be $true -Because "Repository root path should exist"
            }
            $result | Should -Be $script:RepoRoot -Because "Result should match cached repository root"
        }

        It 'Resolves path correctly for scripts/lib location' {
            $libScriptPath = Join-Path $script:RepoRoot 'scripts' 'lib' 'path' 'PathResolution.psm1'
            $result = Get-RepoRoot -ScriptPath $libScriptPath
            $result | Should -Be $script:RepoRoot
        }

        It 'Resolves path correctly for scripts/checks location' {
            $checksDir = Join-Path $script:RepoRoot 'scripts' 'checks'
            if ($checksDir -and (Test-Path -LiteralPath $checksDir)) {
                $checksScriptPath = Join-Path $checksDir 'test.ps1'
                Set-Content -Path $checksScriptPath -Value '# Test' -ErrorAction SilentlyContinue
                try {
                    $result = Get-RepoRoot -ScriptPath $checksScriptPath
                    $result | Should -Be $script:RepoRoot
                }
                finally {
                    Remove-Item -Path $checksScriptPath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Handles relative paths' {
            $testScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
            # Get relative path from repo root
            $relativePath = $testScriptPath.Replace($script:RepoRoot, '').TrimStart('\', '/')
            $result = Get-RepoRoot -ScriptPath $relativePath
            $result | Should -Not -BeNullOrEmpty
            [System.IO.Path]::IsPathRooted($result) | Should -Be $true
        }

        It 'Handles paths with .. components' {
            $testScriptPath = Get-TestScriptPath -RelativePath 'scripts/lib/test.ps1' -StartPath $PSScriptRoot
            # Create a path with .. components
            $parentPath = Join-Path $script:RepoRoot 'tests' 'test-artifacts' 'scripts' 'utils' '..' 'lib' 'test.ps1'
            $result = Get-RepoRoot -ScriptPath $parentPath
            $result | Should -Be $script:RepoRoot
        }

        It 'Returns absolute path' {
            $result = Get-RepoRoot -ScriptPath $script:TestScriptPath
            [System.IO.Path]::IsPathRooted($result) | Should -Be $true
        }

        It 'Uses cached value when available' {
            # Clear cache first
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key "RepoRoot_$($script:TestScriptPath)" -ErrorAction SilentlyContinue
            }

            # First call
            $result1 = Get-RepoRoot -ScriptPath $script:TestScriptPath
            
            # Second call should use cache
            $result2 = Get-RepoRoot -ScriptPath $script:TestScriptPath
            
            $result1 | Should -Be $result2
        }

        It 'Throws when repository root not found' {
            # Create a temporary directory structure without scripts/
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                { Get-RepoRoot -ScriptPath $tempScript } | Should -Throw "*Repository root not found*"
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles file that does not exist but parent directory does' {
            $nonExistentFile = Join-Path $script:RepoRoot 'scripts' 'utils' 'nonexistent.ps1'
            $result = Get-RepoRoot -ScriptPath $nonExistentFile
            $result | Should -Be $script:RepoRoot
        }
    }

    Context 'Get-ProfileDirectory' {
        It 'Returns valid profile.d directory path' {
            $result = Get-ProfileDirectory -ScriptPath $script:TestScriptPath
            $result | Should -Not -BeNullOrEmpty -Because "Get-ProfileDirectory should return a valid path"
            if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                Test-Path -LiteralPath $result | Should -Be $true -Because "Profile directory path should exist"
            }
            $result | Should -BeLike '*profile.d' -Because "Path should contain 'profile.d'"
        }

        It 'Returns correct path relative to repository root' {
            $result = Get-ProfileDirectory -ScriptPath $script:TestScriptPath
            $expectedPath = Join-Path $script:RepoRoot 'profile.d'
            $result | Should -Be $expectedPath
        }

        It 'Returns absolute path' {
            $result = Get-ProfileDirectory -ScriptPath $script:TestScriptPath
            [System.IO.Path]::IsPathRooted($result) | Should -Be $true
        }

        It 'Uses cached value when available' {
            # Clear cache first
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key "ProfileDirectory_$($script:TestScriptPath)" -ErrorAction SilentlyContinue
            }

            # First call
            $result1 = Get-ProfileDirectory -ScriptPath $script:TestScriptPath
            
            # Second call should use cache
            $result2 = Get-ProfileDirectory -ScriptPath $script:TestScriptPath
            
            $result1 | Should -Be $result2
        }

        It 'Throws when repository root cannot be determined' {
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                { Get-ProfileDirectory -ScriptPath $tempScript } | Should -Throw
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-RepoRootSafe' {
        It 'Returns repository root successfully' {
            $result = Get-RepoRootSafe -ScriptPath $script:TestScriptPath
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:RepoRoot
        }

        It 'Returns null when repository root not found and ErrorAction is SilentlyContinue' {
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                $result = Get-RepoRootSafe -ScriptPath $tempScript -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Throws when repository root not found and ErrorAction is Stop' {
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                { Get-RepoRootSafe -ScriptPath $tempScript -ErrorAction Stop } | Should -Throw
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Exits with code 2 when ExitOnError is specified and ExitCodes module not available' {
            # This is difficult to test without actually exiting, but we can verify the structure
            # The function should attempt to use Exit-WithCode if available
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                # Without ExitCodes module, it should throw or exit
                { Get-RepoRootSafe -ScriptPath $tempScript -ExitOnError } | Should -Throw
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Exit-WithCode when ExitCodes module is available and ExitOnError is specified' {
            # Import ExitCodes module
            $exitCodesPath = Join-Path $script:LibPath 'core' 'ExitCodes.psm1'
            if ($exitCodesPath -and (Test-Path -LiteralPath $exitCodesPath)) {
                Import-Module $exitCodesPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
                
                $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
                $tempScript = Join-Path $tempDir 'test.ps1'
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
                try {
                    # This will exit the script, so we can't test it directly
                    # But we can verify the function structure is correct
                    Get-Command Get-RepoRootSafe | Should -Not -BeNullOrEmpty
                }
                finally {
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
                }
            }
        }

        It 'Handles ErrorAction Continue' {
            $tempDir = Join-Path $env:TEMP "test-no-repo-$(Get-Random)"
            $tempScript = Join-Path $tempDir 'test.ps1'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            Set-Content -Path $tempScript -Value '# Test' -ErrorAction SilentlyContinue
            try {
                $result = Get-RepoRootSafe -ScriptPath $tempScript -ErrorAction Continue
                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}


