# ===============================================
# TestModuleLoading.ps1
# Module loading utilities for test environment
# ===============================================

#region Core Module Loading Functions

<#
.SYNOPSIS
    Loads a test module and promotes its functions to global scope.
.DESCRIPTION
    Dot-sources a module file, promotes the initialization function to global scope,
    and promotes user-facing functions matching specified patterns to global scope.
    This helper reduces code duplication in module loading functions.
.PARAMETER ModulePath
    Full path to the module file to load.
.PARAMETER InitFunctionName
    Name of the initialization function to promote (optional).
.PARAMETER FunctionPatterns
    Array of regex patterns to match user-facing functions to promote.
    Default patterns match common function prefixes.
.PARAMETER ModuleName
    Display name for error messages (defaults to filename).
.EXAMPLE
    Import-TestModule -ModulePath $path -InitFunctionName 'Initialize-MyModule' -FunctionPatterns @('^Convert', '^Format')
    Loads a module and promotes its functions.
#>
function Import-TestModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [string]$InitFunctionName,

        [string[]]$FunctionPatterns = @('^(Convert|Format|Get|New|Test|Invoke|Set|Add|Remove|Clear|Decode|Encode|Compare|Merge|Resize)'),

        [string]$ModuleName
    )

    if (-not $ModuleName) {
        $ModuleName = [System.IO.Path]::GetFileName($ModulePath)
    }

    if ($null -eq $ModulePath -or [string]::IsNullOrWhiteSpace($ModulePath)) {
        Write-Warning "Module path is null or empty"
        return
    }
    if (-not (Test-Path -LiteralPath $ModulePath)) {
        Write-Warning "Module file not found: $ModulePath"
        return
    }

    try {
        # Dot-source the module
        . $ModulePath

        # Promote initialization function to global scope if specified
        if ($InitFunctionName) {
            $func = Get-Command $InitFunctionName -ErrorAction SilentlyContinue -All
            if ($func) {
                Set-Item -Path "Function:\global:$InitFunctionName" -Value $func.ScriptBlock -ErrorAction SilentlyContinue -Force
            }
        }

        # Promote user-facing functions to global scope
        # Check both local and global scope for functions that match patterns
        $allFuncs = @()
        $allFuncs += Get-ChildItem Function: | Where-Object {
            $funcName = $_.Name
            $shouldPromote = $false

            # Check if function matches any pattern
            foreach ($pattern in $FunctionPatterns) {
                if ($funcName -match $pattern) {
                    # Exclude initialization functions
                    if ($funcName -notmatch '^Initialize-') {
                        $shouldPromote = $true
                        break
                    }
                }
            }

            return $shouldPromote
        }

        # Also check if functions already exist in global scope (created with Function:Global:)
        foreach ($pattern in $FunctionPatterns) {
            $globalFuncs = Get-ChildItem Function: | Where-Object {
                $funcName = $_.Name
                if ($funcName -match $pattern -and $funcName -notmatch '^Initialize-') {
                    # Check if it's already in global scope
                    $globalCmd = Get-Command "global:$funcName" -ErrorAction SilentlyContinue
                    if ($globalCmd -and $globalCmd.CommandType -eq 'Function') {
                        return $false  # Already in global, don't add to promotion list
                    }
                    return $true
                }
                return $false
            }
            # Functions created with Function:Global: are already accessible, so we just need to ensure they're found
        }

        foreach ($f in $allFuncs) {
            if (-not (Get-Command "global:$($f.Name)" -ErrorAction SilentlyContinue)) {
                Set-Item -Path "Function:\global:$($f.Name)" -Value $f.ScriptBlock -ErrorAction SilentlyContinue -Force
            }
        }
    }
    catch {
        Write-Warning "Failed to load $ModuleName : $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Loads a group of modules from a directory using a configuration.
.DESCRIPTION
    Generic helper function that loads multiple modules from a directory based on
    a configuration object. Each module can specify its init function and function patterns.
.PARAMETER BaseDir
    Base directory containing the modules.
.PARAMETER SubDir
    Subdirectory name (optional, can be empty string for base directory).
.PARAMETER ModuleConfig
    Hashtable mapping filenames to init function names, or array of filenames.
.PARAMETER DefaultFunctionPatterns
    Default function patterns to use if not specified per-module.
.PARAMETER CustomPatterns
    Hashtable mapping specific filenames to custom function patterns.
.EXAMPLE
    $config = @{ 'module.ps1' = 'Initialize-Module' }
    Import-ModuleGroup -BaseDir $baseDir -SubDir 'subdir' -ModuleConfig $config
#>
function Import-ModuleGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseDir,

        [string]$SubDir = '',

        [Parameter(Mandatory)]
        [object]$ModuleConfig,

        [string[]]$DefaultFunctionPatterns = @('^(Convert|Format)'),

        [hashtable]$CustomPatterns = @{},

        [switch]$ParallelLoad,

        [string[]]$SelectiveModules
    )

    $targetDir = if ($SubDir) {
        Join-Path $BaseDir $SubDir
    }
    else {
        $BaseDir
    }

    if ($null -eq $targetDir -or [string]::IsNullOrWhiteSpace($targetDir)) {
        Write-Warning "Target directory is null or empty"
        return
    }
    if (-not (Test-Path -LiteralPath $targetDir)) {
        Write-Warning "Module directory not found: $targetDir"
        return
    }

    # Handle both hashtable (with init functions) and array (without init functions)
    $modules = if ($ModuleConfig -is [hashtable]) {
        $ModuleConfig.Keys
    }
    else {
        $ModuleConfig
    }

    # Filter to selective modules if specified
    if ($SelectiveModules) {
        $modules = $modules | Where-Object { $SelectiveModules -contains $_ }
    }

    # If no modules to load, return early
    if ($modules.Count -eq 0) {
        return
    }

    # Prepare module loading tasks
    $loadTasks = @()
    foreach ($file in $modules) {
        $path = Join-Path $targetDir $file
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Warning "Module file not found: $path"
            continue
        }

        $initFunction = if ($ModuleConfig -is [hashtable]) {
            $ModuleConfig[$file]
        }
        else {
            $null
        }

        $patterns = if ($CustomPatterns.ContainsKey($file)) {
            $CustomPatterns[$file]
        }
        else {
            $DefaultFunctionPatterns
        }

        $params = @{
            ModulePath       = $path
            FunctionPatterns = $patterns
        }

        if ($initFunction) {
            $params['InitFunctionName'] = $initFunction
        }

        $loadTasks += @{
            Params = $params
            File   = $file
        }
    }

    # Load modules sequentially (parallel loading via jobs doesn't work for session state)
    # Selective loading via -SelectiveModules is the real performance win
    foreach ($task in $loadTasks) {
        $params = $task.Params
        Import-TestModule @params
    }
}

#endregion

#region Module Configuration Data

<#
.SYNOPSIS
    Gets the configuration for conversion module helpers.
#>
function Get-ConversionHelpersConfig {
    return @('helpers-xml.ps1', 'helpers-toon.ps1')
}

<#
.SYNOPSIS
    Gets the configuration for data conversion core modules.
#>
function Get-DataCoreModulesConfig {
    return @{
        # Core basic modules (files are in data/core/)
        'json.ps1'           = 'Initialize-FileConversion-CoreBasicJson'
        'yaml.ps1'           = 'Initialize-FileConversion-CoreBasicYaml'
        'csv.ps1'            = 'Initialize-FileConversion-CoreBasicCsv'
        'xml.ps1'            = 'Initialize-FileConversion-CoreBasicXml'
        'json-extended.ps1'  = 'Initialize-FileConversion-CoreJsonExtended'
        'text-gaps.ps1'      = 'Initialize-FileConversion-CoreTextGaps'
        # Base64 module (file is in data/base64/)
        'base64.ps1'         = 'Initialize-FileConversion-CoreBasicBase64'
        # Encoding module (file is in data/encoding/)
        'encoding.ps1'       = 'Initialize-FileConversion-CoreEncoding'
        # Compression modules (files are in data/compression/)
        'gzip.ps1'           = 'Initialize-FileConversion-CoreCompressionGzip'
        'brotli.ps1'         = 'Initialize-FileConversion-CoreCompressionBrotli'
        'zstd.ps1'           = 'Initialize-FileConversion-CoreCompressionZstd'
        'lz4.ps1'            = 'Initialize-FileConversion-CoreCompressionLz4'
        'snappy.ps1'         = 'Initialize-FileConversion-CoreCompressionSnappy'
        'xz.ps1'             = 'Initialize-FileConversion-CoreCompressionXz'
        # Time modules (files are in data/time/)
        'unix.ps1'           = 'Initialize-FileConversion-CoreTimeUnix'
        'iso8601.ps1'        = 'Initialize-FileConversion-CoreTimeIso8601'
        'rfc3339.ps1'        = 'Initialize-FileConversion-CoreTimeRfc3339'
        'human-readable.ps1' = 'Initialize-FileConversion-CoreTimeHumanReadable'
        'timezone.ps1'       = 'Initialize-FileConversion-CoreTimeTimezone'
        'duration.ps1'       = 'Initialize-FileConversion-CoreTimeDuration'
        # Encoding sub-modules (files are in data/encoding/)
        'uuid.ps1'           = 'Initialize-FileConversion-CoreEncodingUuid'
        'guid.ps1'           = 'Initialize-FileConversion-CoreEncodingGuid'
        # Units modules (files are in data/units/)
        'datasize.ps1'       = 'Initialize-FileConversion-CoreUnitsDataSize'
        'length.ps1'         = 'Initialize-FileConversion-CoreUnitsLength'
        'weight.ps1'         = 'Initialize-FileConversion-CoreUnitsWeight'
        'temperature.ps1'    = 'Initialize-FileConversion-CoreUnitsTemperature'
        'volume.ps1'         = 'Initialize-FileConversion-CoreUnitsVolume'
        'energy.ps1'         = 'Initialize-FileConversion-CoreUnitsEnergy'
        'speed.ps1'          = 'Initialize-FileConversion-CoreUnitsSpeed'
        'area.ps1'           = 'Initialize-FileConversion-CoreUnitsArea'
        'pressure.ps1'       = 'Initialize-FileConversion-CoreUnitsPressure'
        'angle.ps1'          = 'Initialize-FileConversion-CoreUnitsAngle'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion encoding sub-modules.
#>
function Get-DataEncodingSubModulesConfig {
    # Encoding sub-modules are in data/encoding/ directory
    # These files don't have the 'core-encoding-' prefix
    return @(
        'roman.ps1',
        'modhex.ps1',
        'ascii.ps1',
        'hex.ps1',
        'binary.ps1',
        'numeric.ps1',
        'base32.ps1',
        'base36.ps1',
        'base58.ps1',
        'base62.ps1',
        'base85.ps1',
        'z85.ps1',
        'base91.ps1',
        'utf16-utf32.ps1',
        'rot.ps1',
        'morse.ps1',
        'url.ps1'
    )
}

<#
.SYNOPSIS
    Gets the configuration for data conversion structured modules.
#>
function Get-DataStructuredModulesConfig {
    return @{
        'toon.ps1'       = 'Initialize-FileConversion-Toon'
        'toml.ps1'       = 'Initialize-FileConversion-Toml'
        'superjson.ps1'  = 'Initialize-FileConversion-SuperJson'
        'ini.ps1'        = 'Initialize-FileConversion-Ini'
        'properties.ps1' = 'Initialize-FileConversion-Properties'
        'sexpr.ps1'      = 'Initialize-FileConversion-Sexpr'
        'edifact.ps1'    = 'Initialize-FileConversion-Edifact'
        'asn1.ps1'       = 'Initialize-FileConversion-Asn1'
        'cfg.ps1'        = 'Initialize-FileConversion-Cfg'
        'hjson.ps1'      = 'Initialize-FileConversion-Hjson'
        'jsonc.ps1'      = 'Initialize-FileConversion-Jsonc'
        'env.ps1'        = 'Initialize-FileConversion-Env'
        'edn.ps1'        = 'Initialize-FileConversion-Edn'
        'ubjson.ps1'     = 'Initialize-FileConversion-Ubjson'
        'ion.ps1'        = 'Initialize-FileConversion-Ion'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion binary modules.
#>
function Get-DataBinaryModulesConfig {
    return @{
        'binary-schema-protobuf.ps1'    = 'Initialize-FileConversion-BinarySchemaProtobuf'
        'binary-schema-avro.ps1'        = 'Initialize-FileConversion-BinarySchemaAvro'
        'binary-schema-flatbuffers.ps1' = 'Initialize-FileConversion-BinarySchemaFlatBuffers'
        'binary-schema-thrift.ps1'      = 'Initialize-FileConversion-BinarySchemaThrift'
        'binary-simple.ps1'             = 'Initialize-FileConversion-BinarySimple'
        'binary-direct.ps1'             = 'Initialize-FileConversion-BinaryDirect'
        'binary-protocol-capnp.ps1'     = 'Initialize-FileConversion-BinaryProtocolCapnp'
        'binary-protocol-orc.ps1'       = 'Initialize-FileConversion-BinaryProtocolOrc'
        'binary-protocol-iceberg.ps1'   = 'Initialize-FileConversion-BinaryProtocolIceberg'
        'binary-protocol-delta.ps1'     = 'Initialize-FileConversion-BinaryProtocolDelta'
        'binary-to-text.ps1'            = 'Initialize-FileConversion-BinaryToText'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion columnar modules.
#>
function Get-DataColumnarModulesConfig {
    return @{
        'columnar-parquet.ps1' = 'Initialize-FileConversion-ColumnarParquet'
        'columnar-arrow.ps1'   = 'Initialize-FileConversion-ColumnarArrow'
        'columnar-direct.ps1'  = 'Initialize-FileConversion-ColumnarDirect'
        'columnar-to-csv.ps1'  = 'Initialize-FileConversion-ColumnarToCsv'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion scientific modules.
#>
function Get-DataScientificModulesConfig {
    return @{
        'scientific-hdf5.ps1'        = 'Initialize-FileConversion-ScientificHdf5'
        'scientific-netcdf.ps1'      = 'Initialize-FileConversion-ScientificNetCdf'
        'scientific-direct.ps1'      = 'Initialize-FileConversion-ScientificDirect'
        'scientific-to-columnar.ps1' = 'Initialize-FileConversion-ScientificToColumnar'
        'scientific-fits.ps1'        = 'Initialize-FileConversion-ScientificFits'
        'scientific-matlab.ps1'      = 'Initialize-FileConversion-ScientificMatlab'
        'scientific-sas.ps1'         = 'Initialize-FileConversion-ScientificSas'
        'scientific-spss.ps1'        = 'Initialize-FileConversion-ScientificSpss'
        'scientific-stata.ps1'       = 'Initialize-FileConversion-ScientificStata'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion database modules.
#>
function Get-DataDatabaseModulesConfig {
    return @{
        'database-sqlite.ps1'   = 'Initialize-FileConversion-DatabaseSqlite'
        'database-sql-dump.ps1' = 'Initialize-FileConversion-DatabaseSqlDump'
        'database-dbf.ps1'      = 'Initialize-FileConversion-DatabaseDbf'
        'database-access.ps1'   = 'Initialize-FileConversion-DatabaseAccess'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion network modules.
#>
function Get-DataNetworkModulesConfig {
    return @{
        'network-url-uri.ps1'      = 'Initialize-FileConversion-NetworkUrlUri'
        'network-query-string.ps1' = 'Initialize-FileConversion-NetworkQueryString'
        'network-http-headers.ps1' = 'Initialize-FileConversion-NetworkHttpHeaders'
        'network-mime-types.ps1'   = 'Initialize-FileConversion-NetworkMimeTypes'
    }
}

<#
.SYNOPSIS
    Gets the configuration for data conversion digest modules.
#>
function Get-DataDigestModulesConfig {
    return @{
        'digest.ps1' = 'Initialize-FileConversion-Digest'
    }
}

<#
.SYNOPSIS
    Gets the configuration for document conversion modules.
#>
function Get-DocumentModulesConfig {
    return @{
        'document-markdown.ps1'         = 'Initialize-FileConversion-DocumentMarkdown'
        'document-latex.ps1'            = 'Initialize-FileConversion-DocumentLaTeX'
        'document-rst.ps1'              = 'Initialize-FileConversion-DocumentRst'
        'document-textile.ps1'          = 'Initialize-FileConversion-DocumentTextile'
        'document-fb2.ps1'              = 'Initialize-FileConversion-DocumentFb2'
        'document-djvu.ps1'             = 'Initialize-FileConversion-DocumentDjvu'
        'document-common-html.ps1'      = 'Initialize-FileConversion-DocumentCommonHtml'
        'document-common-docx.ps1'      = 'Initialize-FileConversion-DocumentCommonDocx'
        'document-common-epub.ps1'      = 'Initialize-FileConversion-DocumentCommonEpub'
        'document-office-odt.ps1'       = 'Initialize-FileConversion-DocumentOfficeOdt'
        'document-office-ods.ps1'       = 'Initialize-FileConversion-DocumentOfficeOds'
        'document-office-odp.ps1'       = 'Initialize-FileConversion-DocumentOfficeOdp'
        'document-office-rtf.ps1'       = 'Initialize-FileConversion-DocumentOfficeRtf'
        'document-office-excel.ps1'     = 'Initialize-FileConversion-DocumentOfficeExcel'
        'document-office-plaintext.ps1' = 'Initialize-FileConversion-DocumentOfficePlaintext'
        'document-office-orgmode.ps1'   = 'Initialize-FileConversion-DocumentOfficeOrgmode'
        'document-office-asciidoc.ps1'  = 'Initialize-FileConversion-DocumentOfficeAsciidoc'
        'document-ebook-mobi.ps1'       = 'Initialize-FileConversion-DocumentEbookMobi'
    }
}

<#
.SYNOPSIS
    Gets the configuration for media conversion modules.
#>
function Get-MediaModulesConfig {
    return @{
        'media-images.ps1' = 'Initialize-FileConversion-MediaImages'
        'media-audio.ps1'  = 'Initialize-FileConversion-MediaAudio'
        'media-video.ps1'  = 'Initialize-FileConversion-MediaVideo'
        'media-pdf.ps1'    = 'Initialize-FileConversion-MediaPdf'
    }
}

<#
.SYNOPSIS
    Gets the configuration for media image conversion modules.
#>
function Get-MediaImageModulesConfig {
    return @{
        'common.ps1' = 'Initialize-FileConversion-MediaImagesCommon'
        'webp.ps1'   = 'Initialize-FileConversion-MediaImagesWebp'
        'avif.ps1'   = 'Initialize-FileConversion-MediaImagesAvif'
        'svg.ps1'    = 'Initialize-FileConversion-MediaImagesSvg'
        'heic.ps1'   = 'Initialize-FileConversion-MediaImagesHeic'
        'ico.ps1'    = 'Initialize-FileConversion-MediaImagesIco'
        'bmp.ps1'    = 'Initialize-FileConversion-MediaImagesBmp'
        'tiff.ps1'   = 'Initialize-FileConversion-MediaImagesTiff'
    }
}

<#
.SYNOPSIS
    Gets the configuration for media audio conversion modules.
#>
function Get-MediaAudioModulesConfig {
    return @{
        'common.ps1' = 'Initialize-FileConversion-MediaAudioCommon'
        'flac.ps1'   = 'Initialize-FileConversion-MediaAudioFlac'
        'ogg.ps1'    = 'Initialize-FileConversion-MediaAudioOgg'
        'wav.ps1'    = 'Initialize-FileConversion-MediaAudioWav'
        'aac.ps1'    = 'Initialize-FileConversion-MediaAudioAac'
        'opus.ps1'   = 'Initialize-FileConversion-MediaAudioOpus'
        'video.ps1'  = 'Initialize-FileConversion-MediaAudioVideo'
    }
}

<#
.SYNOPSIS
    Gets the configuration for specialized conversion modules.
#>
function Get-SpecializedModulesConfig {
    return @{
        'specialized.ps1' = 'Initialize-FileConversion-Specialized'
    }
}

<#
.SYNOPSIS
    Gets the configuration for media color conversion modules.
#>
function Get-MediaColorModulesConfig {
    return @{
        'media-colors-named.ps1'   = 'Initialize-FileConversion-MediaColorsNamed'
        'media-colors-hex.ps1'     = 'Initialize-FileConversion-MediaColorsHex'
        'media-colors-hsl.ps1'     = 'Initialize-FileConversion-MediaColorsHsl'
        'media-colors-hwb.ps1'     = 'Initialize-FileConversion-MediaColorsHwb'
        'media-colors-cmyk.ps1'    = 'Initialize-FileConversion-MediaColorsCmyk'
        'media-colors-ncol.ps1'    = 'Initialize-FileConversion-MediaColorsNcol'
        'media-colors-lab.ps1'     = 'Initialize-FileConversion-MediaColorsLab'
        'media-colors-oklab.ps1'   = 'Initialize-FileConversion-MediaColorsOklab'
        'media-colors-lch.ps1'     = 'Initialize-FileConversion-MediaColorsLch'
        'media-colors-oklch.ps1'   = 'Initialize-FileConversion-MediaColorsOklch'
        'media-colors-parse.ps1'   = 'Initialize-FileConversion-MediaColorsParse'
        'media-colors-convert.ps1' = 'Initialize-FileConversion-MediaColorsConvert'
    }
}

<#
.SYNOPSIS
    Gets the configuration for dev-tools encoding modules.
#>
function Get-DevToolsEncodingModulesConfig {
    return @{
        'base-encoding.ps1' = 'Initialize-DevTools-BaseEncoding'
        'encoding.ps1'      = 'Initialize-DevTools-Encoding'
    }
}

<#
.SYNOPSIS
    Gets the configuration for dev-tools crypto modules.
#>
function Get-DevToolsCryptoModulesConfig {
    return @{
        'hash.ps1' = 'Initialize-DevTools-Hash'
        'jwt.ps1'  = 'Initialize-DevTools-Jwt'
    }
}

<#
.SYNOPSIS
    Gets the configuration for dev-tools format modules.
#>
function Get-DevToolsFormatModulesConfig {
    return @{
        'diff.ps1'  = 'Initialize-DevTools-Diff'
        'regex.ps1' = 'Initialize-DevTools-Regex'
    }
}

<#
.SYNOPSIS
    Gets the configuration for dev-tools QR code modules.
#>
function Get-DevToolsQrCodeModulesConfig {
    return @{
        'qrcode.ps1'               = 'Initialize-DevTools-QrCode'
        'qrcode-communication.ps1' = 'Initialize-DevTools-QrCode'
        'qrcode-formats.ps1'       = 'Initialize-DevTools-QrCode'
        'qrcode-specialized.ps1'   = 'Initialize-DevTools-QrCode'
    }
}

<#
.SYNOPSIS
    Gets the configuration for dev-tools data modules.
#>
function Get-DevToolsDataModulesConfig {
    return @{
        'timestamp.ps1'   = 'Initialize-DevTools-Timestamp'
        'uuid.ps1'        = 'Initialize-DevTools-Uuid'
        'lorem.ps1'       = 'Initialize-DevTools-Lorem'
        'number-base.ps1' = 'Initialize-DevTools-NumberBase'
        'units.ps1'       = 'Initialize-DevTools-Units'
    }
}

#endregion

#region Conversion Modules Loading

<#
.SYNOPSIS
    Loads conversion module helpers.
.DESCRIPTION
    Loads helper modules that are required by other conversion modules.
.PARAMETER ConversionModulesDir
    Base directory for conversion modules.
#>
function Import-ConversionHelpers {
    param(
        [Parameter(Mandatory)]
        [string]$ConversionModulesDir
    )

    $helpersDir = Join-Path $ConversionModulesDir 'helpers'
    $helperFiles = Get-ConversionHelpersConfig

    Import-ModuleGroup -BaseDir $helpersDir -ModuleConfig $helperFiles -DefaultFunctionPatterns @('^.*')
}

<#
.SYNOPSIS
    Loads data conversion modules.
.DESCRIPTION
    Loads all data conversion modules including core, structured, binary, columnar, and scientific modules.
.PARAMETER ConversionModulesDir
    Base directory for conversion modules.
#>
function Import-DataConversionModules {
    param(
        [Parameter(Mandatory)]
        [string]$ConversionModulesDir,

        [switch]$ParallelLoad,

        [string[]]$SelectiveModules
    )

    $dataDir = Join-Path $ConversionModulesDir 'data'

    # If SelectiveModules is specified, only load minimal core dependencies
    # These are often required by structured modules and Ensure-FileConversion-Data
    if ($SelectiveModules -and $SelectiveModules.Count -gt 0) {
        # Load minimal core dependencies needed by most structured modules and Ensure-FileConversion-Data
        $coreDir = Join-Path $dataDir 'core'
        $minimalCoreModules = @{
            'json.ps1'          = 'Initialize-FileConversion-CoreBasicJson'
            'yaml.ps1'          = 'Initialize-FileConversion-CoreBasicYaml'
            'xml.ps1'           = 'Initialize-FileConversion-CoreBasicXml'
            'csv.ps1'           = 'Initialize-FileConversion-CoreBasicCsv'
            'json-extended.ps1' = 'Initialize-FileConversion-CoreJsonExtended'
            'text-gaps.ps1'     = 'Initialize-FileConversion-CoreTextGaps'
        }
        Import-ModuleGroup -BaseDir $coreDir -ModuleConfig $minimalCoreModules -DefaultFunctionPatterns @('^(Convert|Format)')
        
        # Base64 module is commonly needed
        $base64Dir = Join-Path $dataDir 'base64'
        Import-ModuleGroup -BaseDir $base64Dir -ModuleConfig @{ 'base64.ps1' = 'Initialize-FileConversion-CoreBasicBase64' } -DefaultFunctionPatterns @('^(Convert|Format)')
        
        # Encoding module is commonly needed
        $encodingDir = Join-Path $dataDir 'encoding'
        Import-ModuleGroup -BaseDir $encodingDir -ModuleConfig @{ 'encoding.ps1' = 'Initialize-FileConversion-CoreEncoding' } -DefaultFunctionPatterns @('^(Convert|Format)')
    }
    # If SelectiveModules is NOT specified, load all core modules
    elseif (-not $SelectiveModules -or $SelectiveModules.Count -eq 0) {
        # Core modules - load these first as they're required by Ensure-FileConversion-Data
        $coreDir = Join-Path $dataDir 'core'
        $coreModules = Get-DataCoreModulesConfig
        
        # Load core modules from their respective directories
        # Core basic modules (json, yaml, csv, xml, json-extended, text-gaps) are in data/core/
        $coreBasicModules = @{
            'json.ps1'          = 'Initialize-FileConversion-CoreBasicJson'
            'yaml.ps1'          = 'Initialize-FileConversion-CoreBasicYaml'
            'csv.ps1'           = 'Initialize-FileConversion-CoreBasicCsv'
            'xml.ps1'           = 'Initialize-FileConversion-CoreBasicXml'
            'json-extended.ps1' = 'Initialize-FileConversion-CoreJsonExtended'
            'text-gaps.ps1'     = 'Initialize-FileConversion-CoreTextGaps'
        }
        $coreCustomPatterns = @{
            'datasize.ps1' = @('^(Convert|ConvertFrom|ConvertTo)-')
        }
        Import-ModuleGroup -BaseDir $coreDir -ModuleConfig $coreBasicModules -DefaultFunctionPatterns @('^(Convert|Format)') -CustomPatterns $coreCustomPatterns
    
        # Base64 module is in data/base64/
        $base64Dir = Join-Path $dataDir 'base64'
        Import-ModuleGroup -BaseDir $base64Dir -ModuleConfig @{ 'base64.ps1' = 'Initialize-FileConversion-CoreBasicBase64' } -DefaultFunctionPatterns @('^(Convert|Format)')
    
        # Encoding module is in data/encoding/
        $encodingDir = Join-Path $dataDir 'encoding'
        Import-ModuleGroup -BaseDir $encodingDir -ModuleConfig @{ 'encoding.ps1' = 'Initialize-FileConversion-CoreEncoding' } -DefaultFunctionPatterns @('^(Convert|Format)')
    
        # Compression modules are in data/compression/
        $compressionDir = Join-Path $dataDir 'compression'
        $compressionModules = @{
            'gzip.ps1'   = 'Initialize-FileConversion-CoreCompressionGzip'
            'brotli.ps1' = 'Initialize-FileConversion-CoreCompressionBrotli'
            'zstd.ps1'   = 'Initialize-FileConversion-CoreCompressionZstd'
            'lz4.ps1'    = 'Initialize-FileConversion-CoreCompressionLz4'
            'snappy.ps1' = 'Initialize-FileConversion-CoreCompressionSnappy'
            'xz.ps1'     = 'Initialize-FileConversion-CoreCompressionXz'
        }
        Import-ModuleGroup -BaseDir $compressionDir -ModuleConfig $compressionModules -DefaultFunctionPatterns @('^(Convert|Format)')
    
        # Time modules are in data/time/
        $timeDir = Join-Path $dataDir 'time'
        $timeModules = @{
            'unix.ps1'           = 'Initialize-FileConversion-CoreTimeUnix'
            'iso8601.ps1'        = 'Initialize-FileConversion-CoreTimeIso8601'
            'rfc3339.ps1'        = 'Initialize-FileConversion-CoreTimeRfc3339'
            'human-readable.ps1' = 'Initialize-FileConversion-CoreTimeHumanReadable'
            'timezone.ps1'       = 'Initialize-FileConversion-CoreTimeTimezone'
            'duration.ps1'       = 'Initialize-FileConversion-CoreTimeDuration'
        }
        Import-ModuleGroup -BaseDir $timeDir -ModuleConfig $timeModules -DefaultFunctionPatterns @('^(Convert|Format)')
    
        # Encoding sub-modules (uuid, guid, and all other encoding modules) are in data/encoding/
        # Encoding sub-modules are in data/encoding/
        # Map file names to their initialization function names
        $encodingSubModules = @{
            'uuid.ps1'        = 'Initialize-FileConversion-CoreEncodingUuid'
            'guid.ps1'        = 'Initialize-FileConversion-CoreEncodingGuid'
            'roman.ps1'       = 'Initialize-FileConversion-CoreEncodingRoman'
            'modhex.ps1'      = 'Initialize-FileConversion-CoreEncodingModHex'
            'ascii.ps1'       = 'Initialize-FileConversion-CoreEncodingAscii'
            'hex.ps1'         = 'Initialize-FileConversion-CoreEncodingHex'
            'binary.ps1'      = 'Initialize-FileConversion-CoreEncodingBinary'
            'numeric.ps1'     = 'Initialize-FileConversion-CoreEncodingNumeric'
            'base32.ps1'      = 'Initialize-FileConversion-CoreEncodingBase32'
            'base36.ps1'      = 'Initialize-FileConversion-CoreEncodingBase36'
            'base58.ps1'      = 'Initialize-FileConversion-CoreEncodingBase58'
            'base62.ps1'      = 'Initialize-FileConversion-CoreEncodingBase62'
            'base85.ps1'      = 'Initialize-FileConversion-CoreEncodingBase85'
            'z85.ps1'         = 'Initialize-FileConversion-CoreEncodingZ85'
            'base91.ps1'      = 'Initialize-FileConversion-CoreEncodingBase91'
            'utf16-utf32.ps1' = 'Initialize-FileConversion-CoreEncodingUtf16Utf32'
            'rot.ps1'         = 'Initialize-FileConversion-CoreEncodingRot'
            'morse.ps1'       = 'Initialize-FileConversion-CoreEncodingMorse'
            'url.ps1'         = 'Initialize-FileConversion-CoreEncodingUrl'
        }
        Import-ModuleGroup -BaseDir $encodingDir -ModuleConfig $encodingSubModules -DefaultFunctionPatterns @('^ConvertFrom-')
    
        # Units modules are in data/units/
        $unitsDir = Join-Path $dataDir 'units'
        $unitsModules = @{
            'datasize.ps1'    = 'Initialize-FileConversion-CoreUnitsDataSize'
            'length.ps1'      = 'Initialize-FileConversion-CoreUnitsLength'
            'weight.ps1'      = 'Initialize-FileConversion-CoreUnitsWeight'
            'temperature.ps1' = 'Initialize-FileConversion-CoreUnitsTemperature'
            'volume.ps1'      = 'Initialize-FileConversion-CoreUnitsVolume'
            'energy.ps1'      = 'Initialize-FileConversion-CoreUnitsEnergy'
            'speed.ps1'       = 'Initialize-FileConversion-CoreUnitsSpeed'
            'area.ps1'        = 'Initialize-FileConversion-CoreUnitsArea'
            'pressure.ps1'    = 'Initialize-FileConversion-CoreUnitsPressure'
            'angle.ps1'       = 'Initialize-FileConversion-CoreUnitsAngle'
        }
        Import-ModuleGroup -BaseDir $unitsDir -ModuleConfig $unitsModules -DefaultFunctionPatterns @('^(Convert|Format)') -CustomPatterns $coreCustomPatterns
    }

    # Structured modules (always load, but filter if SelectiveModules specified)
    $structuredModules = Get-DataStructuredModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'structured' -ModuleConfig $structuredModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Binary modules (always load, but filter if SelectiveModules specified)
    $binaryModules = Get-DataBinaryModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'binary' -ModuleConfig $binaryModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Columnar modules (always load, but filter if SelectiveModules specified)
    $columnarModules = Get-DataColumnarModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'columnar' -ModuleConfig $columnarModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Scientific modules (always load, but filter if SelectiveModules specified)
    $scientificModules = Get-DataScientificModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'scientific' -ModuleConfig $scientificModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Database modules (always load, but filter if SelectiveModules specified)
    $databaseModules = Get-DataDatabaseModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'database' -ModuleConfig $databaseModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Network modules (always load, but filter if SelectiveModules specified)
    $networkModules = Get-DataNetworkModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'network' -ModuleConfig $networkModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules

    # Digest modules (always load, but filter if SelectiveModules specified)
    $digestModules = Get-DataDigestModulesConfig
    Import-ModuleGroup -BaseDir $dataDir -SubDir 'digest' -ModuleConfig $digestModules -DefaultFunctionPatterns @('^Convert(To|From)-') -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules
}

<#
.SYNOPSIS
    Loads document conversion modules.
.DESCRIPTION
    Loads all document conversion modules.
.PARAMETER ConversionModulesDir
    Base directory for conversion modules.
#>
function Import-DocumentConversionModules {
    param(
        [Parameter(Mandatory)]
        [string]$ConversionModulesDir
    )

    $documentModules = Get-DocumentModulesConfig
    Import-ModuleGroup -BaseDir $ConversionModulesDir -SubDir 'document' -ModuleConfig $documentModules -DefaultFunctionPatterns @('^Convert(To|From)-', '^(Merge|Resize)-')
}

<#
.SYNOPSIS
    Loads media conversion modules.
.DESCRIPTION
    Loads all media conversion modules including basic media and color conversion modules.
.PARAMETER ConversionModulesDir
    Base directory for conversion modules.
#>
function Import-MediaConversionModules {
    param(
        [Parameter(Mandatory)]
        [string]$ConversionModulesDir
    )

    $mediaDir = Join-Path $ConversionModulesDir 'media'
    if ($null -eq $mediaDir -or [string]::IsNullOrWhiteSpace($mediaDir) -or -not (Test-Path -LiteralPath $mediaDir)) {
        return
    }

    # Load basic media modules first (pdf, and legacy modules if they exist)
    $mediaModules = Get-MediaModulesConfig
    Import-ModuleGroup -BaseDir $mediaDir -ModuleConfig $mediaModules -DefaultFunctionPatterns @('^Convert(To|From)-|^Convert-', '^(Merge|Resize)-')

    # Load image modules (from media/images/)
    $imageModules = Get-MediaImageModulesConfig
    $imagesDir = Join-Path $mediaDir 'images'
    if ($imagesDir -and (Test-Path -LiteralPath $imagesDir)) {
        Import-ModuleGroup -BaseDir $imagesDir -ModuleConfig $imageModules -DefaultFunctionPatterns @('^Convert(To|From)-', '^(Merge|Resize)-')
    }

    # Load audio modules (from media/audio/)
    $audioModules = Get-MediaAudioModulesConfig
    $audioDir = Join-Path $mediaDir 'audio'
    if ($audioDir -and (Test-Path -LiteralPath $audioDir)) {
        Import-ModuleGroup -BaseDir $audioDir -ModuleConfig $audioModules -DefaultFunctionPatterns @('^Convert(To|From)-', '^(Merge|Resize)-')
    }

    # Load video modules (from media/video/)
    $videoDir = Join-Path $mediaDir 'video'
    if ($videoDir -and (Test-Path -LiteralPath $videoDir)) {
        Import-ModuleGroup -BaseDir $videoDir -ModuleConfig @{ 'video.ps1' = 'Initialize-FileConversion-MediaVideo' } -DefaultFunctionPatterns @('^Convert(To|From)-', '^(Merge|Resize)-')
    }

    # Load color conversion modules (in dependency order)
    $colorModules = Get-MediaColorModulesConfig
    # Map the config keys to actual file names (remove 'media-colors-' prefix)
    $colorModulesMapped = @{}
    foreach ($key in $colorModules.Keys) {
        $fileName = $key -replace '^media-colors-', ''
        $colorModulesMapped[$fileName] = $colorModules[$key]
    }
    $colorsDir = Join-Path $mediaDir 'colors'
    if ($colorsDir -and (Test-Path -LiteralPath $colorsDir)) {
        Import-ModuleGroup -BaseDir $colorsDir -ModuleConfig $colorModulesMapped -DefaultFunctionPatterns @('^.*')
    }
}

<#
.SYNOPSIS
    Ensures conversion modules are loaded before calling Ensure functions.
.DESCRIPTION
    Manually loads conversion modules from profile.d/conversion-modules to ensure
    initialization functions are available when tests call Ensure-FileConversion-Data,
    Ensure-FileConversion-Documents, or Ensure-FileConversion-Media.
.PARAMETER ProfileDir
    The profile.d directory path.
.PARAMETER ModuleType
    Type of modules to load: 'Data', 'Documents', 'Media', or 'All'.
.EXAMPLE
    Ensure-ConversionModulesLoaded -ProfileDir $script:ProfileDir -ModuleType 'Data'
    Loads all data conversion modules.
#>
function Ensure-ConversionModulesLoaded {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir,
        
        [ValidateSet('Data', 'Documents', 'Media', 'All')]
        [string]$ModuleType = 'All',

        [switch]$ParallelLoad,

        [string[]]$SelectiveModules
    )
    
    # Cache key for module loading
    $cacheKey = "ConversionModules_$ModuleType"
    
    # Check if already loaded (use script scope for cross-file caching)
    if (-not $script:ModuleLoadCache) {
        $script:ModuleLoadCache = @{}
    }
    
    if ($script:ModuleLoadCache.ContainsKey($cacheKey)) {
        return
    }
    
    $conversionModulesDir = Join-Path $ProfileDir 'conversion-modules'
    if ($null -eq $conversionModulesDir -or [string]::IsNullOrWhiteSpace($conversionModulesDir) -or -not (Test-Path -LiteralPath $conversionModulesDir)) {
        Write-Warning "Conversion modules directory not found: $conversionModulesDir"
        return
    }
    
    # Load helpers first (only once, cache separately)
    $helpersCacheKey = "ConversionHelpers"
    if (-not $script:ModuleLoadCache.ContainsKey($helpersCacheKey)) {
        Import-ConversionHelpers -ConversionModulesDir $conversionModulesDir
        $script:ModuleLoadCache[$helpersCacheKey] = $true
    }
    
    if ($ModuleType -in @('Data', 'All')) {
        Import-DataConversionModules -ConversionModulesDir $conversionModulesDir -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules
    }
    
    if ($ModuleType -in @('Documents', 'All')) {
        Import-DocumentConversionModules -ConversionModulesDir $conversionModulesDir
    }
    
    if ($ModuleType -in @('Media', 'All')) {
        Import-MediaConversionModules -ConversionModulesDir $conversionModulesDir
    }
    
    if ($ModuleType -in @('Specialized', 'All')) {
        $specializedModules = Get-SpecializedModulesConfig
        $specializedDir = Join-Path $conversionModulesDir 'specialized'
        if ($specializedDir -and (Test-Path -LiteralPath $specializedDir)) {
            Import-ModuleGroup -BaseDir $specializedDir -ModuleConfig $specializedModules -DefaultFunctionPatterns @('^.*')
        }
    }
    
    # Mark as loaded
    $script:ModuleLoadCache[$cacheKey] = $true
}

#endregion

#region Shared Profile Loading (Performance Optimization)

<#
.SYNOPSIS
    Loads profile components with caching to avoid redundant loading.

.DESCRIPTION
    Provides cached profile loading to improve test performance. Loads bootstrap,
    conversion modules, and file fragments only once per test run, then reuses
    the loaded state for subsequent calls.

.PARAMETER ProfileDir
    The profile.d directory path.

.PARAMETER LoadBootstrap
    Load the bootstrap fragment (bootstrap.ps1). Defaults to true.

.PARAMETER LoadConversionModules
    Load conversion modules. Specify 'Data', 'Media', 'Documents', or 'All'.
    If not specified, no conversion modules are loaded.

.PARAMETER LoadFilesFragment
    Load the files fragment (files.ps1). Defaults to false.

.PARAMETER EnsureFileConversion
    Call Ensure-FileConversion-Data after loading. Defaults to false.
    
.PARAMETER EnsureFileConversionMedia
    Call Ensure-FileConversion-Media after loading. Defaults to false.
    
.PARAMETER EnsureFileConversionDocuments
    Call Ensure-FileConversion-Documents after loading. Defaults to false.

.EXAMPLE
    Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadConversionModules 'Data'
    Loads bootstrap and data conversion modules for testing.

.NOTES
    This function uses caching to avoid reloading the same components multiple times
    during a test run, significantly improving test performance.
#>
function Initialize-TestProfile {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir,
        
        [switch]$LoadBootstrap = $true,
        
        [ValidateSet('Data', 'Documents', 'Media', 'Specialized', 'All')]
        [string]$LoadConversionModules,
        
        [switch]$LoadFilesFragment = $false,
        
        [switch]$EnsureFileConversion = $false,
        
        [switch]$EnsureFileConversionMedia = $false,
        
        [switch]$EnsureFileConversionDocuments = $false,
        
        [switch]$ParallelLoad,
        
        [string[]]$SelectiveModules
    )
    
    # Cache key based on what we're loading
    $cacheKey = "Profile_$(if ($LoadBootstrap) { 'Bootstrap' })_$(if ($LoadConversionModules) { $LoadConversionModules })_$(if ($LoadFilesFragment) { 'Files' })_$(if ($EnsureFileConversion) { 'EnsureData' })_$(if ($EnsureFileConversionMedia) { 'EnsureMedia' })_$(if ($EnsureFileConversionDocuments) { 'EnsureDocs' })"
    
    # Check if already loaded (use script scope for cross-file caching)
    if (-not $script:ProfileLoadCache) {
        $script:ProfileLoadCache = @{}
    }
    
    if ($script:ProfileLoadCache.ContainsKey($cacheKey)) {
        return
    }
    
    # Load bootstrap if requested
    if ($LoadBootstrap) {
        $bootstrapPath = Join-Path $ProfileDir 'bootstrap.ps1'
        if ($bootstrapPath -and (Test-Path -LiteralPath $bootstrapPath)) {
            . $bootstrapPath
        }
    }
    
    # Load conversion modules if requested
    if ($LoadConversionModules) {
        Ensure-ConversionModulesLoaded -ProfileDir $ProfileDir -ModuleType $LoadConversionModules -ParallelLoad:$ParallelLoad -SelectiveModules $SelectiveModules
    }
    
    # Load files fragment if requested
    if ($LoadFilesFragment) {
        $filesPath = Join-Path $ProfileDir 'files.ps1'
        if ($filesPath -and (Test-Path -LiteralPath $filesPath)) {
            . $filesPath
        }
    }
    
    # Ensure file conversion if requested
    # Skip if SelectiveModules is specified (Ensure-FileConversion-Data initializes all modules)
    if ($EnsureFileConversion -and (-not $SelectiveModules -or $SelectiveModules.Count -eq 0)) {
        if (Get-Command Ensure-FileConversion-Data -ErrorAction SilentlyContinue) {
            Ensure-FileConversion-Data
        }
    }
    
    if ($EnsureFileConversionMedia) {
        if (Get-Command Ensure-FileConversion-Media -ErrorAction SilentlyContinue) {
            Ensure-FileConversion-Media
        }
    }
    
    if ($EnsureFileConversionDocuments) {
        if (Get-Command Ensure-FileConversion-Documents -ErrorAction SilentlyContinue) {
            Ensure-FileConversion-Documents
        }
    }
    
    # Mark as loaded
    $script:ProfileLoadCache[$cacheKey] = $true
}


#endregion
#region Dev-Tools Modules Loading

<#
.SYNOPSIS
    Loads dev-tools modules.
.DESCRIPTION
    Loads all dev-tools modules including encoding, crypto, format, QR code, and data modules.
.PARAMETER DevToolsModulesDir
    Base directory for dev-tools modules.
#>
function Import-DevToolsModules {
    param(
        [Parameter(Mandatory)]
        [string]$DevToolsModulesDir
    )

    $defaultPatterns = @('^(Get|Convert|Format|New|Test|Invoke|Set|Add|Remove|Clear|Decode|Encode|Compare)')

    # Encoding modules
    $encodingModules = Get-DevToolsEncodingModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'encoding' -ModuleConfig $encodingModules -DefaultFunctionPatterns $defaultPatterns

    # Crypto modules
    $cryptoModules = Get-DevToolsCryptoModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'crypto' -ModuleConfig $cryptoModules -DefaultFunctionPatterns $defaultPatterns

    # Format modules
    $formatModules = Get-DevToolsFormatModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'format' -ModuleConfig $formatModules -DefaultFunctionPatterns $defaultPatterns

    # QR code modules
    $qrcodeModules = Get-DevToolsQrCodeModulesConfig
    $qrcodeDir = Join-Path $DevToolsModulesDir 'format' 'qrcode'
    Import-ModuleGroup -BaseDir $qrcodeDir -ModuleConfig $qrcodeModules -DefaultFunctionPatterns $defaultPatterns

    # Data modules
    $dataModules = Get-DevToolsDataModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'data' -ModuleConfig $dataModules -DefaultFunctionPatterns $defaultPatterns

    # After loading all modules, promote any remaining functions that might have been created
    # This ensures functions created by initialization functions are also promoted
    $allFuncs = Get-ChildItem Function: | Where-Object { 
        $_.Name -match '^(Get|Convert|Format|New|Test|Invoke|Set|Add|Remove|Clear|Decode|Encode|Compare)' -and
        $_.Name -notmatch '^Initialize-'
    }
    foreach ($f in $allFuncs) {
        if (-not (Get-Command "global:$($f.Name)" -ErrorAction SilentlyContinue)) {
            Set-Item -Path "Function:\global:$($f.Name)" -Value $f.ScriptBlock -ErrorAction SilentlyContinue -Force
        }
    }
}

<#
.SYNOPSIS
    Ensures dev-tools modules are loaded before calling Ensure-DevTools.
.DESCRIPTION
    Manually loads dev-tools modules from profile.d/dev-tools-modules to ensure
    initialization functions are available when tests call Ensure-DevTools.
.PARAMETER ProfileDir
    The profile.d directory path.
.EXAMPLE
    Ensure-DevToolsModulesLoaded -ProfileDir $script:ProfileDir
    Loads all dev-tools modules.
#>
function Ensure-DevToolsModulesLoaded {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir
    )
    
    $devToolsModulesDir = Join-Path $ProfileDir 'dev-tools-modules'
    if ($null -eq $devToolsModulesDir -or [string]::IsNullOrWhiteSpace($devToolsModulesDir) -or -not (Test-Path -LiteralPath $devToolsModulesDir)) {
        Write-Warning "Dev-tools modules directory not found: $devToolsModulesDir"
        return
    }
    
    Import-DevToolsModules -DevToolsModulesDir $devToolsModulesDir
}

#endregion

#region Dev-Tools Modules Loading

<#
.SYNOPSIS
    Loads dev-tools modules.
.DESCRIPTION
    Loads all dev-tools modules including encoding, crypto, format, QR code, and data modules.
.PARAMETER DevToolsModulesDir
    Base directory for dev-tools modules.
#>
function Import-DevToolsModules {
    param(
        [Parameter(Mandatory)]
        [string]$DevToolsModulesDir
    )

    $defaultPatterns = @('^(Get|Convert|Format|New|Test|Invoke|Set|Add|Remove|Clear|Decode|Encode|Compare)')

    # Encoding modules
    $encodingModules = Get-DevToolsEncodingModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'encoding' -ModuleConfig $encodingModules -DefaultFunctionPatterns $defaultPatterns

    # Crypto modules
    $cryptoModules = Get-DevToolsCryptoModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'crypto' -ModuleConfig $cryptoModules -DefaultFunctionPatterns $defaultPatterns

    # Format modules
    $formatModules = Get-DevToolsFormatModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'format' -ModuleConfig $formatModules -DefaultFunctionPatterns $defaultPatterns

    # QR code modules
    $qrcodeModules = Get-DevToolsQrCodeModulesConfig
    $qrcodeDir = Join-Path $DevToolsModulesDir 'format' 'qrcode'
    Import-ModuleGroup -BaseDir $qrcodeDir -ModuleConfig $qrcodeModules -DefaultFunctionPatterns $defaultPatterns

    # Data modules
    $dataModules = Get-DevToolsDataModulesConfig
    Import-ModuleGroup -BaseDir $DevToolsModulesDir -SubDir 'data' -ModuleConfig $dataModules -DefaultFunctionPatterns $defaultPatterns

    # After loading all modules, promote any remaining functions that might have been created
    # This ensures functions created by initialization functions are also promoted
    $allFuncs = Get-ChildItem Function: | Where-Object { 
        $_.Name -match '^(Get|Convert|Format|New|Test|Invoke|Set|Add|Remove|Clear|Decode|Encode|Compare)' -and
        $_.Name -notmatch '^Initialize-'
    }
    foreach ($f in $allFuncs) {
        if (-not (Get-Command "global:$($f.Name)" -ErrorAction SilentlyContinue)) {
            Set-Item -Path "Function:\global:$($f.Name)" -Value $f.ScriptBlock -ErrorAction SilentlyContinue -Force
        }
    }
}

<#
.SYNOPSIS
    Ensures dev-tools modules are loaded before calling Ensure-DevTools.
.DESCRIPTION
    Manually loads dev-tools modules from profile.d/dev-tools-modules to ensure
    initialization functions are available when tests call Ensure-DevTools.
.PARAMETER ProfileDir
    The profile.d directory path.
.EXAMPLE
    Ensure-DevToolsModulesLoaded -ProfileDir $script:ProfileDir
    Loads all dev-tools modules.
#>
function Ensure-DevToolsModulesLoaded {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir
    )
    
    $devToolsModulesDir = Join-Path $ProfileDir 'dev-tools-modules'
    if ($null -eq $devToolsModulesDir -or [string]::IsNullOrWhiteSpace($devToolsModulesDir) -or -not (Test-Path -LiteralPath $devToolsModulesDir)) {
        Write-Warning "Dev-tools modules directory not found: $devToolsModulesDir"
        return
    }
    
    Import-DevToolsModules -DevToolsModulesDir $devToolsModulesDir
}

#e
function Ensure-DevToolsModulesLoaded {
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir
    )
    
    $devToolsModulesDir = Join-Path $ProfileDir 'dev-tools-modules'
    if ($null -eq $devToolsModulesDir -or [string]::IsNullOrWhiteSpace($devToolsModulesDir) -or -not (Test-Path -LiteralPath $devToolsModulesDir)) {
        Write-Warning "Dev-tools modules directory not found: $devToolsModulesDir"
        return
    }
    
    Import-DevToolsModules -DevToolsModulesDir $devToolsModulesDir
}

#endregion

#region Python Package Helpers

# Load Python package availability helpers
$pythonHelpersPath = Join-Path $PSScriptRoot 'TestPythonHelpers.ps1'
if ($pythonHelpersPath -and (Test-Path -LiteralPath $pythonHelpersPath)) {
    . $pythonHelpersPath
}

#endregion
