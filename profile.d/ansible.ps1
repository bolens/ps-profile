# ===============================================
# ansible.ps1
# Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Ansible helper functions and aliases for WSL execution.

.DESCRIPTION
    Provides PowerShell functions and aliases for Ansible commands that execute
    via WSL with UTF-8 locale settings for Linux toolchain compatibility.

.NOTES
    Module: PowerShell.Profile.Ansible
    Author: PowerShell Profile
#>

# Ansible command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible commands through WSL bash shell with proper UTF-8 locale
    settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible.

.EXAMPLE
    Invoke-Ansible --version

.EXAMPLE
    Invoke-Ansible all -m ping
#>
function Invoke-Ansible {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible $($Arguments -join ' ')"
}

# Ansible-playbook command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible playbook commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible-playbook commands through WSL bash shell with proper UTF-8
    locale settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible-playbook.

.EXAMPLE
    Invoke-AnsiblePlaybook playbook.yml

.EXAMPLE
    Invoke-AnsiblePlaybook playbook.yml --check
#>
function Invoke-AnsiblePlaybook {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-playbook $($Arguments -join ' ')"
}

# Ansible-galaxy command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Galaxy commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible-galaxy commands through WSL bash shell with proper UTF-8
    locale settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible-galaxy.

.EXAMPLE
    Invoke-AnsibleGalaxy install geerlingguy.docker

.EXAMPLE
    Invoke-AnsibleGalaxy list
#>
function Invoke-AnsibleGalaxy {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-galaxy $($Arguments -join ' ')"
}

# Ansible-vault command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Vault commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible-vault commands through WSL bash shell with proper UTF-8
    locale settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible-vault.

.EXAMPLE
    Invoke-AnsibleVault encrypt secrets.yml

.EXAMPLE
    Invoke-AnsibleVault decrypt secrets.yml
#>
function Invoke-AnsibleVault {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-vault $($Arguments -join ' ')"
}

# Ansible-doc command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible documentation commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible-doc commands through WSL bash shell with proper UTF-8
    locale settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible-doc.

.EXAMPLE
    Get-AnsibleDoc ping

.EXAMPLE
    Get-AnsibleDoc -l
#>
function Get-AnsibleDoc {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-doc $($Arguments -join ' ')"
}

# Ansible-inventory command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible inventory commands via WSL with UTF-8 locale.

.DESCRIPTION
    Executes ansible-inventory commands through WSL bash shell with proper UTF-8
    locale settings for Linux toolchain compatibility.

.PARAMETER Arguments
    Arguments to pass to ansible-inventory.

.EXAMPLE
    Get-AnsibleInventory --list

.EXAMPLE
    Get-AnsibleInventory --host webserver
#>
function Get-AnsibleInventory {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-inventory $($Arguments -join ' ')"
}

# Create aliases for ansible commands
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ansible' -Target 'Invoke-Ansible'
    Set-AgentModeAlias -Name 'ansible-playbook' -Target 'Invoke-AnsiblePlaybook'
    Set-AgentModeAlias -Name 'ansible-galaxy' -Target 'Invoke-AnsibleGalaxy'
    Set-AgentModeAlias -Name 'ansible-vault' -Target 'Invoke-AnsibleVault'
    Set-AgentModeAlias -Name 'ansible-doc' -Target 'Get-AnsibleDoc'
    Set-AgentModeAlias -Name 'ansible-inventory' -Target 'Get-AnsibleInventory'
}
else {
    Set-Alias -Name 'ansible' -Value 'Invoke-Ansible' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ansible-playbook' -Value 'Invoke-AnsiblePlaybook' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ansible-galaxy' -Value 'Invoke-AnsibleGalaxy' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ansible-vault' -Value 'Invoke-AnsibleVault' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ansible-doc' -Value 'Get-AnsibleDoc' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ansible-inventory' -Value 'Get-AnsibleInventory' -ErrorAction SilentlyContinue
}
