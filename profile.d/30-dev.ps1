# ===============================================
# 30-dev.ps1
# Development shortcuts (docker, podman, k8s, node, python, cargo)
# ===============================================

# Docker shortcuts
function d { docker $args }
# dc: docker-compose wrapper — register a stub if not present
if (-not (Test-Path Function:dc -ErrorAction SilentlyContinue)) { Set-Item -Path Function:dc -Value { docker-compose @Args } -Force | Out-Null }
function dps { docker ps $args }
function di { docker images $args }
function drm { docker rm $args }
function drmi { docker rmi $args }
function dexec { docker exec -it $args }
function dlogs { docker logs $args }

# Podman shortcuts
function pd { podman $args }
function pps { podman ps $args }
function pi { podman images $args }

# Node.js shortcuts
function New-Item { npm install $args }
function nr { npm run $args }
function ns { npm start $args }
function nt { npm test $args }
function nb { npm run build $args }
function nrd { npm run dev $args }

# Python shortcuts
function py { python $args }
function venv { python -m venv $args }
function activate { .\venv\Scripts\Activate.ps1 }
function req { python -m pip freeze > requirements.txt }
function pipi { python -m pip install $args }
function pipu { python -m pip install --upgrade $args }

# Cargo/Rust shortcuts
function cr { cargo run $args }
# cb (cargo build) is provided by the smaller clipboard/shortcuts fragment
# (profile.d/14-clipboard.ps1) and is authoritative. The fallback definition
# in this file was removed to avoid duplicate command registrations.
function ct { cargo test $args }
function cc { cargo check $args }
function cu { cargo update $args }
function ca { cargo add $args }
function cw { cargo watch -x run }
