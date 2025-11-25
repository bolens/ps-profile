# ===============================================
# 22-containers.ps1
# Container engine helpers (Docker/Podman) and Compose utilities
# ===============================================
# Provides unified container management functions that work with either Docker or Podman.
# Functions automatically detect available engines and prefer Docker, falling back to Podman.
# All helpers are idempotent and check for engine availability before executing commands.

# Load container utility modules (loaded eagerly as they provide commonly-used container helpers)
$containerModulesDir = Join-Path $PSScriptRoot 'container-modules'
if (Test-Path $containerModulesDir) {
    # Core container helpers (engine detection, unified command wrappers)
    . (Join-Path $containerModulesDir 'container-helpers.ps1')
    # Docker Compose support
    . (Join-Path $containerModulesDir 'container-compose.ps1')
    # Podman Compose support (alternative to Docker Compose)
    . (Join-Path $containerModulesDir 'container-compose-podman.ps1')
}
