# ===============================================
# database-clients-performance.tests.ps1
# Performance tests for database-clients.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:DatabaseClientsPath = Join-Path $script:ProfileDir 'database-clients.ps1'
    
    # Performance thresholds (in milliseconds)
    $script:MaxLoadTimeMs = 500
    $script:MaxFunctionRegistrationTimeMs = 100
    $script:MaxAliasResolutionTimeMs = 10
}

Describe 'database-clients.ps1 - Performance Tests' {
    BeforeEach {
        # Remove functions and aliases to test fresh loading
        Remove-Item -Path "Function:\Start-MongoDbCompass" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-SqlWorkbench" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-DBeaver" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-TablePlus" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Invoke-Hasura" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Invoke-Supabase" -Force -ErrorAction SilentlyContinue
        
        Remove-Item -Path "Alias:\mongodb-compass" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\sql-workbench" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\dbeaver" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\tableplus" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\hasura" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\supabase" -Force -ErrorAction SilentlyContinue
    }
    
    It 'Fragment loads within acceptable time' {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        $loadTimeMs = $stopwatch.Elapsed.TotalMilliseconds
        
        # Allow up to 1000ms for initial load (includes module imports)
        $loadTimeMs | Should -BeLessThan 1000
    }
    
    It 'Load time is consistent across multiple loads' {
        $times = @()
        for ($i = 0; $i -lt 3; $i++) {
            Remove-Item -Path "Function:\Start-MongoDbCompass" -Force -ErrorAction SilentlyContinue
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $times += $stopwatch.Elapsed.TotalMilliseconds
            Start-Sleep -Milliseconds 50
        }
        
        $avgTime = ($times | Measure-Object -Average).Average
        $maxTime = ($times | Measure-Object -Maximum).Maximum
        $minTime = ($times | Measure-Object -Minimum).Minimum
        
        # Variance should be reasonable (max should be less than 3x min)
        ($maxTime / $minTime) | Should -BeLessThan 3
    }
    
    It 'Function registration is fast' {
        . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $function = Get-Command Start-MongoDbCompass -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        $registrationTimeMs = $stopwatch.Elapsed.TotalMilliseconds
        
        $function | Should -Not -BeNullOrEmpty
        $registrationTimeMs | Should -BeLessThan $script:MaxFunctionRegistrationTimeMs
    }
    
    It 'Alias resolution is fast' {
        # Ensure the fragment is loaded so aliases exist
        . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
        # Ensure alias exists
        if (-not (Get-Alias mongodb-compass -ErrorAction SilentlyContinue)) {
            if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Start-MongoDbCompass' | Out-Null
            }
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $alias = Get-Alias mongodb-compass -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        $aliasResolutionTimeMs = $stopwatch.Elapsed.TotalMilliseconds
        
        $alias | Should -Not -BeNullOrEmpty
        $aliasResolutionTimeMs | Should -BeLessThan $script:MaxAliasResolutionTimeMs
    }
    
    It 'Repeated fragment loads are fast (idempotency check overhead)' {
        . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        $secondLoadTimeMs = $stopwatch.Elapsed.TotalMilliseconds
        
        # Second load should be very fast due to idempotency check
        $secondLoadTimeMs | Should -BeLessThan 500
    }
}

