. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Shortcuts Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot
        # Ensure test mode is set for mocks
        $env:PS_PROFILE_TEST_MODE = '1'
    }
    
    AfterAll {
        # Clean up any files that might have been created in project root
        if (Get-Command Remove-TestArtifacts -ErrorAction SilentlyContinue) {
            Remove-TestArtifacts
        }
        else {
            # Fallback cleanup
            $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $filesToClean = @('0', '2', '5', 'nonexistent.csv', 'nonexistent.yaml', 'nonexistent.txt')
            foreach ($file in $filesToClean) {
                $filePath = Join-Path $repoRoot $file
                if (Test-Path $filePath) {
                    Remove-Item $filePath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Shortcuts functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            
            # CRITICAL: Set up mocks BEFORE loading shortcuts fragment
            # This ensures the fragment sees Open-Editor already exists and doesn't define its own
            Initialize-TestMocks
            
            # Load the fragment - it should see our mocks exist and skip defining its own functions
            . (Join-Path $script:ProfileDir '15-shortcuts.ps1')
            
            # CRITICAL: Re-apply mocks AFTER fragment loads to ensure they override
            # The fragment may have defined Get-AvailableEditor (no guard), so we must override it
            Initialize-TestMocks
            
            # Force override Open-Editor one more time to be absolutely sure
            # The fragment checks if it exists, so if our mock was there first, it won't define its own
            # But we override again just to be safe
            if (Test-Path Function:\Open-Editor) {
                Remove-Item Function:\Open-Editor -Force -ErrorAction SilentlyContinue
            }
            Set-Item -Path Function:\Open-Editor -Value {
                param($p)
                if (-not $p) { 
                    Write-Warning 'Usage: Open-Editor <path>'
                    return 
                }
                Write-Verbose "Mock: Would open in editor: $p (editor execution prevented in test mode)"
            } -Force -ErrorAction SilentlyContinue
            
            # Also ensure Get-AvailableEditor returns null
            if (Test-Path Function:\Get-AvailableEditor) {
                Remove-Item Function:\Get-AvailableEditor -Force -ErrorAction SilentlyContinue
            }
            Set-Item -Path Function:\Get-AvailableEditor -Value { return $null } -Force -ErrorAction SilentlyContinue
        }

        It 'Get-AvailableEditor function exists' {
            Get-Command Get-AvailableEditor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-AvailableEditor can be called without error' {
            # Get-AvailableEditor may return an editor or null depending on what's installed
            # The important thing is that Open-Editor is mocked to prevent actual editor opening
            { $editor = Get-AvailableEditor } | Should -Not -Throw
            # If an editor is found, that's fine - Open-Editor mock will prevent it from opening
        }

        It 'Open-VSCode function exists' {
            Get-Command Open-VSCode -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Open-VSCode can be called without error' {
            # Should not throw regardless of editor availability
            { Open-VSCode } | Should -Not -Throw
        }

        It 'vsc alias exists' {
            Get-Alias vsc -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Open-Editor function exists' {
            Get-Command Open-Editor -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Open-Editor warns when no path provided' {
            # Should not throw when called without parameters
            { Open-Editor } | Should -Not -Throw
        }

        It 'Open-Editor can be called with nonexistent file' {
            # Should not throw even with invalid path
            # Use a path in TestDrive to avoid creating files in project root
            $testFile = Join-Path $TestDrive 'nonexistent-file.txt'
            
            # Verify the mock is active - Open-Editor should not actually launch an editor
            # Capture verbose output to verify mock is working
            $verbosePreference = $VerbosePreference
            $VerbosePreference = 'Continue'
            $output = Open-Editor $testFile 4>&1
            $VerbosePreference = $verbosePreference
            
            # Should not throw
            { Open-Editor $testFile } | Should -Not -Throw
            
            # Verify mock message appears (indicates mock is active, not real function)
            $output | Where-Object { $_ -like '*Mock: Would open in editor*' } | Should -Not -BeNullOrEmpty -Because "Mock should be active and prevent editor execution"
        }

        It 'e alias exists' {
            Get-Alias e -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ProjectRoot function exists' {
            Get-Command Get-ProjectRoot -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-ProjectRoot can be called without error' {
            # Should not throw regardless of git availability
            { Get-ProjectRoot } | Should -Not -Throw
        }

        It 'project-root alias exists' {
            Get-Alias project-root -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }
}
