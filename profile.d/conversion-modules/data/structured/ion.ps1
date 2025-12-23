# ===============================================
# Ion (Amazon Ion) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Ion format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Ion format conversions.
    Ion is a richly-typed, self-describing, hierarchical data serialization format.
    Ion supports both text and binary representations.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Ion is developed by Amazon and supports both text (.ion) and binary (.10n) formats.
    Reference: https://amzn.github.io/ion-docs/
#>
function Initialize-FileConversion-Ion {
    # Ensure Python module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Get-PythonPath -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $pythonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'Python.psm1'
        if ($pythonModulePath -and -not [string]::IsNullOrWhiteSpace($pythonModulePath) -and (Test-Path -LiteralPath $pythonModulePath)) {
            Import-Module $pythonModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }

    # Ion to JSON
    Set-Item -Path Function:Global:_ConvertFrom-IonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(ion|10n)$', '.json'
            }
            
            # Try Python with ion-python package
            if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
                $pythonCmd = Get-PythonPath
                if ($pythonCmd) {
                    $pythonScript = @"
import sys
import json

try:
    import ion
    from ion import simpleion
    
    with open(sys.argv[1], 'rb') as f:
        data = simpleion.load(f, single_value=False)
    
    # Convert Ion types to JSON-serializable types
    def ion_to_json(obj):
        if isinstance(obj, ion.SymbolToken):
            return str(obj)
        elif isinstance(obj, ion.Timestamp):
            return obj.isoformat()
        elif isinstance(obj, ion.Decimal):
            return float(obj)
        elif isinstance(obj, (list, tuple)):
            return [ion_to_json(item) for item in obj]
        elif isinstance(obj, dict):
            return {str(k): ion_to_json(v) for k, v in obj.items()}
        else:
            return obj
    
    json_data = ion_to_json(data)
    
    with open(sys.argv[2], 'w') as f:
        json.dump(json_data, f, indent=2)
except ImportError:
    print('Error: ion-python package is not installed. Install with: uv pip install ion-python', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
                    $tempScript = Join-Path $env:TEMP "ion-to-json-$(Get-Random).py"
                    Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
                    try {
                        $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Python script failed: $result"
                        }
                        return
                    }
                    finally {
                        Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                    }
                }
            }
            
            throw "Python is not available. Install Python and ion-python package (uv pip install ion-python) to use Ion conversions."
        }
        catch {
            Write-Error "Failed to convert Ion to JSON: $_"
            throw
        }
    } -Force

    # JSON to Ion
    Set-Item -Path Function:Global:_ConvertTo-IonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [switch]$Binary)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $ext = if ($Binary) { '.10n' } else { '.ion' }
                $OutputPath = $InputPath -replace '\.json$', $ext
            }
            
            # Try Python with ion-python package
            if (Get-Command Get-PythonPath -ErrorAction SilentlyContinue) {
                $pythonCmd = Get-PythonPath
                if ($pythonCmd) {
                    $binaryFlag = if ($Binary) { 'True' } else { 'False' }
                    $pythonScript = @"
import sys
import json

try:
    import ion
    from ion import simpleion
    
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    # Convert JSON to Ion types
    def json_to_ion(obj):
        if isinstance(obj, dict):
            return {ion.SymbolToken(k): json_to_ion(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [json_to_ion(item) for item in obj]
        else:
            return obj
    
    ion_data = json_to_ion(data)
    binary = sys.argv[3] == 'True'
    
    with open(sys.argv[2], 'wb') as f:
        if binary:
            simpleion.dump(ion_data, f, binary=True)
        else:
            simpleion.dump(ion_data, f, binary=False)
except ImportError:
    print('Error: ion-python package is not installed. Install with: uv pip install ion-python', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
                    $tempScript = Join-Path $env:TEMP "json-to-ion-$(Get-Random).py"
                    Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
                    try {
                        $result = & $pythonCmd $tempScript $InputPath $OutputPath $binaryFlag 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Python script failed: $result"
                        }
                        return
                    }
                    finally {
                        Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                    }
                }
            }
            
            throw "Python is not available. Install Python and ion-python package (uv pip install ion-python) to use Ion conversions."
        }
        catch {
            Write-Error "Failed to convert JSON to Ion: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert Ion to JSON
<#
.SYNOPSIS
    Converts Ion file to JSON format.
.DESCRIPTION
    Converts an Ion file (text or binary) to JSON format.
    Ion is a richly-typed, self-describing, hierarchical data serialization format.
    Requires Python and the ion-python package to be installed.
.PARAMETER InputPath
    The path to the Ion file (.ion for text, .10n for binary).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-IonToJson -InputPath 'data.ion'
    
    Converts data.ion to data.json.
.OUTPUTS
    System.String
    Returns the path to the output JSON file.
#>
Set-Item -Path Function:Global:ConvertFrom-IonToJson -Value {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IonToJson @PSBoundParameters
} -Force
Set-Alias -Name ion-to-json -Value ConvertFrom-IonToJson -ErrorAction SilentlyContinue

# Convert JSON to Ion
<#
.SYNOPSIS
    Converts JSON file to Ion format.
.DESCRIPTION
    Converts a JSON file to Ion format (text or binary).
    Ion is a richly-typed, self-describing, hierarchical data serialization format.
    Requires Python and the ion-python package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Ion file. If not specified, uses input path with .ion extension.
.PARAMETER Binary
    If specified, creates binary Ion format (.10n) instead of text format (.ion).
.EXAMPLE
    ConvertTo-IonFromJson -InputPath 'data.json'
    
    Converts data.json to data.ion (text format).
.EXAMPLE
    ConvertTo-IonFromJson -InputPath 'data.json' -Binary
    
    Converts data.json to data.10n (binary format).
.OUTPUTS
    System.String
    Returns the path to the output Ion file.
#>
Set-Item -Path Function:Global:ConvertTo-IonFromJson -Value {
    param([string]$InputPath, [string]$OutputPath, [switch]$Binary)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IonFromJson @PSBoundParameters
} -Force
Set-Alias -Name json-to-ion -Value ConvertTo-IonFromJson -ErrorAction SilentlyContinue

