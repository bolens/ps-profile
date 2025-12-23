# ===============================================
# debug-test-cached-command-mock.tests.ps1
# Debug test to understand why Test-CachedCommand mock isn't working
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    # Get the profile directory relative to the repo root
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ProfileDir = Join-Path $repoRoot 'profile.d'
    if (-not (Test-Path $script:ProfileDir)) {
        throw "Profile directory not found: $script:ProfileDir"
    }
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'Debug Test-CachedCommand Mock' {
    BeforeEach {
        # Clear everything
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('gitleaks', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('GITLEAKS', [ref]$null)
        }
        
        Remove-Item -Path "Function:\gitleaks" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:gitleaks" -Force -ErrorAction SilentlyContinue
    }
    
    It 'Should verify Test-CachedCommand function details' {
        $func = Get-Command Test-CachedCommand -ErrorAction SilentlyContinue
        $func | Should -Not -BeNullOrEmpty
        
        Write-Host "Test-CachedCommand CommandType: $($func.CommandType)" -ForegroundColor Cyan
        Write-Host "Test-CachedCommand ModuleName: $($func.ModuleName)" -ForegroundColor Cyan
        Write-Host "Test-CachedCommand Source: $($func.Source)" -ForegroundColor Cyan
        Write-Host "Test-CachedCommand Scope: $($func.Scope)" -ForegroundColor Cyan
        Write-Host "Test-CachedCommand Definition: $($func.Definition.Substring(0, [Math]::Min(100, $func.Definition.Length)))..." -ForegroundColor Cyan
    }
    
    It 'Should verify mock setup with Mock-CommandAvailabilityPester' {
        Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
        
        # In Pester 5, we can check if mocks were invoked using Should -Invoke
        # But we can't easily inspect mock setup. Let's just test if it works.
        $result = Test-CachedCommand 'gitleaks'
        Write-Host "Test-CachedCommand('gitleaks') returned: $result" -ForegroundColor Cyan
        
        # The result should be false if the mock is working
        if ($result -ne $false) {
            Write-Warning "Mock may not be working - returned $result instead of false"
        }
    }
    
    It 'Should test direct Mock call without parameter filter' {
        # Try mocking without parameter filter - this should intercept ALL calls
        Mock -CommandName Test-CachedCommand -MockWith {
            param([string]$Name)
            Write-Host "Mock intercepted call with Name: '$Name'" -ForegroundColor Green
            if ($Name -eq 'gitleaks') {
                return $false
            }
            # For other commands, we need to call the real function
            # But we can't easily do that, so return false for now
            return $false
        }
        
        $result = Test-CachedCommand 'gitleaks'
        Write-Host "Result from Test-CachedCommand('gitleaks'): $result" -ForegroundColor Cyan
        
        # Verify the mock was invoked
        Should -Invoke Test-CachedCommand -Times 1
        $result | Should -Be $false
    }
    
    It 'Should test Mock with parameter filter' {
        # Clear cache first to ensure fresh state
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        # Try mocking with parameter filter
        # The issue might be that the parameter filter isn't matching
        Mock -CommandName Test-CachedCommand -ParameterFilter {
            param([string]$Name)
            Write-Host "Parameter filter checking Name: '$Name'" -ForegroundColor Yellow
            $matches = $Name -eq 'gitleaks'
            Write-Host "Parameter filter match result: $matches" -ForegroundColor Yellow
            return $matches
        } -MockWith {
            Write-Host "Mock with parameter filter intercepted!" -ForegroundColor Green
            return $false
        }
        
        $result = Test-CachedCommand 'gitleaks'
        Write-Host "Result from Test-CachedCommand('gitleaks'): $result" -ForegroundColor Cyan
        
        # Check if mock was invoked - this will tell us if the parameter filter matched
        try {
            Should -Invoke Test-CachedCommand -Times 1 -ParameterFilter { $Name -eq 'gitleaks' }
            Write-Host "Mock was invoked (parameter filter matched)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Mock was NOT invoked - parameter filter may not have matched: $($_.Exception.Message)"
        }
        
        # The result should be false if the mock worked
        if ($result -ne $false) {
            Write-Warning "Mock didn't work - returned $result instead of false"
        }
    }
    
    It 'Should test Mock-CommandAvailabilityPester and verify behavior' {
        # Clear cache FIRST before setting up mock
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        # Remove from cache directly
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gitleaks', [ref]$null)
        }
        
        Mock-CommandAvailabilityPester -CommandName 'gitleaks' -Available $false
        
        # Check what Test-CachedCommand actually returns
        $result1 = Test-CachedCommand 'gitleaks'
        $result2 = Test-CachedCommand -Name 'gitleaks'
        
        Write-Host "Test-CachedCommand('gitleaks') returned: $result1" -ForegroundColor Cyan
        Write-Host "Test-CachedCommand -Name 'gitleaks' returned: $result2" -ForegroundColor Cyan
        
        # Check if function exists
        $funcExists1 = Test-Path "Function:\gitleaks"
        $funcExists2 = Test-Path "Function:\global:gitleaks"
        Write-Host "Function exists in Function:\gitleaks: $funcExists1" -ForegroundColor Cyan
        Write-Host "Function exists in Function:\global:gitleaks: $funcExists2" -ForegroundColor Cyan
        
        # Check cache AFTER the call
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $cacheKey = 'gitleaks'
            $inCache = $global:TestCachedCommandCache.ContainsKey($cacheKey)
            Write-Host "Command in cache AFTER call: $inCache" -ForegroundColor Cyan
            if ($inCache) {
                $cacheEntry = $global:TestCachedCommandCache[$cacheKey]
                Write-Host "Cache entry: $($cacheEntry | ConvertTo-Json -Compress)" -ForegroundColor Cyan
            }
        }
        
        # Check AssumedAvailableCommands
        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $inAssumed = $global:AssumedAvailableCommands.ContainsKey('gitleaks')
            Write-Host "Command in AssumedAvailableCommands: $inAssumed" -ForegroundColor Cyan
        }
        
        # Check Get-Command result (this should be mocked to return null)
        $getCommandResult = Get-Command 'gitleaks' -ErrorAction SilentlyContinue
        Write-Host "Get-Command('gitleaks') returned: $(if ($getCommandResult) { $getCommandResult.Name } else { 'null' })" -ForegroundColor Cyan
        
        # The key finding: if result is true, the mock didn't work
        if ($result1 -eq $true -or $result2 -eq $true) {
            Write-Warning "Mock-CommandAvailabilityPester did NOT work - Test-CachedCommand returned true"
            Write-Warning "This suggests the mock parameter filter isn't matching or the cache has a stale entry"
        }
    }
    
    It 'Should test if global function mocking works differently' {
        # Try creating a test global function and mocking it
        function global:Test-DebugFunction {
            param([string]$Name)
            return "Real function: $Name"
        }
        
        Mock -CommandName Test-DebugFunction -MockWith {
            param([string]$Name)
            return "Mocked function: $Name"
        }
        
        $result = Test-DebugFunction 'test'
        Write-Host "Test-DebugFunction('test') returned: $result" -ForegroundColor Cyan
        
        # Cleanup
        Remove-Item -Path "Function:\Test-DebugFunction" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:Test-DebugFunction" -Force -ErrorAction SilentlyContinue
        
        $result | Should -Match "Mocked"
    }
}

