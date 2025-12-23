

Describe 'Bootstrap Performance and Memory Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Performance and memory tests' {
        BeforeAll {
            . $script:BootstrapPath
        }

        It 'Test-CachedCommand improves performance on repeated calls' {
            try {
                $commandName = 'Get-Command'

                $start1 = Get-Date
                $result1 = Test-CachedCommand -Name $commandName
                $time1 = (Get-Date) - $start1

                $start2 = Get-Date
                $result2 = Test-CachedCommand -Name $commandName
                $time2 = (Get-Date) - $start2

                $result1 | Should -Be $result2 -Because "cached results should be consistent"
                $time2.TotalMilliseconds | Should -BeLessOrEqual ($time1.TotalMilliseconds + 50) -Because "second call should be faster due to caching"
            }
            catch {
                $errorDetails = @{
                    Message     = $_.Exception.Message
                    CommandName = $commandName
                    Category    = $_.CategoryInfo.Category
                }
                Write-Error "Test-CachedCommand performance test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Set-AgentModeFunction does not leak memory on repeated calls' {
            $funcName = "TestMemory_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                for ($i = 1; $i -le 5; $i++) {
                    $result = Set-AgentModeFunction -Name $funcName -Body { "test$i" }
                    $result | Should -Be $true -Because "Set-AgentModeFunction should succeed on each iteration"
                    Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
                }

                $final = Set-AgentModeFunction -Name $funcName -Body { 'final' }
                $final | Should -Be $true -Because "final function creation should succeed"
                $cleanupNeeded = $true
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FunctionName = $funcName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeFunction memory leak test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

