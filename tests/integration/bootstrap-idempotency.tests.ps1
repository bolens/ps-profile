. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Bootstrap Idempotency Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'Idempotency tests' {
        It 'Set-AgentModeFunction is idempotent' {
            . $script:BootstrapPath
            $funcName = "TestIdempotent_$(Get-Random)"

            $result1 = Set-AgentModeFunction -Name $funcName -Body { 'test' }
            $result1 | Should -Be $true

            $result2 = Set-AgentModeFunction -Name $funcName -Body { 'test2' }
            $result2 | Should -Be $false

            $funcResult = & $funcName
            $funcResult | Should -Be 'test'

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias is idempotent' {
            . $script:BootstrapPath
            $aliasName = "TestAliasIdempotent_$(Get-Random)"

            $result1 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result1 | Should -Be $true

            $result2 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Host'
            $result2 | Should -Be $false

            $aliasResult = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
            if ($aliasResult) {
                $aliasResult.Definition | Should -Match 'Write-Output'
            }

            Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }
}
