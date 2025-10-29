# ===============================================
# 03-agent-mode.ps1
# Thin compatibility shim for legacy "agent-mode" helpers.
# This file is intentionally small: it documents the migration and
# provides a few safe, non-destructive compatibility helpers that
# defer to canonical fragments when available.
# ===============================================

if (Test-Path 'Function:Set-AgentModeFunction') {
    # Provide a safe, backwards-compatible alias for listing functions
    $null = Set-AgentModeFunction -Name 'am-list' -Body { Get-Command -CommandType Function | Where-Object { $_.Name -like '*am*' } }

    # Compatibility: open the legacy agent-mode README if present
    $null = Set-AgentModeFunction -Name 'am-doc' -Body {
        $p = Join-Path (Split-Path $PROFILE) 'profile.d\00-bootstrap.README.md'
        if (Test-Path $p) { notepad $p } else { Write-Output 'No agent-mode docs available locally.' }
    }
}














