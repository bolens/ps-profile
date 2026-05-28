# ===============================================
# ssh.ps1
# SSH agent and key helpers
# ===============================================

<#
.SYNOPSIS
    SSH agent and key management helpers.
.DESCRIPTION
    Provides functions and aliases for SSH key management:
    - Get-SSHKeys (ssh-list): list loaded keys
    - Add-SSHKeyIfNotLoaded (ssh-add-if): idempotent key loader
    - Start-SSHAgent (ssh-agent-start): start agent if not running
#>

# Show loaded keys
# Tier: essential
# Dependencies: bootstrap, env
# Environment: server, development
if (-not (Test-Path Function:\Get-SSHKeys)) {
    $sbList = { ssh-add -l }
    # Create directly via Function: provider to keep dot-source cheap
    New-Item -Path Function:\Get-SSHKeys -Value $sbList -Force | Out-Null
    Set-AgentModeAlias -Name 'ssh-list' -Target 'Get-SSHKeys'
}

# Add a private key to the agent (idempotent wrapper)
if (-not (Test-Path Function:\Add-SSHKeyIfNotLoaded)) {
    $sbAddIf = {
        param($path)
        if (-not $path) { Write-Warning 'Usage: Add-SSHKeyIfNotLoaded <path-to-key>'; return }
        if (-not ($path -and -not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path))) { Write-Warning 'Key not found: ' + $path; return }
        $existing = (ssh-add -l 2>$null) -join "`n"
        if ($existing -and $existing -match (Split-Path $path -Leaf)) { Write-Output 'Key already loaded'; return }
        ssh-add $path
    }
    New-Item -Path Function:\Add-SSHKeyIfNotLoaded -Value $sbAddIf -Force | Out-Null
    Set-AgentModeAlias -Name 'ssh-add-if' -Target 'Add-SSHKeyIfNotLoaded'
}

# Start Pageant/ssh-agent on Windows (if not running)
if (-not (Test-Path Function:\Start-SSHAgent)) {
    # Register a lazy starter for ssh-agent; do not probe or start at dot-source
    $sb = {
        # Start ssh-agent in the background and set env vars for the current session
        try {
            $out = ssh-agent -s 2>$null
            if ($out) {
                $env:SSH_AUTH_SOCK = ($out | Select-String -Pattern 'SSH_AUTH_SOCK' | ForEach-Object { ($_ -replace 'SSH_AUTH_SOCK=', '') -split ';' | Select-Object -First 1 })
                $env:SSH_AGENT_PID = ($out | Select-String -Pattern 'SSH_AGENT_PID' | ForEach-Object { ($_ -replace 'SSH_AGENT_PID=', '') -split ';' | Select-Object -First 1 })
                Write-Output 'ssh-agent started (if available)'
            }
            else {
                Write-Output 'ssh-agent not available'
            }
        }
        catch {
            Write-Verbose "ssh-agent starter failed: $($_.Exception.Message)"
        }
    }
    if (-not (Test-Path Function:\Start-SSHAgent)) {
        New-Item -Path Function:\Start-SSHAgent -Value $sb -Force | Out-Null
        Set-AgentModeAlias -Name 'ssh-agent-start' -Target 'Start-SSHAgent'
    }
}
