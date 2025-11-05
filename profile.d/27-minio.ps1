# ===============================================
# 27-minio.ps1
# MinIO client helpers (mc) — guarded
# ===============================================

# MinIO list - list files in MinIO
if (-not (Test-Path Function:mc-ls -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:mc-ls -Value { param($p) if (Test-HasCommand mc) { mc ls $p } else { Write-Warning 'mc not found' } } -Force | Out-Null
}

# MinIO copy - copy files to/from MinIO
if (-not (Test-Path Function:mc-cp -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:mc-cp -Value { param($src, $dst) if (Test-HasCommand mc) { mc cp $src $dst } else { Write-Warning 'mc not found' } } -Force | Out-Null
}
