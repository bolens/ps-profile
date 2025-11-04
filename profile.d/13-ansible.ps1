# ===============================================
# 13-ansible.ps1
# Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility
# ===============================================

# Ansible command wrappers for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Invoke-Ansible { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible $args" }
Set-Alias -Name ansible -Value Invoke-Ansible -ErrorAction SilentlyContinue

# Ansible-playbook command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible playbook commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-playbook commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Invoke-AnsiblePlaybook { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-playbook $args" }
Set-Alias -Name ansible-playbook -Value Invoke-AnsiblePlaybook -ErrorAction SilentlyContinue

# Ansible-galaxy command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Galaxy commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-galaxy commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Invoke-AnsibleGalaxy { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-galaxy $args" }
Set-Alias -Name ansible-galaxy -Value Invoke-AnsibleGalaxy -ErrorAction SilentlyContinue

# Ansible-vault command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Vault commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-vault commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Invoke-AnsibleVault { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-vault $args" }
Set-Alias -Name ansible-vault -Value Invoke-AnsibleVault -ErrorAction SilentlyContinue

# Ansible-doc command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible documentation commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-doc commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Get-AnsibleDoc { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-doc $args" }
Set-Alias -Name ansible-doc -Value Get-AnsibleDoc -ErrorAction SilentlyContinue

# Ansible-inventory command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible inventory commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-inventory commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function Get-AnsibleInventory { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-inventory $args" }
Set-Alias -Name ansible-inventory -Value Get-AnsibleInventory -ErrorAction SilentlyContinue
