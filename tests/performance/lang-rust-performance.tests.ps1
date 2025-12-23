# ===============================================
# lang-rust-performance.tests.ps1
# Performance tests for lang-rust.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:LangRustPath = Join-Path $script:ProfileDir 'lang-rust.ps1'
}

Describe 'lang-rust.ps1 Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Fragment loads in less than 500ms' {
            $loadTimes = @()
            for ($i = 0; $i -lt 5; $i++) {
                # Clear any cached functions
                Remove-Item Function:\Install-RustBinary -ErrorAction SilentlyContinue
                Remove-Item Function:\Watch-RustProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Audit-RustProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Test-RustOutdated -ErrorAction SilentlyContinue
                Remove-Item Function:\Build-RustRelease -ErrorAction SilentlyContinue
                Remove-Item Function:\Update-RustDependencies -ErrorAction SilentlyContinue
                
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:LangRustPath -ErrorAction SilentlyContinue
                $sw.Stop()
                $loadTimes += $sw.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan 500
        }
    }
    
    Context 'Load Time Consistency' {
        It 'Fragment load time is consistent across multiple loads' {
            $loadTimes = @()
            for ($i = 0; $i -lt 10; $i++) {
                # Clear any cached functions
                Remove-Item Function:\Install-RustBinary -ErrorAction SilentlyContinue
                Remove-Item Function:\Watch-RustProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Audit-RustProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Test-RustOutdated -ErrorAction SilentlyContinue
                Remove-Item Function:\Build-RustRelease -ErrorAction SilentlyContinue
                Remove-Item Function:\Update-RustDependencies -ErrorAction SilentlyContinue
                
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:LangRustPath -ErrorAction SilentlyContinue
                $sw.Stop()
                $loadTimes += $sw.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $maxLoadTime = ($loadTimes | Measure-Object -Maximum).Maximum
            $minLoadTime = ($loadTimes | Measure-Object -Minimum).Minimum
            $variance = $maxLoadTime - $minLoadTime
            
            # Variance should be less than 200ms (consistent performance)
            $variance | Should -BeLessThan 200
        }
    }
    
    Context 'Function Registration Performance' {
        It 'Function registration is fast' {
            . $script:LangRustPath -ErrorAction SilentlyContinue
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Out-Null
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Test-RustOutdated -ErrorAction SilentlyContinue | Out-Null
            Get-Command Build-RustRelease -ErrorAction SilentlyContinue | Out-Null
            Get-Command Update-RustDependencies -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Alias Resolution Performance' {
        It 'Alias resolution is fast' {
            . $script:LangRustPath -ErrorAction SilentlyContinue
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Alias cargo-binstall -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-watch -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-audit -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-outdated -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-build-release -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-update-deps -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency checks add minimal overhead' {
            . $script:LangRustPath -ErrorAction SilentlyContinue
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:LangRustPath -ErrorAction SilentlyContinue
            . $script:LangRustPath -ErrorAction SilentlyContinue
            . $script:LangRustPath -ErrorAction SilentlyContinue
            $sw.Stop()
            
            # Multiple loads should be fast due to idempotency
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
}

