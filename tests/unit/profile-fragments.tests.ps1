#
# Core profile fragment smoke tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapPath = Join-Path $script:ProfileDir '00-bootstrap.ps1'
    . $script:BootstrapPath
}

Describe 'Profile fragments' {
    Context 'Fragment lifecycle' {
        It 'loads fragments twice without error (idempotency)' {
            $fragments = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File | Sort-Object Name | Select-Object -ExpandProperty FullName
            & { param($files, $root) $PSScriptRoot = $root; foreach ($fragment in $files) { . $fragment } } $fragments $PSScriptRoot
            & { param($files, $root) $PSScriptRoot = $root; foreach ($fragment in $files) { . $fragment } } $fragments $PSScriptRoot
            $true | Should -Be $true
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
        It 'base64 encode/decode roundtrip for small content' {
            $payload = 'hello world'
            $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload))
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
            $decoded | Should -Be 'hello world'
        }
    }
}
