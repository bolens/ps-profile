# ===============================================
# TOML (Tom's Obvious, Minimal Language) conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes TOML format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for TOML (Tom's Obvious, Minimal Language) format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires PSToml module for TOML output conversions.
    
    Internal Dependencies:
    - helpers-xml.ps1: Provides Convert-JsonToXml for TOML to XML conversions
    - helpers-toon.ps1: Provides Convert-JsonToToon for TOML to TOON conversions
#>
function Initialize-FileConversion-Toml {
    # Ensure PSToml module is available for TOML output conversions
    if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
        if (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue) {
            Import-Module PSToml -ErrorAction SilentlyContinue
        }
    }

    # TOML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-TomlToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            if ($LASTEXITCODE -eq 0 -and $json) {
                $json | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.toml.to-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.toml.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            else {
                throw "yq command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert TOML to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.toml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-json] Output path: $OutputPath"
            }
            
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            
            $convStartTime = Get-Date
            $jsonObj = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-json] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.toml.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $pstomlAvailable = (Get-Module -Name PSToml -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    pstoml_available = $pstomlAvailable
                }
            }
            else {
                Write-Error "Failed to convert JSON to TOML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # TOML to YAML
    Set-Item -Path Function:Global:_ConvertFrom-TomlToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $yaml = & yq eval -P -p toml -o yaml '.' $InputPath 2>$null
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            if ($LASTEXITCODE -eq 0 -and $yaml) {
                $yaml | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.toml.to-yaml] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.toml.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            else {
                throw "yq command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert TOML to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ya?ml$', '.toml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-yaml] Output path: $OutputPath"
            }
            
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            
            $convStartTime = Get-Date
            $json = & yq eval -o=json $InputPath 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $json) {
                throw "yq command failed with exit code $LASTEXITCODE"
            }
            $jsonObj = $json | ConvertFrom-Json
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.toml.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $pstomlAvailable = (Get-Module -Name PSToml -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                    pstoml_available = $pstomlAvailable
                }
            }
            else {
                Write-Error "Failed to convert YAML to TOML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # TOML to TOON
    Set-Item -Path Function:Global:_ConvertFrom-TomlToToon -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.to-toon] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.toon'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-toon] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $jsonObj = $json | ConvertFrom-Json
                $toon = Convert-JsonToToon -JsonObject $jsonObj
                Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.toml.to-toon] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.toml.to-toon] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            else {
                throw "yq command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.to-toon' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert TOML to TOON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-toon] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.to-toon] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # TOON to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromToon -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.from-toon] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toon$', '.toml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-toon] Output path: $OutputPath"
            }
            
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            
            $convStartTime = Get-Date
            $toon = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = Convert-ToonToJson -ToonString $toon
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-toon] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.toml.from-toon] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $pstomlAvailable = (Get-Module -Name PSToml -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.from-toon' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    pstoml_available = $pstomlAvailable
                }
            }
            else {
                Write-Error "Failed to convert TOON to TOML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-toon] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.from-toon] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # TOML to XML
    Set-Item -Path Function:Global:_ConvertFrom-TomlToXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.to-xml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.xml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-xml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $jsonObj = $json | ConvertFrom-Json
                $xml = Convert-JsonToXml -JsonObject $jsonObj
                $xml.Save($OutputPath)
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.toml.to-xml] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.toml.to-xml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            else {
                throw "yq command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.to-xml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert TOML to XML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.to-xml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.to-xml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # XML to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.toml.from-xml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.xml$', '.toml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-xml] Output path: $OutputPath"
            }
            
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            
            $convStartTime = Get-Date
            $xml = [xml](Get-Content -LiteralPath $InputPath -Raw)
            $result = @{}
            $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement
            $jsonObj = [PSCustomObject]$result
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-xml] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.toml.from-xml] Root element: $($xml.DocumentElement.Name)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.toml.from-xml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Root element: $($xml.DocumentElement.Name)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $pstomlAvailable = (Get-Module -Name PSToml -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.toml.from-xml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    pstoml_available = $pstomlAvailable
                }
            }
            else {
                Write-Error "Failed to convert XML to TOML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.toml.from-xml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.toml.from-xml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert TOML to JSON
<#
.SYNOPSIS
    Converts TOML file to JSON format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to JSON format using yq.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-TomlToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToJson @PSBoundParameters
}
Set-Alias -Name toml-to-json -Value ConvertFrom-TomlToJson -ErrorAction SilentlyContinue

# Convert JSON to TOML
<#
.SYNOPSIS
    Converts JSON file to TOML format.
.DESCRIPTION
    Converts a JSON file to TOML (Tom's Obvious, Minimal Language) format using yq.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromJson @PSBoundParameters
}
Set-Alias -Name json-to-toml -Value ConvertTo-TomlFromJson -ErrorAction SilentlyContinue

# Convert TOML to YAML
<#
.SYNOPSIS
    Converts TOML file to YAML format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to YAML format using yq.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-TomlToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToYaml @PSBoundParameters
}
Set-Alias -Name toml-to-yaml -Value ConvertFrom-TomlToYaml -ErrorAction SilentlyContinue

# Convert YAML to TOML
<#
.SYNOPSIS
    Converts YAML file to TOML format.
.DESCRIPTION
    Converts a YAML file to TOML (Tom's Obvious, Minimal Language) format using yq.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-toml -Value ConvertTo-TomlFromYaml -ErrorAction SilentlyContinue

# Convert TOML to TOON
<#
.SYNOPSIS
    Converts TOML file to TOON format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to TOON (Token-Oriented Object Notation) format.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertFrom-TomlToToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToToon @PSBoundParameters
}
Set-Alias -Name toml-to-toon -Value ConvertFrom-TomlToToon -ErrorAction SilentlyContinue

# Convert TOON to TOML
<#
.SYNOPSIS
    Converts TOON file to TOML format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to TOML (Tom's Obvious, Minimal Language) format.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromToon @PSBoundParameters
}
Set-Alias -Name toon-to-toml -Value ConvertTo-TomlFromToon -ErrorAction SilentlyContinue

# Convert TOML to XML
<#
.SYNOPSIS
    Converts TOML file to XML format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to XML format.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-TomlToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToXml @PSBoundParameters
}
Set-Alias -Name toml-to-xml -Value ConvertFrom-TomlToXml -ErrorAction SilentlyContinue

# Convert XML to TOML
<#
.SYNOPSIS
    Converts XML file to TOML format.
.DESCRIPTION
    Converts an XML file to TOML (Tom's Obvious, Minimal Language) format.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromXml @PSBoundParameters
}
Set-Alias -Name xml-to-toml -Value ConvertTo-TomlFromXml -ErrorAction SilentlyContinue

