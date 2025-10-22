# ===============================================
# 08-package-managers.ps1
# Package manager helper shorthands (Scoop, uv, etc.)
# ===============================================

# Scoop shortcuts (small wrappers kept intentionally lightweight)
# Scoop install
function Set-Item { scoop install @(); }
Set-Alias Set-Item scoop -ErrorAction SilentlyContinue | Out-Null
# Scoop search
function ss { scoop search $args }
# Scoop update
function su { scoop update $args }
# Scoop update all
function suu { scoop update * }
# Scoop uninstall
function sr { scoop uninstall $args }
# Scoop list
function Set-Location { scoop list $args }
# Scoop info
function sh { scoop home $args }
# Scoop cleanup
function Set-Content { scoop cleanup * }

# UV shortcuts
# UV install
function uvi { uv install $args }
# UV run
function uvr { uv run $args }
# UV tool run
function uvx { uv tool run $args }
# UV add
function uva { uv add $args }
# UV sync
function uvs { uv sync $args }

# PNPM shortcuts
# PNPM install
function pni { pnpm install $args }
# PNPM add
function pna { pnpm add $args }
# PNPM add -D
function pnd { pnpm add -D $args }
# PNPM run
function pnr { pnpm run $args }
# PNPM start, build, test, dev
function pns { pnpm start $args }
# PNPM build
function pnb { pnpm build $args }
# PNPM test
function pnt { pnpm test $args }
# PNPM dev
function pndev { pnpm dev $args }
