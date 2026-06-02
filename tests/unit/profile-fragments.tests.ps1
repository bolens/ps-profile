#
# Core profile fragment smoke tests.
#

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    . $script:BootstrapPath
}

Describe 'Profile fragments' {
    Context 'Fragment lifecycle' {
        It 'loads fragments twice without error (idempotency)' {
            $fragments = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File | Sort-Object Name | Select-Object -ExpandProperty FullName
            { & { param($files, $root) $PSScriptRoot = $root; foreach ($fragment in $files) { . $fragment } } $fragments $PSScriptRoot } | Should -Not -Throw
            { & { param($files, $root) $PSScriptRoot = $root; foreach ($fragment in $files) { . $fragment } } $fragments $PSScriptRoot } | Should -Not -Throw
        }
    }

    Context 'Agent helper registration' {
        It 'Set-AgentModeFunction registers a function safely' {
            . $script:BootstrapPath
            $scriptBlock = Set-AgentModeFunction -Name 'test_agent_fn' -Body { 'ok' } -ReturnScriptBlock
            $scriptBlock | Should -Not -Be $false
            $scriptBlock.GetType().Name | Should -Be 'ScriptBlock'

            $result = $null
            try {
                $result = (& test_agent_fn)
            }
            catch {
            }
            $result | Should -Be 'ok'

            $aliasName = "test_alias_{0}" -f (Get-Random)
            $aliasCreated = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $aliasCreated | Should -Be $true

            $aliasOutput = $null
            try {
                $aliasOutput = & $aliasName 'ping'
            }
            catch {
            }
            $aliasOutput | Should -Be 'ping'
        }
    }

    Context 'Utility helpers' {
        It 'Test-CachedCommand returns bool for known command' {
            . $script:BootstrapPath
            $result = Test-CachedCommand 'pwsh'
            $result | Should -BeOfType [bool]
        }
    }
}
