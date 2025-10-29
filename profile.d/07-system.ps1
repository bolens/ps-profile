# ===============================================
# 07-system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================

# which equivalent
function which { Get-Command $args }
# pgrep equivalent
function pgrep { Select-String $args }
# touch equivalent
function touch { New-Item -ItemType File $args }
# mkdir equivalent
function mkdir { New-Item -ItemType Directory $args }
# rm equivalent
function rm { Remove-Item $args }
# cp equivalent
function cp { Copy-Item $args }
# mv equivalent
function mv { Move-Item $args }
# search equivalent
function search { Get-ChildItem -Recurse -Name $args }
# df equivalent
function df { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root }
# top equivalent
function htop { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# ports equivalent
function ports { netstat -an $args }
# ptest equivalent
function ptest { Test-Connection $args }
# dns equivalent
function dns { Resolve-DnsName $args }
# rest equivalent
function rest { Invoke-RestMethod $args }
# web equivalent
function web { Invoke-WebRequest $args }

# unzip equivalent
function unzip { Expand-Archive $args }
# zip equivalent
function zip { Compress-Archive $args }
# code alias for VS Code
function code { & "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" $args }
# vim alias for neovim
function vim { nvim $args }
# vi alias for neovim
function vi { nvim $args }












