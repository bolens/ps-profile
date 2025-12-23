# ===============================================
# lang-python-performance.tests.ps1
# Performance tests for lang-python.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:LangPythonPath = Join-Path $script:ProfileDir 'lang-python.ps1'
}

Describe 'lang-python.ps1 Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Fragment loads in less than 500ms' {
            $loadTimes = @()
            for ($i = 0; $i -lt 5; $i++) {
                # Clear any cached functions
                Remove-Item Function:\Install-PythonApp -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-Pipx -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-PythonScript -ErrorAction SilentlyContinue
                Remove-Item Function:\New-PythonVirtualEnv -ErrorAction SilentlyContinue
                Remove-Item Function:\New-PythonProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Install-PythonPackage -ErrorAction SilentlyContinue

                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:LangPythonPath -ErrorAction SilentlyContinue
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
                Remove-Item Function:\Install-PythonApp -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-Pipx -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-PythonScript -ErrorAction SilentlyContinue
                Remove-Item Function:\New-PythonVirtualEnv -ErrorAction SilentlyContinue
                Remove-Item Function:\New-PythonProject -ErrorAction SilentlyContinue
                Remove-Item Function:\Install-PythonPackage -ErrorAction SilentlyContinue

                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:LangPythonPath -ErrorAction SilentlyContinue
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
            . $script:LangPythonPath -ErrorAction SilentlyContinue

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Command Install-PythonApp -ErrorAction SilentlyContinue | Out-Null
            Get-Command Invoke-Pipx -ErrorAction SilentlyContinue | Out-Null
            Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue | Out-Null
            Get-Command New-PythonVirtualEnv -ErrorAction SilentlyContinue | Out-Null
            Get-Command New-PythonProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Install-PythonPackage -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }

    Context 'Alias Resolution Performance' {
        It 'Alias resolution is fast' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Alias pipx-install -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pipx -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pyvenv -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pyinstall -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency checks add minimal overhead' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            $sw.Stop()

            # Multiple loads should be fast due to idempotency
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
}

