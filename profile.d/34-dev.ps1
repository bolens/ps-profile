# ===============================================
# 34-dev.ps1
# Development shortcuts (docker, podman, k8s, node, python, cargo)
# ===============================================

# Docker shortcuts
# d: docker wrapper
if (-not (Test-Path Function:d -ErrorAction SilentlyContinue)) { Set-Item -Path Function:d -Value { docker @Args } -Force | Out-Null }
# dc: docker-compose wrapper
if (-not (Test-Path Function:dc -ErrorAction SilentlyContinue)) { Set-Item -Path Function:dc -Value { docker-compose @Args } -Force | Out-Null }
# dps: docker ps wrapper
if (-not (Test-Path Function:dps -ErrorAction SilentlyContinue)) { Set-Item -Path Function:dps -Value { docker ps @Args } -Force | Out-Null }
# di: docker images wrapper
if (-not (Test-Path Function:di -ErrorAction SilentlyContinue)) { Set-Item -Path Function:di -Value { docker images @Args } -Force | Out-Null }
# drm: docker rm wrapper
if (-not (Test-Path Function:drm -ErrorAction SilentlyContinue)) { Set-Item -Path Function:drm -Value { docker rm @Args } -Force | Out-Null }
# drmi: docker rmi wrapper
if (-not (Test-Path Function:drmi -ErrorAction SilentlyContinue)) { Set-Item -Path Function:drmi -Value { docker rmi @Args } -Force | Out-Null }
# dexec: docker exec -it wrapper
if (-not (Test-Path Function:dexec -ErrorAction SilentlyContinue)) { Set-Item -Path Function:dexec -Value { docker exec -it @Args } -Force | Out-Null }
# dlogs: docker logs wrapper
if (-not (Test-Path Function:dlogs -ErrorAction SilentlyContinue)) { Set-Item -Path Function:dlogs -Value { docker logs @Args } -Force | Out-Null }

# Podman shortcuts
# pd: podman wrapper
if (-not (Test-Path Function:pd -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pd -Value { podman @Args } -Force | Out-Null }
# pps: podman ps wrapper
if (-not (Test-Path Function:pps -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pps -Value { podman ps $args } -Force | Out-Null }
# pi: podman images wrapper
if (-not (Test-Path Function:pi -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pi -Value { podman images $args } -Force | Out-Null }
# prmi: podman rmi wrapper
if (-not (Test-Path Function:prmi -ErrorAction SilentlyContinue)) { Set-Item -Path Function:prmi -Value { podman rmi $args } -Force | Out-Null }
# pdexec: podman exec -it wrapper
if (-not (Test-Path Function:pdexec -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pdexec -Value { podman exec -it $args } -Force | Out-Null }
# pdlogs: podman logs wrapper
if (-not (Test-Path Function:pdlogs -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pdlogs -Value { podman logs $args } -Force | Out-Null }

# Node.js shortcuts
# n: npm wrapper
if (-not (Test-Path Function:n -ErrorAction SilentlyContinue)) { Set-Item -Path Function:n -Value { npm @Args } -Force | Out-Null }
# ni: npm install wrapper
if (-not (Test-Path Function:ni -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ni -Value { npm install @Args } -Force | Out-Null }
# nr: npm run wrapper
if (-not (Test-Path Function:nr -ErrorAction SilentlyContinue)) { Set-Item -Path Function:nr -Value { npm run @Args } -Force | Out-Null }
# ns: npm start wrapper
if (-not (Test-Path Function:ns -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ns -Value { npm start @Args } -Force | Out-Null }
# nt: npm test wrapper
if (-not (Test-Path Function:nt -ErrorAction SilentlyContinue)) { Set-Item -Path Function:nt -Value { npm test @Args } -Force | Out-Null }
# np: npm publish wrapper
if (-not (Test-Path Function:np -ErrorAction SilentlyContinue)) { Set-Item -Path Function:np -Value { npm publish @Args } -Force | Out-Null }
# nb: npm run build wrapper
if (-not (Test-Path Function:nb -ErrorAction SilentlyContinue)) { Set-Item -Path Function:nb -Value { npm run build @Args } -Force | Out-Null }
# nrd: npm run dev wrapper
if (-not (Test-Path Function:nrd -ErrorAction SilentlyContinue)) { Set-Item -Path Function:nrd -Value { npm run dev @Args } -Force | Out-Null }

# Python shortcuts
# py: python wrapper
if (-not (Test-Path Function:py -ErrorAction SilentlyContinue)) { Set-Item -Path Function:py -Value { python @Args } -Force | Out-Null }
# venv: python virtual environment wrapper
if (-not (Test-Path Function:venv -ErrorAction SilentlyContinue)) { Set-Item -Path Function:venv -Value { python -m venv @Args } -Force | Out-Null }
# activate: activate virtual environment
if (-not (Test-Path Function:activate -ErrorAction SilentlyContinue)) { Set-Item -Path Function:activate -Value { .\venv\Scripts\Activate.ps1 } -Force | Out-Null }
# req: generate requirements.txt
if (-not (Test-Path Function:req -ErrorAction SilentlyContinue)) { Set-Item -Path Function:req -Value { python -m pip freeze > requirements.txt } -Force | Out-Null }
# pipi: pip install wrapper
if (-not (Test-Path Function:pipi -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pipi -Value { python -m pip install @Args } -Force | Out-Null }
# pipu: pip install --upgrade wrapper
if (-not (Test-Path Function:pipu -ErrorAction SilentlyContinue)) { Set-Item -Path Function:pipu -Value { python -m pip install --upgrade @Args } -Force | Out-Null }

# Cargo/Rust shortcuts
# cr: cargo run wrapper
if (-not (Test-Path Function:cr -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cr -Value { cargo run @Args } -Force | Out-Null }
# cb: cargo build wrapper
if (-not (Test-Path Function:cb -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cb -Value { cargo build @Args } -Force | Out-Null }
# ct: cargo test wrapper
if (-not (Test-Path Function:ct -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ct -Value { cargo test @Args } -Force | Out-Null }
# cc: cargo check wrapper
if (-not (Test-Path Function:cc -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cc -Value { cargo check @Args } -Force | Out-Null }
# cu: cargo update wrapper
if (-not (Test-Path Function:cu -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cu -Value { cargo update @Args } -Force | Out-Null }
# ca: cargo add wrapper
if (-not (Test-Path Function:ca -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ca -Value { cargo add @Args } -Force | Out-Null }
# cw: cargo watch -x run wrapper
if (-not (Test-Path Function:cw -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cw -Value { cargo watch -x run @Args } -Force | Out-Null }
# cd: cargo doc --open wrapper
if (-not (Test-Path Function:cd -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cd -Value { cargo doc --open @Args } -Force | Out-Null }
# cl: cargo clippy wrapper
if (-not (Test-Path Function:cl -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cl -Value { cargo clippy @Args } -Force | Out-Null }
# cf: cargo fmt wrapper
if (-not (Test-Path Function:cf -ErrorAction SilentlyContinue)) { Set-Item -Path Function:cf -Value { cargo fmt @Args } -Force | Out-Null }
# ci: cargo install wrapper
if (-not (Test-Path Function:ci -ErrorAction SilentlyContinue)) { Set-Item -Path Function:ci -Value { cargo install @Args } -Force | Out-Null }










