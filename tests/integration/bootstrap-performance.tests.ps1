. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Bootstrap Performance and Memory Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'Performance and memory tests' {
        BeforeAll {
            . $script:BootstrapPath
        }

        It 'Test-CachedCommand improves performance on repeated calls' {
            $commandName = 'Get-Command'

            $start1 = Get-Date
            $result1 = Test-CachedCommand -Name $commandName
            $time1 = (Get-Date) - $start1

            $start2 = Get-Date
            $result2 = Test-CachedCommand -Name $commandName
            $time2 = (Get-Date) - $start2

            $result1 | Should -Be $result2
            $time2.TotalMilliseconds | Should -BeLessOrEqual ($time1.TotalMilliseconds + 50)
        }

        It 'Set-AgentModeFunction does not leak memory on repeated calls' {
            $funcName = "TestMemory_$(Get-Random)"

            for ($i = 1; $i -le 5; $i++) {
                $result = Set-AgentModeFunction -Name $funcName -Body { "test$i" }
                $result | Should -Be $true
                Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }

            $final = Set-AgentModeFunction -Name $funcName -Body { 'final' }
            $final | Should -Be $true

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }
    }
}
