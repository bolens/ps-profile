# ===============================================
# SuperJSON conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes SuperJSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for SuperJSON format, which extends JSON to support additional types.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the superjson package.
#>
function Initialize-FileConversion-SuperJson {
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
    # JSON to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.superjson' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use SuperJSON conversions."
            }
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $nodeScript = @"
try {
    const superjson = require('superjson');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const serialized = superjson.serialize(data);
    console.log(JSON.stringify(serialized));
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: superjson package is not installed. Install it with: pnpm add -g superjson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "superjson-serialize-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                $result | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to SuperJSON: $_"
        }
    } -Force

    # SuperJSON to JSON
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use SuperJSON conversions."
            }
            $nodeScript = @"
try {
    const superjson = require('superjson');
    const fs = require('fs');
    const serialized = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const data = superjson.deserialize(serialized);
    console.log(JSON.stringify(data, null, 2));
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: superjson package is not installed. Install it with: pnpm add -g superjson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "superjson-deserialize-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                $result | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert SuperJSON to JSON: $_"
        }
    } -Force

    # SuperJSON to YAML
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToYaml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.yaml' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; if (-not (Get-Command yq -ErrorAction SilentlyContinue)) { throw "yq command not available" }; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; _ConvertFrom-SuperJsonToJson -InputPath $InputPath -OutputPath $tempJson; if (Test-Path $tempJson) { $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json; $jsonObj | ConvertTo-Json -Depth 100 | & yq eval -P | Out-File -FilePath $OutputPath -Encoding UTF8; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } } catch { Write-Error "Failed to convert SuperJSON to YAML: $_" } } -Force

    # YAML to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromYaml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ya?ml$', '.superjson' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; if (-not (Get-Command yq -ErrorAction SilentlyContinue)) { throw "yq command not available" }; $json = & yq eval -o=json $InputPath 2>$null; if ($LASTEXITCODE -eq 0 -and $json) { $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; $json | Set-Content -LiteralPath $tempJson -Encoding UTF8; _ConvertTo-SuperJsonFromJson -InputPath $tempJson -OutputPath $OutputPath; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } else { throw "yq command failed" } } catch { Write-Error "Failed to convert YAML to SuperJSON: $_" } } -Force

    # SuperJSON to TOON
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToToon -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.toon' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; _ConvertFrom-SuperJsonToJson -InputPath $InputPath -OutputPath $tempJson; $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json; $toon = Convert-JsonToToon -JsonObject $jsonObj; Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert SuperJSON to TOON: $_" } } -Force

    # TOON to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromToon -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toon$', '.superjson' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $toon = Get-Content -LiteralPath $InputPath -Raw; $jsonObj = Convert-ToonToJson -ToonString $toon; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; $jsonObj | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $tempJson -Encoding UTF8; _ConvertTo-SuperJsonFromJson -InputPath $tempJson -OutputPath $OutputPath; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert TOON to SuperJSON: $_" } } -Force

    # SuperJSON to TOML
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToToml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.toml' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; if (-not (Get-Command yq -ErrorAction SilentlyContinue)) { throw "yq command not available" }; if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) { throw "PSToml module is not available" }; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; _ConvertFrom-SuperJsonToJson -InputPath $InputPath -OutputPath $tempJson; $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json; $toml = $jsonObj | ConvertTo-Toml -Depth 100; if ($toml) { Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8 } else { throw "PSToml conversion failed" }; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert SuperJSON to TOML: $_" } } -Force

    # TOML to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromToml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toml$', '.superjson' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; if (-not (Get-Command yq -ErrorAction SilentlyContinue)) { throw "yq command not available" }; $json = & yq eval -o=json -p toml '.' $InputPath 2>$null; if ($LASTEXITCODE -eq 0 -and $json) { $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; $json | Set-Content -LiteralPath $tempJson -Encoding UTF8; _ConvertTo-SuperJsonFromJson -InputPath $tempJson -OutputPath $OutputPath; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } else { throw "yq command failed" } } catch { Write-Error "Failed to convert TOML to SuperJSON: $_" } } -Force

    # SuperJSON to XML
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToXml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.xml' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; _ConvertFrom-SuperJsonToJson -InputPath $InputPath -OutputPath $tempJson; $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json; $xml = Convert-JsonToXml -JsonObject $jsonObj; $xml.Save($OutputPath); Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert SuperJSON to XML: $_" } } -Force

    # XML to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromXml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.xml$', '.superjson' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $xml = [xml](Get-Content -LiteralPath $InputPath -Raw); $result = @{}; $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement; $jsonObj = [PSCustomObject]$result; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; $jsonObj | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $tempJson -Encoding UTF8; _ConvertTo-SuperJsonFromJson -InputPath $tempJson -OutputPath $OutputPath; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert XML to SuperJSON: $_" } } -Force

    # SuperJSON to CSV
    Set-Item -Path Function:Global:_ConvertFrom-SuperJsonToCsv -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.superjson$', '.csv' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; _ConvertFrom-SuperJsonToJson -InputPath $InputPath -OutputPath $tempJson; $data = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $OutputPath } elseif ($data -is [PSCustomObject]) { @($data) | Export-Csv -NoTypeInformation -Path $OutputPath } else { throw "SuperJSON must represent an array of objects or a single object" }; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert SuperJSON to CSV: $_" } } -Force

    # CSV to SuperJSON
    Set-Item -Path Function:Global:_ConvertTo-SuperJsonFromCsv -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.csv$', '.superjson' }; if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is not available" }; $data = Import-Csv -Path $InputPath; $tempJson = $env:TEMP + "\temp-$(Get-Random).json"; $data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tempJson -Encoding UTF8; _ConvertTo-SuperJsonFromJson -InputPath $tempJson -OutputPath $OutputPath; Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue } catch { Write-Error "Failed to convert CSV to SuperJSON: $_" } } -Force
}

# Public functions and aliases
# Convert JSON to SuperJSON
<#
.SYNOPSIS
    Converts JSON file to SuperJSON format.
.DESCRIPTION
    Converts a JSON file to SuperJSON format, which extends JSON to support additional types like Date, Map, Set, etc.
    Requires Node.js and the superjson package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromJson @PSBoundParameters
}
Set-Alias -Name json-to-superjson -Value ConvertTo-SuperJsonFromJson -ErrorAction SilentlyContinue

# Convert SuperJSON to JSON
<#
.SYNOPSIS
    Converts SuperJSON file to JSON format.
.DESCRIPTION
    Converts a SuperJSON file back to standard JSON format.
    Requires Node.js and the superjson package to be installed.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-SuperJsonToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToJson @PSBoundParameters
}
Set-Alias -Name superjson-to-json -Value ConvertFrom-SuperJsonToJson -ErrorAction SilentlyContinue

# Convert SuperJSON to YAML
<#
.SYNOPSIS
    Converts SuperJSON file to YAML format.
.DESCRIPTION
    Converts a SuperJSON file to YAML format.
    Requires Node.js, superjson package, and yq command.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-SuperJsonToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToYaml @PSBoundParameters
}
Set-Alias -Name superjson-to-yaml -Value ConvertFrom-SuperJsonToYaml -ErrorAction SilentlyContinue

# Convert YAML to SuperJSON
<#
.SYNOPSIS
    Converts YAML file to SuperJSON format.
.DESCRIPTION
    Converts a YAML file to SuperJSON format.
    Requires Node.js, superjson package, and yq command.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-superjson -Value ConvertTo-SuperJsonFromYaml -ErrorAction SilentlyContinue

# Convert SuperJSON to TOON
<#
.SYNOPSIS
    Converts SuperJSON file to TOON format.
.DESCRIPTION
    Converts a SuperJSON file to TOON (Token-Oriented Object Notation) format.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertFrom-SuperJsonToToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToToon @PSBoundParameters
}
Set-Alias -Name superjson-to-toon -Value ConvertFrom-SuperJsonToToon -ErrorAction SilentlyContinue

# Convert TOON to SuperJSON
<#
.SYNOPSIS
    Converts TOON file to SuperJSON format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to SuperJSON format.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromToon @PSBoundParameters
}
Set-Alias -Name toon-to-superjson -Value ConvertTo-SuperJsonFromToon -ErrorAction SilentlyContinue

# Convert SuperJSON to TOML
<#
.SYNOPSIS
    Converts SuperJSON file to TOML format.
.DESCRIPTION
    Converts a SuperJSON file to TOML (Tom's Obvious, Minimal Language) format.
    Requires Node.js, superjson package, yq command, and PSToml module.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertFrom-SuperJsonToToml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToToml @PSBoundParameters
}
Set-Alias -Name superjson-to-toml -Value ConvertFrom-SuperJsonToToml -ErrorAction SilentlyContinue

# Convert TOML to SuperJSON
<#
.SYNOPSIS
    Converts TOML file to SuperJSON format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to SuperJSON format.
    Requires Node.js, superjson package, and yq command.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromToml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromToml @PSBoundParameters
}
Set-Alias -Name toml-to-superjson -Value ConvertTo-SuperJsonFromToml -ErrorAction SilentlyContinue

# Convert SuperJSON to XML
<#
.SYNOPSIS
    Converts SuperJSON file to XML format.
.DESCRIPTION
    Converts a SuperJSON file to XML format.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-SuperJsonToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToXml @PSBoundParameters
}
Set-Alias -Name superjson-to-xml -Value ConvertFrom-SuperJsonToXml -ErrorAction SilentlyContinue

# Convert XML to SuperJSON
<#
.SYNOPSIS
    Converts XML file to SuperJSON format.
.DESCRIPTION
    Converts an XML file to SuperJSON format.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromXml @PSBoundParameters
}
Set-Alias -Name xml-to-superjson -Value ConvertTo-SuperJsonFromXml -ErrorAction SilentlyContinue

# Convert SuperJSON to CSV
<#
.SYNOPSIS
    Converts SuperJSON file to CSV format.
.DESCRIPTION
    Converts a SuperJSON file to CSV format. The SuperJSON must represent an array of objects or a single object.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the SuperJSON file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-SuperJsonToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SuperJsonToCsv @PSBoundParameters
}
Set-Alias -Name superjson-to-csv -Value ConvertFrom-SuperJsonToCsv -ErrorAction SilentlyContinue

# Convert CSV to SuperJSON
<#
.SYNOPSIS
    Converts CSV file to SuperJSON format.
.DESCRIPTION
    Converts a CSV file to SuperJSON format.
    Requires Node.js and superjson package.
.PARAMETER InputPath
    The path to the CSV file.
.PARAMETER OutputPath
    The path for the output SuperJSON file. If not specified, uses input path with .superjson extension.
#>
function ConvertTo-SuperJsonFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SuperJsonFromCsv @PSBoundParameters
}
Set-Alias -Name csv-to-superjson -Value ConvertTo-SuperJsonFromCsv -ErrorAction SilentlyContinue

