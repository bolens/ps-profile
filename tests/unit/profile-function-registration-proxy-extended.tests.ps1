<#
tests/unit/profile-function-registration-proxy-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for fragment command proxy registration helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'FunctionRegistration.ps1')
}

Describe 'FunctionRegistration proxy extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:FuncName = "ProxyFunc_$script:Suffix"
        $script:AliasOne = "ProxyAliasOne_$script:Suffix"
        $script:AliasTwo = "ProxyAliasTwo_$script:Suffix"
    }

    AfterEach {
        Remove-Item -Path "Function:\$script:FuncName" -Force -ErrorAction SilentlyContinue
        Remove-Item Alias:\$script:AliasOne -Force -ErrorAction SilentlyContinue
        Remove-Item Alias:\$script:AliasTwo -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\Load-FragmentForCommand' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\Get-FragmentForCommand' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\BootstrapExistingProxyTarget' -Force -ErrorAction SilentlyContinue
    }

    Context 'Register-FragmentFunction' {
        It 'Registers a function and optional aliases in one call' {
            $null = Register-FragmentFunction `
                -Name $script:FuncName `
                -Body { 'proxy-body' } `
                -Aliases @($script:AliasOne, $script:AliasTwo)

            & $script:FuncName | Should -Be 'proxy-body'
            Get-Alias -Name $script:AliasOne -ErrorAction Stop | Select-Object -ExpandProperty Definition |
                Should -Be $script:FuncName
        }

        It 'Returns false when the function name is already registered' {
            Register-FragmentFunction -Name $script:FuncName -Body { 'first' } | Should -Be $true
            Register-FragmentFunction -Name $script:FuncName -Body { 'second' } | Should -Be $false
            & $script:FuncName | Should -Be 'first'
        }

        It 'Rejects a null body script block at parameter binding time' {
            { Register-FragmentFunction -Name $script:FuncName -Body $null } | Should -Throw
        }
    }

    Context 'New-FragmentCommandProxy' {
        BeforeEach {
            $script:ProxyCommandName = "ProxyCommand_$([Guid]::NewGuid().ToString('N'))"
            Remove-Item -Path "Function:\$script:ProxyCommandName" -Force -ErrorAction SilentlyContinue
        }

        AfterEach {
            Remove-Item -Path "Function:\$script:ProxyCommandName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\Load-FragmentForCommand' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\Get-FragmentForCommand' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\BootstrapExistingProxyTarget' -Force -ErrorAction SilentlyContinue
        }

        It 'Returns false when fragment loader helpers are unavailable' {
            New-FragmentCommandProxy -CommandName $script:ProxyCommandName | Should -Be $false
        }

        It 'Creates a proxy when fragment loader helpers are stubbed' {
            function global:Load-FragmentForCommand { return $true }
            function global:Get-FragmentForCommand { return 'proxy-fragment' }

            New-FragmentCommandProxy -CommandName $script:ProxyCommandName -FragmentName 'proxy-fragment' |
                Should -Be $true

            $proxy = Get-Command -Name $script:ProxyCommandName -CommandType Function
            $proxy.ScriptBlock.ToString() | Should -Match 'Load-FragmentForCommand'

            New-FragmentCommandProxy -CommandName $script:ProxyCommandName -FragmentName 'proxy-fragment' |
                Should -Be $true
        }

        It 'Returns false when a non-proxy function already exists' {
            function global:BootstrapExistingProxyTarget { 'existing' }

            function global:Load-FragmentForCommand { return $true }
            function global:Get-FragmentForCommand { return 'proxy-fragment' }

            New-FragmentCommandProxy -CommandName 'BootstrapExistingProxyTarget' -FragmentName 'proxy-fragment' |
                Should -Be $false
        }
    }
}
