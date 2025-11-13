. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Bootstrap Function Scoping and Visibility' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'Function scoping and visibility' {
        It 'Set-AgentModeFunction creates global functions' {
            $funcName = "TestGlobal_$(Get-Random)"
            $result = Set-AgentModeFunction -Name $funcName -Body { 'global' }
            $result | Should -Be $true

            Get-Command $funcName -ErrorAction Stop | Should -Not -Be $null

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias creates global aliases' {
            $aliasName = "TestGlobalAlias_$(Get-Random)"
            $result = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result | Should -Be $true

            Get-Alias $aliasName -ErrorAction Stop | Should -Not -Be $null

            Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }
}