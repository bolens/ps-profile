# ===============================================
# ansible.ps1
# Ansible wrappers — runs natively on Linux/macOS, via WSL on Windows
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Ansible helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for Ansible commands.
    On Linux/macOS ansible is invoked directly. On Windows it is run
    through WSL with UTF-8 locale settings.

.NOTES
    Module: PowerShell.Profile.Ansible
    Author: PowerShell Profile
.EXAMPLE
    Invoke-Ansible -Arguments @('all', '-m', 'ping')

#>

# Determine invocation strategy once at load time
$script:_ansibleIsLinux = $IsLinux -or $IsMacOS
$script:_ansibleHasWsl  = -not $script:_ansibleIsLinux -and (Test-CachedCommand 'wsl')

# On Windows without WSL there is nothing to register — show install hint and bail out
if (-not $script:_ansibleIsLinux -and -not $script:_ansibleHasWsl) {
    if (Get-Command Invoke-MissingToolWarning -ErrorAction SilentlyContinue) {
        Invoke-MissingToolWarning -ToolName 'ansible' -Tool 'ansible (requires WSL on Windows)'
    }
    return
}

# Private helper: invoke an ansible binary with the right strategy
<#
.SYNOPSIS
    Invokes an Ansible binary with the correct platform strategy.

.DESCRIPTION
    Invokes an Ansible binary with the correct platform strategy.

.PARAMETER Bin
    Ansible executable name (for example ansible or ansible-playbook).

.PARAMETER Arguments
    Arguments to pass to the binary.

.EXAMPLE
    script:Invoke-AnsibleBin -Bin 'ansible' -Arguments @('all', '-m', 'ping')
#>
function script:Invoke-AnsibleBin {
    param([string]$Bin, [string[]]$Arguments)
    if ($script:_ansibleIsLinux) {
        & $Bin @Arguments
    }
    else {
        $cmd = "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && $Bin $($Arguments -join ' ')"
        wsl bash -lc $cmd
    }
}

<#
.SYNOPSIS
        Runs ansible with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible.
#>
function Invoke-Ansible {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible' $Arguments
}

<#
.SYNOPSIS
        Runs ansible-playbook with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible-playbook with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible-playbook.
#>
function Invoke-AnsiblePlaybook {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible-playbook' $Arguments
}

<#
.SYNOPSIS
        Runs ansible-galaxy with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible-galaxy with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible-galaxy.
#>
function Invoke-AnsibleGalaxy {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible-galaxy' $Arguments
}

<#
.SYNOPSIS
        Runs ansible-vault with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible-vault with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible-vault.
#>
function Invoke-AnsibleVault {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible-vault' $Arguments
}

<#
.SYNOPSIS
        Runs ansible-doc with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible-doc with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible-doc.
#>
function Get-AnsibleDoc {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible-doc' $Arguments
}

<#
.SYNOPSIS
        Runs ansible-inventory with the correct invocation strategy for the current platform.

.DESCRIPTION
        Runs ansible-inventory with the correct invocation strategy for the current platform.

.PARAMETER Arguments
        Arguments to pass to ansible-inventory.
#>
function Get-AnsibleInventory {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    script:Invoke-AnsibleBin 'ansible-inventory' $Arguments
}

# Register functions globally (required for nested/test scopes and command registry)
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Invoke-Ansible' -Body ${function:Invoke-Ansible}
    Set-AgentModeFunction -Name 'Invoke-AnsiblePlaybook' -Body ${function:Invoke-AnsiblePlaybook}
    Set-AgentModeFunction -Name 'Invoke-AnsibleGalaxy' -Body ${function:Invoke-AnsibleGalaxy}
    Set-AgentModeFunction -Name 'Invoke-AnsibleVault' -Body ${function:Invoke-AnsibleVault}
    Set-AgentModeFunction -Name 'Get-AnsibleDoc' -Body ${function:Get-AnsibleDoc}
    Set-AgentModeFunction -Name 'Get-AnsibleInventory' -Body ${function:Get-AnsibleInventory}
}

# Aliases
Set-AgentModeAlias -Name 'ansible'           -Target 'Invoke-Ansible'
Set-AgentModeAlias -Name 'ansible-playbook'  -Target 'Invoke-AnsiblePlaybook'
Set-AgentModeAlias -Name 'ansible-galaxy'    -Target 'Invoke-AnsibleGalaxy'
Set-AgentModeAlias -Name 'ansible-vault'     -Target 'Invoke-AnsibleVault'
Set-AgentModeAlias -Name 'ansible-doc'       -Target 'Get-AnsibleDoc'
Set-AgentModeAlias -Name 'ansible-inventory' -Target 'Get-AnsibleInventory'
