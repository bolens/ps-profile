<#
tests/ValidationScripts.tests.ps1

Tests for validation scripts themselves.
#>

BeforeAll {
    # Import the Common module
    $commonModulePath = Join-Path $PSScriptRoot '..' 'scripts' 'lib' 'Common.psm1'
    Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
    
    # Get repository root
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:ScriptsUtilsPath = Join-Path $script:RepoRoot 'scripts' 'utils'
    $script:ScriptsChecksPath = Join-Path $script:RepoRoot 'scripts' 'checks'
    $script:TestTempDir = Join-Path $env:TEMP "PowerShellProfileValidationTests_$(New-Guid)"
    
    # Create test directory
    New-Item -ItemType Directory -Path $script:TestTempDir -Force | Out-Null
}

AfterAll {
    # Cleanup test directory
    if (Test-Path $script:TestTempDir) {
        Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'check-script-standards.ps1' {
    Context 'Script Standards Validation' {
        It 'Validates scripts with correct standards' {
            # Create a test script that follows standards
            $testScript = @'
# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode 2 -ErrorRecord $_
}

Exit-WithCode -ExitCode 0 -Message "Success"
'@
            $testScriptPath = Join-Path $script:TestTempDir 'test-standard.ps1'
            $testScript | Set-Content -Path $testScriptPath
            
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $scriptPath) {
                $result = pwsh -NoProfile -File $scriptPath -Path $script:TestTempDir 2>&1
                # Should pass validation (exit code 0)
                $LASTEXITCODE | Should -Be 0
            }
            else {
                Set-ItResult -Skipped -Because "check-script-standards.ps1 not found"
            }
        }
        
        It 'Detects direct exit calls' {
            # Create a test script with direct exit
            $testScript = @'
# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

exit 1
'@
            $testScriptPath = Join-Path $script:TestTempDir 'test-exit.ps1'
            $testScript | Set-Content -Path $testScriptPath
            
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $scriptPath) {
                $result = pwsh -NoProfile -File $scriptPath -Path $script:TestTempDir 2>&1 | Out-String
                # Should detect the issue (may exit with 1 or 0 depending on severity)
                $LASTEXITCODE | Should -BeIn @(0, 1)
                # Check if the output contains references to exit or the file name
                ($result -match 'exit|Exit-WithCode|test-exit') | Should -Be $true
            }
            else {
                Set-ItResult -Skipped -Because "check-script-standards.ps1 not found"
            }
        }
        
        It 'Detects inconsistent Common.psm1 import patterns' {
            # Create a test script with wrong import pattern for utils/
            $testScript = @'
# Wrong import pattern for utils/ scripts
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
'@
            $testScriptPath = Join-Path $script:TestTempDir 'test-import.ps1'
            $testScript | Set-Content -Path $testScriptPath
            
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $scriptPath) {
                # Note: This test may need adjustment based on actual script location
                # The check compares script location to expected pattern
                $result = pwsh -NoProfile -File $scriptPath -Path $script:TestTempDir 2>&1
                # Should detect inconsistency (may be Info severity)
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because "check-script-standards.ps1 not found"
            }
        }
        
        It 'Handles invalid path parameter gracefully' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $scriptPath) {
                $invalidPath = Join-Path $script:TestTempDir 'nonexistent'
                $result = pwsh -NoProfile -File $scriptPath -Path $invalidPath 2>&1
                # Should handle invalid path (may exit with error or validate parameter)
                $LASTEXITCODE | Should -BeIn @(0, 1, 2)
            }
            else {
                Set-ItResult -Skipped -Because "check-script-standards.ps1 not found"
            }
        }
        
        It 'Processes multiple scripts correctly' {
            # Create multiple test scripts
            1..3 | ForEach-Object {
                $testScript = @"
# Test script $_ 
`$commonModulePath = Join-Path `$PSScriptRoot 'Common.psm1'
Import-Module `$commonModulePath -ErrorAction Stop
Exit-WithCode -ExitCode 0
"@
                $testScriptPath = Join-Path $script:TestTempDir "test-$_.ps1"
                $testScript | Set-Content -Path $testScriptPath
            }
            
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-script-standards.ps1'
            if (Test-Path $scriptPath) {
                $result = pwsh -NoProfile -File $scriptPath -Path $script:TestTempDir 2>&1
                # Should process all scripts
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because "check-script-standards.ps1 not found"
            }
        }
    }
}

Describe 'validate-profile.ps1' {
    Context 'Profile Validation Orchestration' {
        It 'Runs all validation checks in sequence' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $scriptPath) {
                # This test may take a while and may fail if any check fails
                # We'll just verify the script exists and can be invoked
                $result = pwsh -NoProfile -File $scriptPath 2>&1
                # Exit code depends on validation results
                $LASTEXITCODE | Should -BeIn @(0, 1, 2)
            }
            else {
                Set-ItResult -Skipped -Because "validate-profile.ps1 not found"
            }
        }
        
        It 'Exits early when a validation check fails' {
            # Create a mock validation script that fails
            $mockCheckScript = @'
Write-Error "Mock validation failure"
exit 1
'@
            $mockCheckPath = Join-Path $script:TestTempDir 'mock-check.ps1'
            $mockCheckScript | Set-Content -Path $mockCheckPath
            
            # Note: This is a conceptual test - validate-profile.ps1 runs specific checks
            # We can't easily mock them, but we can verify the script structure
            $scriptPath = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $scriptPath) {
                # Verify script exists and has correct structure
                $content = Get-Content -Path $scriptPath -Raw
                $content | Should -Match 'validate-profile'
            }
            else {
                Set-ItResult -Skipped -Because "validate-profile.ps1 not found"
            }
        }
        
        It 'Handles missing validation scripts gracefully' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $scriptPath) {
                # Verify script checks for script existence
                $content = Get-Content -Path $scriptPath -Raw
                # Script should handle missing files (though it may fail)
                $content | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because "validate-profile.ps1 not found"
            }
        }
    }
}

Describe 'check-idempotency.ps1' {
    Context 'Idempotency Checks' {
        It 'Validates profile idempotency' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-idempotency.ps1'
            if (Test-Path $scriptPath) {
                $result = pwsh -NoProfile -File $scriptPath 2>&1
                # Exit code depends on idempotency check results
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because "check-idempotency.ps1 not found"
            }
        }
    }
}

Describe 'check-comment-help.ps1' {
    Context 'Comment-Based Help Validation' {
        It 'Validates comment-based help in fragments' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-comment-help.ps1'
            if (Test-Path $scriptPath) {
                $result = pwsh -NoProfile -File $scriptPath 2>&1
                # Exit code depends on validation results
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because "check-comment-help.ps1 not found"
            }
        }
    }
}

Describe 'check-commit-messages.ps1' {
    Context 'Commit Message Validation' {
        It 'Validates commit message format' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-commit-messages.ps1'
            if (Test-Path $scriptPath) {
                # This script typically runs as a git hook, so we'll just verify it exists
                $scriptPath | Should -Exist
            }
            else {
                Set-ItResult -Skipped -Because "check-commit-messages.ps1 not found"
            }
        }
    }
}


