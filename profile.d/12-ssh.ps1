# ===============================================
# 12-ssh.ps1
# SSH agent and key helpers
# ===============================================

# Show loaded keys
if (-not (Test-Path Function:\ssh-list)) {
  $sbList = { ssh-add -l }
  # Create directly via Function: provider to keep dot-source cheap
  New-Item -Path Function:\ssh-list -Value $sbList -Force | Out-Null
}

# Add a private key to the agent (idempotent wrapper)
if (-not (Test-Path Function:\ssh-add-if)) {
  $sbAddIf = {
    param($path)
    if (-not $path) { Write-Warning 'Usage: ssh-add-if <path-to-key>'; return }
    if (-not (Test-Path $path)) { Write-Warning 'Key not found: ' + $path; return }
    $existing = (ssh-add -l 2>$null) -join "`n"
    if ($existing -and $existing -match (Split-Path $path -Leaf)) { Write-Output 'Key already loaded'; return }
    ssh-add $path
  }
  New-Item -Path Function:\ssh-add-if -Value $sbAddIf -Force | Out-Null
}

# Start Pageant/ssh-agent on Windows (if not running)
if (-not (Test-Path Function:\ssh-agent-start)) {
  # Register a lazy starter for ssh-agent; do not probe or start at dot-source
  $sb = {
    # Start ssh-agent in the background and set env vars for the current session
    try {
      $out = ssh-agent -s 2>$null
      if ($out) {
        $env:SSH_AUTH_SOCK = ($out | Select-String -Pattern 'SSH_AUTH_SOCK' | ForEach-Object { ($_ -split ';')[0] -replace 'set | ','' })
        $env:SSH_AGENT_PID = ($out | Select-String -Pattern 'SSH_AGENT_PID' | ForEach-Object { ($_ -split ';')[0] -replace 'set | ','' })
        Write-Output 'ssh-agent started (if available)'
      } else {
        Write-Output 'ssh-agent not available'
      }
    } catch {
      Write-Verbose "ssh-agent starter failed: $($_.Exception.Message)"
    }
  }
  if (-not (Test-Path Function:\ssh-agent-start)) {
    New-Item -Path Function:\ssh-agent-start -Value $sb -Force | Out-Null
  }
}
