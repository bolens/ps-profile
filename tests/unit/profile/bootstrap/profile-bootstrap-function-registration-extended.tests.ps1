# ===============================================
# profile-bootstrap-function-registration-extended.tests.ps1
# Execution tests for bootstrap/FunctionRegistration.ps1 behavior
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/FunctionRegistration.ps1 extended scenarios' {
    It 'Registers collision-safe function and alias helpers' {
        Get-Command Set-AgentModeFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-AgentModeAlias -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Register-LazyFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Set-AgentModeFunction does not overwrite existing function bodies' {
        $funcName = "BootstrapReg_$([Guid]::NewGuid().ToString('N'))"
                Set-AgentModeFunction -Name $funcName -Body { 'first-body' } | Should -Be $true
        Set-AgentModeFunction -Name $funcName -Body { 'second-body' } | Should -Be $false
        & $funcName | Should -Be 'first-body'
    }
    finally {
        Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
    }

    It 'Preserves registration helper bodies on repeated module loads' {
        $firstRegister = Get-Command Set-AgentModeFunction -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'FunctionRegistration.ps1')

        (Get-Command Set-AgentModeFunction -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRegister.ScriptBlock.ToString()
    }
}
