# ===============================================
# 26-rclone.ps1
# rclone convenience helpers (guarded)
# ===============================================

# rclone copy - copy files to/from remote
if (-not (Test-Path Function:rcopy -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rcopy -Value { param($src, $dst) if (Test-HasCommand rclone) { rclone Copy-Item $src $dst } else { Write-Warning 'rclone not found' } } -Force | Out-Null
}

# rclone list - list remote files
if (-not (Test-Path Function:rls -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rls -Value { param($p) if (Test-HasCommand rclone) { rclone ls $p } else { Write-Warning 'rclone not found' } } -Force | Out-Null
}
