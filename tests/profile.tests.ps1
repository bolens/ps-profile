Describe 'Profile fragments' {
    It 'loads fragments twice without error (idempotency)' {
        $fragDir = Join-Path $PSScriptRoot '..\profile.d'
        # Dot-source each fragment inside a scriptblock that defines $PSScriptRoot so fragments can rely on it.
        $files = Get-ChildItem -Path $fragDir -Filter *.ps1 -File | Sort-Object Name | Select-Object -ExpandProperty FullName
        # Dot-source all fragments in the same scope so helpers defined in bootstrap are visible
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        & { param($files, $root) $PSScriptRoot = $root; foreach ($f in $files) { . $f } } $files $PSScriptRoot
        # If no exception reached here, pass
        $true | Should Be $true
    }

    It 'Set-AgentModeFunction registers a function safely' {
        . "$PSScriptRoot/..\profile.d\00-bootstrap.ps1"
    $sb = Set-AgentModeFunction -Name 'test_agent_fn' -Body { return 'ok' } -ReturnScriptBlock
        # The helper returns the created ScriptBlock on success, or $false when it was a no-op.
    $sb | Should Not Be $false
        $sb.GetType().Name | Should Be 'ScriptBlock'
        $result = $null
        try { $result = (& test_agent_fn) } catch { }
        $result | Should Be 'ok'
        # Also test alias helper returns boolean
        $aliasName = "test_alias_$(Get-Random)"
        $aliasResult = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
    $aliasResult | Should Be $true
    # Invocation test: calling the created alias should invoke the target (Write-Output)
    $aliasOut = $null
    try { $aliasOut = & $aliasName 'ping' } catch { }
    $aliasOut | Should Be 'ping'
    }

    It 'base64 encode/decode roundtrip for small content' {
    $tmp = [IO.Path]::GetTempFileName()
    Set-Content -Path $tmp -Value 'hello world' -NoNewline
    # Use Get-Content -Encoding Byte for compatibility with older PowerShell
    $bytes = Get-Content -Path $tmp -Encoding Byte -ReadCount 0
    $b64 = [System.Convert]::ToBase64String([byte[]]$bytes)
    $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
    ($decoded -eq 'hello world') | Should Be $true
    Remove-Item $tmp -Force
    }
}
