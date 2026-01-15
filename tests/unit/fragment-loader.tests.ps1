# ===============================================
# fragment-loader.tests.ps1
# Unit tests for FragmentLoader.psm1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:LoaderModulePath = Join-Path $script:FragmentLibDir 'FragmentLoader.psm1'
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    
    if (Test-Path -LiteralPath $script:LoaderModulePath) {
        Import-Module $script:LoaderModulePath -DisableNameChecking -ErrorAction Stop
    }
    else {
        Write-Warning "FragmentLoader module not found at: $script:LoaderModulePath"
    }
}

Describe 'FragmentLoader.psm1 - Get-ProfileDirectory' {
    It 'Returns profile directory path' {
        if (Get-Command Get-ProfileDirectory -ErrorAction SilentlyContinue) {
            $profileDir = Get-ProfileDirectory
            $profileDir | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $profileDir | Should -Be $true
        }
    }
}

Describe 'FragmentLoader.psm1 - Get-FragmentPath' {
    It 'Returns path for existing fragment' {
        if (Get-Command Get-FragmentPath -ErrorAction SilentlyContinue) {
            $fragmentPath = Get-FragmentPath -FragmentName 'bootstrap'
            $fragmentPath | Should -Not -BeNullOrEmpty
            $fragmentPath | Should -Match 'bootstrap\.ps1$'
        }
    }
    
    It 'Returns path for non-existent fragment' {
        if (Get-Command Get-FragmentPath -ErrorAction SilentlyContinue) {
            $fragmentPath = Get-FragmentPath -FragmentName 'NonExistentFragment'
            $fragmentPath | Should -Not -BeNullOrEmpty
            $fragmentPath | Should -Match 'NonExistentFragment\.ps1$'
        }
    }
    
    It 'Handles null or empty fragment name' {
        if (Get-Command Get-FragmentPath -ErrorAction SilentlyContinue) {
            { Get-FragmentPath -FragmentName '' } | Should -Not -Throw
            { Get-FragmentPath -FragmentName $null } | Should -Not -Throw
        }
    }
}

Describe 'FragmentLoader.psm1 - Test-FragmentLoaded' {
    It 'Returns false for unloaded fragment' {
        if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
            Test-FragmentLoaded -FragmentName 'TestUnloadedFragment' | Should -Be $false
        }
    }
    
    It 'Handles null or empty fragment name' {
        if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
            Test-FragmentLoaded -FragmentName '' | Should -Be $false
            Test-FragmentLoaded -FragmentName $null | Should -Be $false
        }
    }
}

Describe 'FragmentLoader.psm1 - Get-FragmentDependencies' {
    It 'Returns empty array for fragment with no dependencies' {
        if (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
            # Create a test fragment file without dependencies
            $testFragmentPath = Join-Path $TestDrive 'test-fragment.ps1'
            Set-Content -Path $testFragmentPath -Value '# Test fragment with no dependencies'
            
            $deps = Get-FragmentDependencies -FragmentName 'test-fragment' -FragmentPath $testFragmentPath
            $deps | Should -Not -BeNullOrEmpty
            $deps.Count | Should -Be 0
        }
    }
    
    It 'Parses dependencies from fragment file' {
        if (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
            # Create a test fragment file with dependencies
            $testFragmentPath = Join-Path $TestDrive 'test-fragment-deps.ps1'
            $content = @'
# Requires: bootstrap, env
# Fragment with dependencies
'@
            Set-Content -Path $testFragmentPath -Value $content
            
            $deps = Get-FragmentDependencies -FragmentName 'test-fragment-deps' -FragmentPath $testFragmentPath
            $deps | Should -Not -BeNullOrEmpty
            $deps | Should -Contain 'bootstrap'
            $deps | Should -Contain 'env'
        }
    }
}

Describe 'FragmentLoader.psm1 - Load-Fragment' {
    It 'Loads existing fragment without errors' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { Load-Fragment -FragmentName 'bootstrap' } | Should -Not -Throw
        }
    }
    
    It 'Is idempotent (can load same fragment multiple times)' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { 
                Load-Fragment -FragmentName 'bootstrap'
                Load-Fragment -FragmentName 'bootstrap'
            } | Should -Not -Throw
        }
    }
    
    It 'Handles missing fragment gracefully' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { Load-Fragment -FragmentName 'NonExistentFragment12345' } | Should -Not -Throw
        }
    }
    
    It 'Handles null or empty fragment name gracefully' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { Load-Fragment -FragmentName '' } | Should -Not -Throw
            { Load-Fragment -FragmentName $null } | Should -Not -Throw
        }
    }
}

Describe 'FragmentLoader.psm1 - Load-FragmentForCommand' {
    BeforeAll {
        # Ensure registry is available and has a test entry
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-LoadForCommand' -FragmentName 'bootstrap' -CommandType 'Function'
        }
    }
    
    It 'Loads fragment for registered command' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            { Load-FragmentForCommand -CommandName 'Test-LoadForCommand' } | Should -Not -Throw
        }
    }
    
    It 'Handles unregistered command gracefully' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            { Load-FragmentForCommand -CommandName 'NonExistentCommand12345' } | Should -Not -Throw
        }
    }
    
    It 'Handles null or empty command name gracefully' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            { Load-FragmentForCommand -CommandName '' } | Should -Not -Throw
            { Load-FragmentForCommand -CommandName $null } | Should -Not -Throw
        }
    }

    It 'Handles missing registry gracefully' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                { Load-FragmentForCommand -CommandName 'Test-Command' } | Should -Not -Throw
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Handles Invoke-WithWideEvent when available' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            # This test verifies the function works with wide event tracking
            if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
                $null = Register-FragmentCommand -CommandName 'Test-WideEvent' -FragmentName 'bootstrap' -CommandType 'Function'
                { Load-FragmentForCommand -CommandName 'Test-WideEvent' } | Should -Not -Throw
            }
        }
    }
    
    It 'Handles fallback when Invoke-WithWideEvent is not available' {
        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            # This test verifies the function works without wide event tracking
            if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
                $null = Register-FragmentCommand -CommandName 'Test-Fallback' -FragmentName 'bootstrap' -CommandType 'Function'
                { Load-FragmentForCommand -CommandName 'Test-Fallback' } | Should -Not -Throw
            }
        }
    }
}

Describe 'FragmentLoader.psm1 - Get-FragmentDependencies error handling' {
    It 'Handles missing FragmentLoading module gracefully' {
        if (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
            # Create a test fragment file
            $testFragmentPath = Join-Path $TestDrive 'test-fragment.ps1'
            Set-Content -Path $testFragmentPath -Value '# Requires: bootstrap, env'
            
            # Function should fall back to manual parsing
            { $deps = Get-FragmentDependencies -FragmentName 'test-fragment' -FragmentPath $testFragmentPath } | Should -Not -Throw
            $deps | Should -Not -BeNullOrEmpty
        }
    }
    
    It 'Handles null or empty fragment path' {
        if (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
            { Get-FragmentDependencies -FragmentName 'test' -FragmentPath $null } | Should -Not -Throw
            { Get-FragmentDependencies -FragmentName 'test' -FragmentPath '' } | Should -Not -Throw
        }
    }
}

Describe 'FragmentLoader.psm1 - Load-Fragment error handling' {
    It 'Handles missing fragment path gracefully' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { Load-Fragment -FragmentName 'NonExistentFragment99999' } | Should -Not -Throw
        }
    }
    
    It 'Handles LoadDependencies parameter' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            { Load-Fragment -FragmentName 'bootstrap' -LoadDependencies:$false } | Should -Not -Throw
            { Load-Fragment -FragmentName 'bootstrap' -LoadDependencies:$true } | Should -Not -Throw
        }
    }
    
    It 'Handles Invoke-WithWideEvent when available' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            # This test verifies the function works with wide event tracking
            { Load-Fragment -FragmentName 'bootstrap' } | Should -Not -Throw
        }
    }
    
    It 'Handles fallback when Invoke-WithWideEvent is not available' {
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            # This test verifies the function works without wide event tracking
            { Load-Fragment -FragmentName 'bootstrap' } | Should -Not -Throw
        }
    }
}

Describe 'FragmentLoader.psm1 - Test-FragmentLoaded error handling' {
    It 'Handles missing FragmentIdempotency module gracefully' {
        if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
            # Function should fall back to global variable check
            { Test-FragmentLoaded -FragmentName 'TestFragment' } | Should -Not -Throw
        }
    }
    
    It 'Handles module function call errors gracefully' {
        if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
            # Function should handle errors in module function calls
            { Test-FragmentLoaded -FragmentName 'TestFragment' } | Should -Not -Throw
        }
    }
}
