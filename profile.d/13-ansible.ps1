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
function ansible { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible $args" }

# Ansible-playbook command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible playbook commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-playbook commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function ansible-playbook { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-playbook $args" }

# Ansible-galaxy command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Galaxy commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-galaxy commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function ansible-galaxy { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-galaxy $args" }

# Ansible-vault command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible Vault commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-vault commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function ansible-vault { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-vault $args" }

# Ansible-doc command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible documentation commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-doc commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function ansible-doc { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-doc $args" }

# Ansible-inventory command wrapper for WSL with UTF-8 locale
<#
.SYNOPSIS
    Runs Ansible inventory commands via WSL with UTF-8 locale.
.DESCRIPTION
    Executes ansible-inventory commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.
#>
function ansible-inventory { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-inventory $args" }

























