Describe 'Alias helper' {
    It 'Set-AgentModeAlias returns definition when requested and alias works' {
        . "$PSScriptRoot/..\profile.d\00-bootstrap.ps1"
        $name = "test_alias_$(Get-Random)"
        $def = Set-AgentModeAlias -Name $name -Target 'Write-Output' -ReturnDefinition
    $def | Should Not Be $false
    $def.GetType().Name | Should Be 'String'
        # The alias should also be callable and emit the given argument
        $out = & $name 'hello'
        $out | Should Be 'hello'
    }
}
