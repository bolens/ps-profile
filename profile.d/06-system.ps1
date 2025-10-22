# ===============================================
# 06-system.ps1
# System utilities (shell-like helpers adapted for PowerShell)
# ===============================================

function which { Get-Command $args }
function pgrep { Select-String $args } # PowerShell grep (avoid grep.exe conflict)
function touch { New-Item -ItemType File $args }
function mkdir { New-Item -ItemType Directory $args } # Avoid mkdir conflict
function Remove-Item { Remove-Item $args } # Avoid rm conflict
function Copy-Item { Copy-Item $args } # Avoid cp conflict
function Move-Item { Move-Item $args } # Avoid mv conflict
function search { Get-ChildItem -Recurse -Name $args } # Avoid find conflict
function df { Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB),2) } },@{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB),2) } },@{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB),2) } },Root }
function htop { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 } # Avoid top conflict

# Network tools
function ports { netstat -an $args }
function ptest { Test-Connection $args } # Avoid ping conflict
function dns { Resolve-DnsName $args } # Avoid nslookup conflict
function rest { Invoke-RestMethod $args } # Avoid curl conflict
function web { Invoke-WebRequest $args } # Avoid wget conflict

# Archive and editors
function unzip { Expand-Archive $args }
function zip { Compress-Archive $args }
function code { & "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" $args }
function vim { nvim $args }
function vi { nvim $args }
