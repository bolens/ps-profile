# ===============================================
# library-command-dispatcher-handler.tests.ps1
# Real command-not-found callback and module-scope regression coverage
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '../../..' 'TestSupport.ps1')
    $script:DispatcherPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/fragment/CommandDispatcher.psm1'
}

Describe 'Command dispatcher module-bound handler' {
    It 'Resolves commands and preserves fallback across nested imports and forced registration' {
        $dispatcherPath = $script:DispatcherPath.Replace("'", "''")
        $bridgePath = (Join-Path $TestDrive 'DispatcherBridge.psm1').Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
`$global:FragmentCommandRegistry = @{ CiDispatcherTarget = @{ Fragment = 'fixture' } }
`$env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '1'
`$global:CiRegistryQueries = 0
function global:Test-CommandInRegistry {
    param(`$CommandName)
    `$global:CiRegistryQueries++
    `$global:FragmentCommandRegistry.ContainsKey(`$CommandName)
}
function global:Load-FragmentForCommand {
    param(`$CommandName)
    if (`$CommandName -eq 'CiDispatcherTarget') {
        function global:CiDispatcherTarget { 'REGISTERED_COMMAND_OK' }
        return `$true
    }
    return `$false
}
function global:CiDispatcherFallback { 'PREVIOUS_HANDLER_OK' }
`$previous = {
    param(`$CommandName, `$EventArgs)
    if (`$CommandName -eq 'CiDispatcherMissing') {
        `$null = Get-Command CiDispatcherNestedMissing -ErrorAction SilentlyContinue
        `$EventArgs.CommandScriptBlock = { CiDispatcherFallback }
    }
}
`$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = `$previous
`$expectedPrevious = `$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
@'
Import-Module '$dispatcherPath' -DisableNameChecking
function Enable-CiDispatcher { param([switch]`$Force) Register-CommandDispatcher -Force:`$Force }
function Disable-CiDispatcher { Unregister-CommandDispatcher }
Export-ModuleMember -Function Enable-CiDispatcher, Disable-CiDispatcher
'@ | Set-Content '$bridgePath'
Import-Module '$bridgePath'
try {
    `$null = Enable-CiDispatcher
    `$null = Enable-CiDispatcher -Force
    CiDispatcherTarget
    CiDispatcherMissing
    if (`$global:CiRegistryQueries -eq 1) { 'UNKNOWN_COMMAND_FAST_PATH_OK' }
}
finally {
    `$null = Disable-CiDispatcher
}
if (`$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction -eq `$expectedPrevious) { 'HANDLER_RESTORED_OK' }
"@
        $result | Should -Match 'REGISTERED_COMMAND_OK'
        $result | Should -Match 'PREVIOUS_HANDLER_OK'
        $result | Should -Match 'HANDLER_RESTORED_OK'
        $result | Should -Match 'UNKNOWN_COMMAND_FAST_PATH_OK'
    }
}
