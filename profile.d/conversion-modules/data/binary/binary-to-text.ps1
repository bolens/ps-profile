# ===============================================
# Binary-to-text conversion utilities
# Converts binary formats (BSON, MessagePack, CBOR) to text formats (CSV, YAML)
# ===============================================

<#
.SYNOPSIS
    Initializes binary format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for binary-to-text conversions from BSON, MessagePack, and CBOR to CSV and YAML.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and respective npm packages for each format.
#>
function Initialize-FileConversion-BinaryToText {
    # Ensure NodeJs module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'NodeJs.psm1'
        if (Test-Path $nodeJsModulePath) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
}
# Convert BSON to CSV
<#
.SYNOPSIS
    Converts BSON file to CSV format.
.DESCRIPTION
    Converts a BSON (Binary JSON) file to CSV format for easy inspection and debugging.
    Requires Node.js and the bson package to be installed.
.PARAMETER InputPath
    The path to the BSON file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-BsonToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-BsonToCsv @PSBoundParameters
}
Set-Alias -Name bson-to-csv -Value ConvertFrom-BsonToCsv -ErrorAction SilentlyContinue

# Convert MessagePack to CSV
<#
.SYNOPSIS
    Converts MessagePack file to CSV format.
.DESCRIPTION
    Converts a MessagePack binary file to CSV format for easy inspection and debugging.
    Requires Node.js and the @msgpack/msgpack package to be installed.
.PARAMETER InputPath
    The path to the MessagePack file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-MessagePackToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MessagePackToCsv @PSBoundParameters
}
Set-Alias -Name msgpack-to-csv -Value ConvertFrom-MessagePackToCsv -ErrorAction SilentlyContinue
Set-Alias -Name messagepack-to-csv -Value ConvertFrom-MessagePackToCsv -ErrorAction SilentlyContinue

# Convert CBOR to CSV
<#
.SYNOPSIS
    Converts CBOR file to CSV format.
.DESCRIPTION
    Converts a CBOR (Concise Binary Object Representation) file to CSV format for easy inspection and debugging.
    Requires Node.js and the cbor package to be installed.
.PARAMETER InputPath
    The path to the CBOR file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-CborToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CborToCsv @PSBoundParameters
}
Set-Alias -Name cbor-to-csv -Value ConvertFrom-CborToCsv -ErrorAction SilentlyContinue

# Convert BSON to YAML
<#
.SYNOPSIS
    Converts BSON file to YAML format.
.DESCRIPTION
    Converts a BSON (Binary JSON) file to YAML format for easy inspection and debugging.
    Requires Node.js, the bson package, and yq to be installed.
.PARAMETER InputPath
    The path to the BSON file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-BsonToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-BsonToYaml @PSBoundParameters
}
Set-Alias -Name bson-to-yaml -Value ConvertFrom-BsonToYaml -ErrorAction SilentlyContinue

# Convert MessagePack to YAML
<#
.SYNOPSIS
    Converts MessagePack file to YAML format.
.DESCRIPTION
    Converts a MessagePack binary file to YAML format for easy inspection and debugging.
    Requires Node.js, the @msgpack/msgpack package, and yq to be installed.
.PARAMETER InputPath
    The path to the MessagePack file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-MessagePackToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MessagePackToYaml @PSBoundParameters
}
Set-Alias -Name msgpack-to-yaml -Value ConvertFrom-MessagePackToYaml -ErrorAction SilentlyContinue
Set-Alias -Name messagepack-to-yaml -Value ConvertFrom-MessagePackToYaml -ErrorAction SilentlyContinue

# Convert CBOR to YAML
<#
.SYNOPSIS
    Converts CBOR file to YAML format.
.DESCRIPTION
    Converts a CBOR (Concise Binary Object Representation) file to YAML format for easy inspection and debugging.
    Requires Node.js, the cbor package, and yq to be installed.
.PARAMETER InputPath
    The path to the CBOR file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-CborToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CborToYaml @PSBoundParameters
}
Set-Alias -Name cbor-to-yaml -Value ConvertFrom-CborToYaml -ErrorAction SilentlyContinue

# Binary to text conversions (for inspection/debugging)
# Binary to text conversions (for inspection/debugging)
    
# BSON to CSV
Set-Item -Path Function:Global:_ConvertFrom-BsonToCsv -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bson$', '.csv' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use BSON conversions."
        }
        # Convert BSON to JSON first, then JSON to CSV
        $tempJson = Join-Path $env:TEMP "bson-to-csv-$(Get-Random).json"
        try {
            _ConvertFrom-BsonToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "BSON to JSON conversion failed - output file not created"
            }
            # Use PowerShell's ConvertFrom-Json and Export-Csv
            $jsonContent = Get-Content -LiteralPath $tempJson -Raw -ErrorAction Stop
            $jsonData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            if ($jsonData -is [array]) {
                $jsonData | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            elseif ($jsonData -is [PSCustomObject]) {
                @($jsonData) | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            else {
                throw "BSON data must be an array or object"
            }
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|bson package') {
                "BSON package is not installed. Install it with: pnpm add -g bson"
            }
            else {
                "Failed to convert BSON to CSV: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert BSON to CSV: $_"
    }
} -Force

# MessagePack to CSV
Set-Item -Path Function:Global:_ConvertFrom-MessagePackToCsv -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.msgpack$', '.csv' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use MessagePack conversions."
        }
        # Convert MessagePack to JSON first, then JSON to CSV
        $tempJson = Join-Path $env:TEMP "msgpack-to-csv-$(Get-Random).json"
        try {
            _ConvertFrom-MessagePackToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "MessagePack to JSON conversion failed - output file not created"
            }
            # Use PowerShell's ConvertFrom-Json and Export-Csv
            $jsonContent = Get-Content -LiteralPath $tempJson -Raw -ErrorAction Stop
            $jsonData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            if ($jsonData -is [array]) {
                $jsonData | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            elseif ($jsonData -is [PSCustomObject]) {
                @($jsonData) | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            else {
                throw "MessagePack data must be an array or object"
            }
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|@msgpack/msgpack') {
                "@msgpack/msgpack package is not installed. Install it with: pnpm add -g @msgpack/msgpack"
            }
            else {
                "Failed to convert MessagePack to CSV: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MessagePack to CSV: $_"
    }
} -Force

# CBOR to CSV
Set-Item -Path Function:Global:_ConvertFrom-CborToCsv -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.cbor$', '.csv' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use CBOR conversions."
        }
        # Convert CBOR to JSON first, then JSON to CSV
        $tempJson = Join-Path $env:TEMP "cbor-to-csv-$(Get-Random).json"
        try {
            _ConvertFrom-CborToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "CBOR to JSON conversion failed - output file not created"
            }
            # Use PowerShell's ConvertFrom-Json and Export-Csv
            $jsonContent = Get-Content -LiteralPath $tempJson -Raw -ErrorAction Stop
            $jsonData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            if ($jsonData -is [array]) {
                $jsonData | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            elseif ($jsonData -is [PSCustomObject]) {
                @($jsonData) | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
            }
            else {
                throw "CBOR data must be an array or object"
            }
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|cbor package') {
                "cbor package is not installed. Install it with: pnpm add -g cbor"
            }
            else {
                "Failed to convert CBOR to CSV: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert CBOR to CSV: $_"
    }
} -Force

# BSON to YAML
Set-Item -Path Function:Global:_ConvertFrom-BsonToYaml -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bson$', '.yaml' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use BSON conversions."
        }
        if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
            throw "yq is not available. Install yq to use BSON to YAML conversions."
        }
        # Convert BSON to JSON first, then JSON to YAML
        $tempJson = Join-Path $env:TEMP "bson-to-yaml-$(Get-Random).json"
        try {
            _ConvertFrom-BsonToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "BSON to JSON conversion failed - output file not created"
            }
            $yamlResult = & yq eval -p json -o yaml '.' $tempJson 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "yq command failed"
            }
            $yamlResult | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|bson package') {
                "BSON package is not installed. Install it with: pnpm add -g bson"
            }
            elseif ($_.Exception.Message -match 'yq.*not available|yq command failed') {
                "yq is not available. Install yq to use YAML conversions."
            }
            else {
                "Failed to convert BSON to YAML: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert BSON to YAML: $_"
    }
} -Force

# MessagePack to YAML
Set-Item -Path Function:Global:_ConvertFrom-MessagePackToYaml -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.msgpack$', '.yaml' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use MessagePack conversions."
        }
        if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
            throw "yq is not available. Install yq to use MessagePack to YAML conversions."
        }
        # Convert MessagePack to JSON first, then JSON to YAML
        $tempJson = Join-Path $env:TEMP "msgpack-to-yaml-$(Get-Random).json"
        try {
            _ConvertFrom-MessagePackToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "MessagePack to JSON conversion failed - output file not created"
            }
            $yamlResult = & yq eval -p json -o yaml '.' $tempJson 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "yq command failed"
            }
            $yamlResult | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|@msgpack/msgpack') {
                "@msgpack/msgpack package is not installed. Install it with: pnpm add -g @msgpack/msgpack"
            }
            elseif ($_.Exception.Message -match 'yq.*not available|yq command failed') {
                "yq is not available. Install yq to use YAML conversions."
            }
            else {
                "Failed to convert MessagePack to YAML: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MessagePack to YAML: $_"
    }
} -Force

# CBOR to YAML
Set-Item -Path Function:Global:_ConvertFrom-CborToYaml -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.cbor$', '.yaml' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use CBOR conversions."
        }
        if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
            throw "yq is not available. Install yq to use CBOR to YAML conversions."
        }
        # Convert CBOR to JSON first, then JSON to YAML
        $tempJson = Join-Path $env:TEMP "cbor-to-yaml-$(Get-Random).json"
        try {
            _ConvertFrom-CborToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
            if (-not (Test-Path $tempJson)) {
                throw "CBOR to JSON conversion failed - output file not created"
            }
            $yamlResult = & yq eval -p json -o yaml '.' $tempJson 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "yq command failed"
            }
            $yamlResult | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|cbor package') {
                "cbor package is not installed. Install it with: pnpm add -g cbor"
            }
            elseif ($_.Exception.Message -match 'yq.*not available|yq command failed') {
                "yq is not available. Install yq to use YAML conversions."
            }
            else {
                "Failed to convert CBOR to YAML: $_"
            }
            Write-Error $errorMsg
        }
        finally {
            Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert CBOR to YAML: $_"
    }
} -Force
