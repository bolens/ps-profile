# ===============================================
# 61-eza.ps1
# Modern ls replacement with eza
# ===============================================

# Eza aliases for modern directory listing
# Requires: eza (https://github.com/eza-community/eza)

if (Get-Command eza -ErrorAction SilentlyContinue) {
  # Basic ls replacements
  function ls { eza @args }
  function l { eza @args }

  # Long listing
  function ll { eza -l @args }
  function la { eza -la @args }
  function lla { eza -la @args }

  # Tree view
  function lt { eza --tree @args }
  function lta { eza --tree -a @args }

  # With git status
  function lg { eza --git @args }
  function llg { eza -l --git @args }

  # By size
  function lS { eza -l -s size @args }

  # By time
  function ltime { eza -l -s modified @args }
}
else {
  Write-Warning "eza not found. Install with: scoop install eza"
}
