# ===============================================
# 02-files.ps1
# Consolidated file and listing utilities (json/yaml, eza, bat, navigation)
# ===============================================

# Lazy bulk initializer for file helpers
if (-not (Test-Path "Function:\\Ensure-FileHelper")) {
    function Ensure-FileHelper {
        # Replace this initializer with the real implementations. Use the cached
        # command availability helper for checks.
        if ($script:__FileHelperInitialized) { return }
        $script:__FileHelperInitialized = $true

        # JSON pretty-print
        Set-Item -Path Function:json-pretty -Value {
            param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            if ($fileArgs) { Get-Content -Raw -LiteralPath @fileArgs | ConvertFrom-Json | ConvertTo-Json -Depth 10 }
            else { $input | ConvertFrom-Json | ConvertTo-Json -Depth 10 }
        } -Force | Out-Null

        # YAML to JSON
        Set-Item -Path Function:yaml-to-json -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -o=json @fileArgs } -Force | Out-Null
        # JSON to YAML
        Set-Item -Path Function:json-to-yaml -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) yq eval -P @fileArgs } -Force | Out-Null

        # Listing helpers (prefer eza when available)
        Set-Item -Path Function:ll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons --git @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:la -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:lx -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Item -Path Function:tree -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -T --icons @fileArgs } else { Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName } } -Force | Out-Null

        # bat wrapper
        Set-Item -Path Function:bat-cat -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if ($fileArgs) { if (Test-CachedCommand bat) { bat @fileArgs } else { Get-Content -LiteralPath @fileArgs | Out-Host } } else { if (Test-CachedCommand bat) { bat } else { $input | Out-Host } } } -Force | Out-Null

        # Up directory
        Set-Item -Path Function:.. -Value { Set-Location .. } -Force | Out-Null
        # Up two directories
        Set-Item -Path Function:... -Value { Set-Location ..\..\ } -Force | Out-Null
        # Up three directories
        Set-Item -Path Function:.... -Value { Set-Location ..\..\..\ } -Force | Out-Null
        # Go to user's Home directory
        Set-Item -Path Function:~ -Value { Set-Location $env:USERPROFILE } -Force | Out-Null
        # Go to user's Desktop directory
        Set-Item -Path Function:desktop -Value { Set-Location "$env:USERPROFILE\Desktop" } -Force | Out-Null
        # Go to user's Downloads directory
        Set-Item -Path Function:downloads -Value { Set-Location "$env:USERPROFILE\Downloads" } -Force | Out-Null
        # Go to user's Documents directory
        Set-Item -Path Function:docs -Value { Set-Location "$env:USERPROFILE\Documents" } -Force | Out-Null

        # head (first N lines))
        Set-Item -Path Function:head -Value {
            param([Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            process {
                if ($InputObject) { $InputObject | Select-Object -First $Lines }
                elseif ($fileArgs) { Get-Content -LiteralPath @fileArgs | Select-Object -First $Lines }
                else { $input | Select-Object -First $Lines }
            }
        } -Force | Out-Null

        # tail (last N lines)
        Set-Item -Path Function:tail -Value {
            param([Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            process {
                if ($InputObject) { $InputObject | Select-Object -Last $Lines }
                elseif ($fileArgs) { Get-Content -LiteralPath @fileArgs | Select-Object -Last $Lines }
                else { $input | Select-Object -Last $Lines }
            }
        } -Force | Out-Null

        # Base64 encode
        Set-Item -Path Function:to-base64 -Value { param([Parameter(ValueFromPipeline = $true)] $InputObject) process { if ($InputObject -is [string] -and (Test-Path -LiteralPath $InputObject)) { [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $InputObject))) } else { $bytes = [Text.Encoding]::UTF8.GetBytes(($InputObject | Out-String)); [Convert]::ToBase64String($bytes) } } } -Force | Out-Null
        # Base64 decode
        Set-Item -Path Function:from-base64 -Value { param([Parameter(ValueFromPipeline = $true)] $InputObject) process { $s = ($InputObject -join "") -replace '\s+', ''; try { $bytes = [Convert]::FromBase64String($s); [Text.Encoding]::UTF8.GetString($bytes) } catch { Write-Error "Invalid base64 input" } } } -Force | Out-Null

        # CSV to JSON
        Set-Item -Path Function:csv-to-json -Value { param([string]$Path) Import-Csv -Path $Path | ConvertTo-Json -Depth 10 } -Force | Out-Null
        # XML to JSON
        Set-Item -Path Function:xml-to-json -Value { param([string]$Path) try { $xml = [xml](Get-Content -LiteralPath $Path -Raw); $xml | ConvertTo-Json -Depth 100 } catch { Write-Error "Failed to parse XML: $_" } } -Force | Out-Null

        # File hash
        Set-Item -Path Function:file-hash -Value { param([string]$Path, [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')] [string]$Algorithm = 'SHA256') if (-not (Test-Path -LiteralPath $Path)) { Write-Error "File not found: $Path"; return } Get-FileHash -Algorithm $Algorithm -Path $Path } -Force | Out-Null
        # File size
        Set-Item -Path Function:filesize -Value { param([string]$Path) if (-not (Test-Path -LiteralPath $Path)) { Write-Error "File not found: $Path"; return } $len = (Get-Item -LiteralPath $Path).Length; switch ($len) { { $_ -ge 1TB } { "{0:N2} TB" -f ($len / 1TB); break } { $_ -ge 1GB } { "{0:N2} GB" -f ($len / 1GB); break } { $_ -ge 1MB } { "{0:N2} MB" -f ($len / 1MB); break } { $_ -ge 1KB } { "{0:N2} KB" -f ($len / 1KB); break } default { "{0} bytes" -f $len } } } -Force | Out-Null
    }
}

# Lightweight stubs that ensure the real implementations are created on first use
# Pretty-print JSON
function json-pretty { if (-not (Test-Path Function:\json-pretty)) { Ensure-FileHelper }; return & (Get-Item Function:\json-pretty -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Convert YAML to JSON
function yaml-to-json { if (-not (Test-Path Function:\yaml-to-json)) { Ensure-FileHelper }; return & (Get-Item Function:\yaml-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Convert JSON to YAML
function json-to-yaml { if (-not (Test-Path Function:\json-to-yaml)) { Ensure-FileHelper }; return & (Get-Item Function:\json-to-yaml -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# List files in a directory
function ll { if (-not (Test-Path Function:\ll)) { Ensure-FileHelper }; return & (Get-Item Function:\ll -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# List all files including hidden
function la { if (-not (Test-Path Function:\la)) { Ensure-FileHelper }; return & (Get-Item Function:\la -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# List files excluding hidden
function lx { if (-not (Test-Path Function:\lx)) { Ensure-FileHelper }; return & (Get-Item Function:\lx -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Display directory tree
function tree { if (-not (Test-Path Function:\tree)) { Ensure-FileHelper }; return & (Get-Item Function:\tree -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# cat with syntax highlighting (bat)
function bat-cat { if (-not (Test-Path Function:\bat-cat)) { Ensure-FileHelper }; return & (Get-Item Function:\bat-cat -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Up one directory
Set-Item -Path Function:\.. -Value { if (-not (Test-Path Function:\..)) { Ensure-FileHelper }; return & (Get-Item Function:\.. -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null
# Up two directories
function ... { if (-not (Test-Path Function:\...)) { Ensure-FileHelper }; return & (Get-Item Function:\... -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Up three directories
function .... { if (-not (Test-Path Function:\....)) { Ensure-FileHelper }; return & (Get-Item Function:\.... -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Go to user home directory
Set-Item -Path Function:\~ -Value { if (-not (Test-Path Function:\~)) { Ensure-FileHelper }; return & (Get-Item Function:\~ -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null
# Go to Desktop directory
function desktop { if (-not (Test-Path Function:\desktop)) { Ensure-FileHelper }; return & (Get-Item Function:\desktop -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Go to Downloads directory
function downloads { if (-not (Test-Path Function:\downloads)) { Ensure-FileHelper }; return & (Get-Item Function:\downloads -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Go to Documents directory
function docs { if (-not (Test-Path Function:\docs)) { Ensure-FileHelper }; return & (Get-Item Function:\docs -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Head (first 10 lines) of a file
function head { if (-not (Test-Path Function:\head)) { Ensure-FileHelper }; return & (Get-Item Function:\head -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Tail (last 10 lines) of a file
function tail { if (-not (Test-Path Function:\tail)) { Ensure-FileHelper }; return & (Get-Item Function:\tail -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Encode to base64
function to-base64 { if (-not (Test-Path Function:\to-base64)) { Ensure-FileHelper }; return & (Get-Item Function:\to-base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Decode from base64
function from-base64 { if (-not (Test-Path Function:\from-base64)) { Ensure-FileHelper }; return & (Get-Item Function:\from-base64 -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Convert CSV to JSON
function csv-to-json { if (-not (Test-Path Function:\csv-to-json)) { Ensure-FileHelper }; return & (Get-Item Function:\csv-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Convert XML to JSON
function xml-to-json { if (-not (Test-Path Function:\xml-to-json)) { Ensure-FileHelper }; return & (Get-Item Function:\xml-to-json -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Get file hash
function file-hash { if (-not (Test-Path Function:\file-hash)) { Ensure-FileHelper }; return & (Get-Item Function:\file-hash -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
# Get file size
function filesize { if (-not (Test-Path Function:\filesize)) { Ensure-FileHelper }; return & (Get-Item Function:\filesize -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }














