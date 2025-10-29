# ===============================================
# 27-minio.ps1
# MinIO client helpers (mc) — guarded
# ===============================================

# MinIO list - list files in MinIO
if (-not (Test-Path Function:mc-ls -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:mc-ls -Value { param($p) if (Test-CachedCommand mc) { mc ls $p } else { Write-Warning 'mc not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:mc-ls -Value { param($p) if (Get-Command mc -ErrorAction SilentlyContinue) { mc ls $p } else { Write-Warning 'mc not found' } } -Force | Out-Null
    }
}

# MinIO copy - copy files to/from MinIO
if (-not (Test-Path Function:mc-cp -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:mc-cp -Value { param($src, $dst) if (Test-CachedCommand mc) { mc cp $src $dst } else { Write-Warning 'mc not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:mc-cp -Value { param($src, $dst) if (Get-Command mc -ErrorAction SilentlyContinue) { mc cp $src $dst } else { Write-Warning 'mc not found' } } -Force | Out-Null
    }
}












