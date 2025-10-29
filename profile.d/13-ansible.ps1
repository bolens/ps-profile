# ===============================================
# 13-ansible.ps1
# Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility
# ===============================================

# Ansible command wrappers for WSL with UTF-8 locale
function ansible { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible $args" }
# Ansible-playbook command wrapper for WSL with UTF-8 locale
function ansible-playbook { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-playbook $args" }
# Ansible-galaxy command wrapper for WSL with UTF-8 locale
function ansible-galaxy { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-galaxy $args" }
# Ansible-vault command wrapper for WSL with UTF-8 locale
function ansible-vault { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-vault $args" }
# Ansible-doc command wrapper for WSL with UTF-8 locale
function ansible-doc { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-doc $args" }
# Ansible-inventory command wrapper for WSL with UTF-8 locale
function ansible-inventory { wsl bash -lc "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && ansible-inventory $args" }












