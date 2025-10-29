# ===============================================
# 26-rclone.ps1
# rclone convenience helpers (guarded)
# ===============================================

# rclone copy - copy files to/from remote
if (-not (Test-Path Function:rcopy -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:rcopy -Value { param($src, $dst) if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand rclone) { rclone Copy-Item $src $dst } else { Write-Warning 'rclone not found' } } else { if (Get-Command rclone -ErrorAction SilentlyContinue) { rclone Copy-Item $src $dst } else { Write-Warning 'rclone not found' } } } -Force | Out-Null
}

# rclone list - list remote files
if (-not (Test-Path Function:rls -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:rls -Value { param($p) if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand rclone) { rclone ls $p } else { Write-Warning 'rclone not found' } } else { if (Get-Command rclone -ErrorAction SilentlyContinue) { rclone ls $p } else { Write-Warning 'rclone not found' } } } -Force | Out-Null
}
















