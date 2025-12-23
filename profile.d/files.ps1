# ===============================================
# files.ps1
# File utilities, conversions, listing, and navigation
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Provides consistent error handling when loading sub-modules.

.DESCRIPTION
    Helper function for consistent error handling when loading sub-modules.
    Uses Write-ProfileError if available, otherwise falls back to Write-Warning.
    Only outputs errors when PS_PROFILE_DEBUG environment variable is set.

.PARAMETER ErrorRecord
    The error record to report.

.PARAMETER ModuleName
    The name of the module that failed to load.

.EXAMPLE
    try {
        . (Join-Path $dir 'module.ps1')
    }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'module.ps1'
    }

    Reports an error when loading a sub-module fails.
#>
function Write-SubModuleError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory)]
        [string]$ModuleName
    )
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $ErrorRecord -Context "Fragment: files ($ModuleName)" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load $ModuleName : $($ErrorRecord.Exception.Message)"
        }
    }
}

# Load LaTeX detection utilities using standardized module loading
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    $null = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('files', 'LaTeXDetection.ps1') `
        -Context "Fragment: files (LaTeXDetection.ps1)"
}
else {
    # Fallback for environments where Import-FragmentModule is not yet available
    $latexDetectionPath = Join-Path $PSScriptRoot 'files' 'LaTeXDetection.ps1'
    if (Test-Path -LiteralPath $latexDetectionPath -ErrorAction SilentlyContinue) {
        try {
            . $latexDetectionPath
        }
        catch {
            Write-SubModuleError -ErrorRecord $_ -ModuleName 'LaTeXDetection.ps1'
        }
    }
}

# Import Node.js helper module (provides Node.js detection and execution utilities)
# Used by conversion and dev-tools modules that require Node.js
# Note: This is a library module (scripts/lib), not a fragment module, so we use Import-Module directly
$nodeJsModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
if (Test-Path -LiteralPath $nodeJsModulePath -ErrorAction SilentlyContinue) {
    try {
        Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'NodeJs module'
    }
}

# ===============================================
# Module Registry for Deferred Loading
# ===============================================
# Load module registry that maps Ensure-* functions to module paths.
# This enables deferred loading - modules are only loaded when their Ensure function is called.
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    $null = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('files-module-registry.ps1') `
        -Context "Fragment: files (Module Registry)"
}
else {
    # Fallback for environments where Import-FragmentModule is not yet available
    $moduleRegistryPath = Join-Path $PSScriptRoot 'files-module-registry.ps1'
    if (Test-Path -LiteralPath $moduleRegistryPath -ErrorAction SilentlyContinue) {
        try {
            . $moduleRegistryPath
        }
        catch {
            Write-SubModuleError -ErrorRecord $_ -ModuleName 'Module Registry'
        }
    }
}

# Lazy bulk initializer for data format conversion helpers
# This function is called automatically when any data conversion function is first used.
# The lazy loading pattern defers expensive module initialization until actually needed.
<#
.SYNOPSIS
    Initializes data format conversion utility functions on first use.
.DESCRIPTION
    Sets up all data format conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads conversion modules from the conversion-modules subdirectory.
#>
function Ensure-FileConversion-Data {
    # Idempotency check: skip if already initialized
    if ($global:FileConversionDataInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Data' -BaseDir $PSScriptRoot
    }

    # Initialize all data conversion modules (core, structured, binary, columnar, scientific)
    # Only initialize functions that exist (modules may not all be loaded, e.g., with selective loading)
    # Core basic modules
    if (Get-Command Initialize-FileConversion-CoreBasicJson -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreBasicJson }
    if (Get-Command Initialize-FileConversion-CoreBasicYaml -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreBasicYaml }
    if (Get-Command Initialize-FileConversion-CoreBasicBase64 -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreBasicBase64 }
    if (Get-Command Initialize-FileConversion-CoreBasicCsv -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreBasicCsv }
    if (Get-Command Initialize-FileConversion-CoreBasicXml -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreBasicXml }
    if (Get-Command Initialize-FileConversion-CoreJsonExtended -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreJsonExtended }
    if (Get-Command Initialize-FileConversion-CoreTextGaps -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTextGaps }
    if (Get-Command Initialize-FileConversion-CoreEncoding -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreEncoding }
    if (Get-Command Initialize-FileConversion-CoreCompressionGzip -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionGzip }
    if (Get-Command Initialize-FileConversion-CoreCompressionBrotli -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionBrotli }
    if (Get-Command Initialize-FileConversion-CoreCompressionZstd -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionZstd }
    if (Get-Command Initialize-FileConversion-CoreCompressionLz4 -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionLz4 }
    if (Get-Command Initialize-FileConversion-CoreCompressionSnappy -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionSnappy }
    if (Get-Command Initialize-FileConversion-CoreCompressionXz -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreCompressionXz }
    if (Get-Command Initialize-FileConversion-CoreTimeUnix -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeUnix }
    if (Get-Command Initialize-FileConversion-CoreTimeIso8601 -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeIso8601 }
    if (Get-Command Initialize-FileConversion-CoreTimeRfc3339 -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeRfc3339 }
    if (Get-Command Initialize-FileConversion-CoreTimeHumanReadable -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeHumanReadable }
    if (Get-Command Initialize-FileConversion-CoreTimeTimezone -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeTimezone }
    if (Get-Command Initialize-FileConversion-CoreTimeDuration -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreTimeDuration }
    if (Get-Command Initialize-FileConversion-CoreEncodingUuid -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreEncodingUuid }
    if (Get-Command Initialize-FileConversion-CoreUnitsDataSize -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsDataSize }
    if (Get-Command Initialize-FileConversion-CoreUnitsLength -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsLength }
    if (Get-Command Initialize-FileConversion-CoreUnitsWeight -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsWeight }
    if (Get-Command Initialize-FileConversion-CoreUnitsTemperature -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsTemperature }
    if (Get-Command Initialize-FileConversion-CoreUnitsVolume -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsVolume }
    if (Get-Command Initialize-FileConversion-CoreUnitsEnergy -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsEnergy }
    if (Get-Command Initialize-FileConversion-CoreUnitsSpeed -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsSpeed }
    if (Get-Command Initialize-FileConversion-CoreUnitsArea -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsArea }
    if (Get-Command Initialize-FileConversion-CoreUnitsPressure -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsPressure }
    if (Get-Command Initialize-FileConversion-CoreUnitsAngle -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreUnitsAngle }
    if (Get-Command Initialize-FileConversion-CoreEncodingGuid -ErrorAction SilentlyContinue) { Initialize-FileConversion-CoreEncodingGuid }
    # Structured format modules
    if (Get-Command Initialize-FileConversion-Toon -ErrorAction SilentlyContinue) { Initialize-FileConversion-Toon }
    if (Get-Command Initialize-FileConversion-Toml -ErrorAction SilentlyContinue) { Initialize-FileConversion-Toml }
    if (Get-Command Initialize-FileConversion-SuperJson -ErrorAction SilentlyContinue) { Initialize-FileConversion-SuperJson }
    if (Get-Command Initialize-FileConversion-Ini -ErrorAction SilentlyContinue) { Initialize-FileConversion-Ini }
    if (Get-Command Initialize-FileConversion-Hjson -ErrorAction SilentlyContinue) { Initialize-FileConversion-Hjson }
    if (Get-Command Initialize-FileConversion-Jsonc -ErrorAction SilentlyContinue) { Initialize-FileConversion-Jsonc }
    if (Get-Command Initialize-FileConversion-Env -ErrorAction SilentlyContinue) { Initialize-FileConversion-Env }
    if (Get-Command Initialize-FileConversion-Properties -ErrorAction SilentlyContinue) { Initialize-FileConversion-Properties }
    if (Get-Command Initialize-FileConversion-Sexpr -ErrorAction SilentlyContinue) { Initialize-FileConversion-Sexpr }
    if (Get-Command Initialize-FileConversion-Edifact -ErrorAction SilentlyContinue) { Initialize-FileConversion-Edifact }
    if (Get-Command Initialize-FileConversion-Asn1 -ErrorAction SilentlyContinue) { Initialize-FileConversion-Asn1 }
    if (Get-Command Initialize-FileConversion-Edn -ErrorAction SilentlyContinue) { Initialize-FileConversion-Edn }
    if (Get-Command Initialize-FileConversion-Cfg -ErrorAction SilentlyContinue) { Initialize-FileConversion-Cfg }
    if (Get-Command Initialize-FileConversion-Ubjson -ErrorAction SilentlyContinue) { Initialize-FileConversion-Ubjson }
    if (Get-Command Initialize-FileConversion-Ion -ErrorAction SilentlyContinue) { Initialize-FileConversion-Ion }
    # Digest format modules
    if (Get-Command Initialize-FileConversion-Digest -ErrorAction SilentlyContinue) { Initialize-FileConversion-Digest }
    # Binary schema modules
    if (Get-Command Initialize-FileConversion-BinarySchemaProtobuf -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinarySchemaProtobuf }
    if (Get-Command Initialize-FileConversion-BinarySchemaAvro -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinarySchemaAvro }
    if (Get-Command Initialize-FileConversion-BinarySchemaFlatBuffers -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinarySchemaFlatBuffers }
    if (Get-Command Initialize-FileConversion-BinarySchemaThrift -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinarySchemaThrift }
    if (Get-Command Initialize-FileConversion-BinarySimple -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinarySimple }
    if (Get-Command Initialize-FileConversion-BinaryDirect -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryDirect }
    if (Get-Command Initialize-FileConversion-BinaryToText -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryToText }
    if (Get-Command Initialize-FileConversion-BinaryProtocolCapnp -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryProtocolCapnp }
    if (Get-Command Initialize-FileConversion-BinaryProtocolOrc -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryProtocolOrc }
    if (Get-Command Initialize-FileConversion-BinaryProtocolIceberg -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryProtocolIceberg }
    if (Get-Command Initialize-FileConversion-BinaryProtocolDelta -ErrorAction SilentlyContinue) { Initialize-FileConversion-BinaryProtocolDelta }
    # Columnar format modules
    if (Get-Command Initialize-FileConversion-ColumnarParquet -ErrorAction SilentlyContinue) { Initialize-FileConversion-ColumnarParquet }
    if (Get-Command Initialize-FileConversion-ColumnarArrow -ErrorAction SilentlyContinue) { Initialize-FileConversion-ColumnarArrow }
    if (Get-Command Initialize-FileConversion-ColumnarDirect -ErrorAction SilentlyContinue) { Initialize-FileConversion-ColumnarDirect }
    if (Get-Command Initialize-FileConversion-ColumnarToCsv -ErrorAction SilentlyContinue) { Initialize-FileConversion-ColumnarToCsv }
    # Scientific format modules
    if (Get-Command Initialize-FileConversion-ScientificHdf5 -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificHdf5 }
    if (Get-Command Initialize-FileConversion-ScientificNetCdf -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificNetCdf }
    if (Get-Command Initialize-FileConversion-ScientificDirect -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificDirect }
    if (Get-Command Initialize-FileConversion-ScientificToColumnar -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificToColumnar }
    if (Get-Command Initialize-FileConversion-ScientificFits -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificFits }
    if (Get-Command Initialize-FileConversion-ScientificMatlab -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificMatlab }
    if (Get-Command Initialize-FileConversion-ScientificSas -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificSas }
    if (Get-Command Initialize-FileConversion-ScientificSpss -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificSpss }
    if (Get-Command Initialize-FileConversion-ScientificStata -ErrorAction SilentlyContinue) { Initialize-FileConversion-ScientificStata }
    # Database format modules
    if (Get-Command Initialize-FileConversion-DatabaseSqlite -ErrorAction SilentlyContinue) { Initialize-FileConversion-DatabaseSqlite }
    if (Get-Command Initialize-FileConversion-DatabaseSqlDump -ErrorAction SilentlyContinue) { Initialize-FileConversion-DatabaseSqlDump }
    if (Get-Command Initialize-FileConversion-DatabaseDbf -ErrorAction SilentlyContinue) { Initialize-FileConversion-DatabaseDbf }
    if (Get-Command Initialize-FileConversion-DatabaseAccess -ErrorAction SilentlyContinue) { Initialize-FileConversion-DatabaseAccess }
    # Network format modules
    if (Get-Command Initialize-FileConversion-NetworkUrlUri -ErrorAction SilentlyContinue) { Initialize-FileConversion-NetworkUrlUri }
    if (Get-Command Initialize-FileConversion-NetworkQueryString -ErrorAction SilentlyContinue) { Initialize-FileConversion-NetworkQueryString }
    if (Get-Command Initialize-FileConversion-NetworkHttpHeaders -ErrorAction SilentlyContinue) { Initialize-FileConversion-NetworkHttpHeaders }
    if (Get-Command Initialize-FileConversion-NetworkMimeTypes -ErrorAction SilentlyContinue) { Initialize-FileConversion-NetworkMimeTypes }

    # Mark as initialized
    $global:FileConversionDataInitialized = $true
}

# Lazy bulk initializer for document format conversion helpers
<#
.SYNOPSIS
    Initializes document format conversion utility functions on first use.
.DESCRIPTION
    Sets up all document format conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads document conversion modules from the conversion-modules subdirectory.
#>
function Ensure-FileConversion-Documents {
    if ($global:FileConversionDocumentsInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Documents' -BaseDir $PSScriptRoot
    }

    # Initialize all document conversion modules (Markdown, LaTeX, reStructuredText, Textile, common utilities)
    # Only initialize functions that exist (modules may not all be loaded)
    if (Get-Command Initialize-FileConversion-DocumentMarkdown -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentMarkdown }
    if (Get-Command Initialize-FileConversion-DocumentLaTeX -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentLaTeX }
    if (Get-Command Initialize-FileConversion-DocumentRst -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentRst }
    if (Get-Command Initialize-FileConversion-DocumentTextile -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentTextile }
    if (Get-Command Initialize-FileConversion-DocumentFb2 -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentFb2 }
    if (Get-Command Initialize-FileConversion-DocumentDjvu -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentDjvu }
    # Document common modules
    if (Get-Command Initialize-FileConversion-DocumentCommonHtml -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentCommonHtml }
    if (Get-Command Initialize-FileConversion-DocumentCommonDocx -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentCommonDocx }
    if (Get-Command Initialize-FileConversion-DocumentCommonEpub -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentCommonEpub }
    # Office document modules
    if (Get-Command Initialize-FileConversion-DocumentOfficeOdt -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeOdt }
    if (Get-Command Initialize-FileConversion-DocumentOfficeOds -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeOds }
    if (Get-Command Initialize-FileConversion-DocumentOfficeOdp -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeOdp }
    if (Get-Command Initialize-FileConversion-DocumentOfficeRtf -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeRtf }
    if (Get-Command Initialize-FileConversion-DocumentOfficeExcel -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeExcel }
    if (Get-Command Initialize-FileConversion-DocumentOfficePlaintext -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficePlaintext }
    if (Get-Command Initialize-FileConversion-DocumentOfficeOrgmode -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeOrgmode }
    if (Get-Command Initialize-FileConversion-DocumentOfficeAsciidoc -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentOfficeAsciidoc }
    # E-book format modules
    if (Get-Command Initialize-FileConversion-DocumentEbookMobi -ErrorAction SilentlyContinue) { Initialize-FileConversion-DocumentEbookMobi }

    # Mark as initialized
    $global:FileConversionDocumentsInitialized = $true
}

# Lazy bulk initializer for media format conversion helpers
<#
.SYNOPSIS
    Initializes media format conversion utility functions on first use.
.DESCRIPTION
    Sets up all media format conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads media conversion modules from the conversion-modules subdirectory.
#>
function Ensure-FileConversion-Media {
    if ($global:FileConversionMediaInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Media' -BaseDir $PSScriptRoot
    }

    # Initialize all media conversion modules (images, audio, video, PDF, colors)
    # Only initialize functions that exist (modules may not all be loaded)
    # Image conversion modules (initialize in dependency order - common first, then format-specific)
    if (Get-Command Initialize-FileConversion-MediaImagesCommon -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesCommon }
    if (Get-Command Initialize-FileConversion-MediaImagesWebp -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesWebp }
    if (Get-Command Initialize-FileConversion-MediaImagesAvif -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesAvif }
    if (Get-Command Initialize-FileConversion-MediaImagesSvg -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesSvg }
    if (Get-Command Initialize-FileConversion-MediaImagesHeic -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesHeic }
    if (Get-Command Initialize-FileConversion-MediaImagesIco -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesIco }
    if (Get-Command Initialize-FileConversion-MediaImagesBmp -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesBmp }
    if (Get-Command Initialize-FileConversion-MediaImagesTiff -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaImagesTiff }
    # Audio conversion modules (initialize in dependency order - common first, then format-specific)
    if (Get-Command Initialize-FileConversion-MediaAudioCommon -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioCommon }
    if (Get-Command Initialize-FileConversion-MediaAudioFlac -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioFlac }
    if (Get-Command Initialize-FileConversion-MediaAudioOgg -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioOgg }
    if (Get-Command Initialize-FileConversion-MediaAudioWav -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioWav }
    if (Get-Command Initialize-FileConversion-MediaAudioAac -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioAac }
    if (Get-Command Initialize-FileConversion-MediaAudioOpus -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioOpus }
    if (Get-Command Initialize-FileConversion-MediaAudioVideo -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaAudioVideo }
    if (Get-Command Initialize-FileConversion-MediaVideo -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaVideo }
    if (Get-Command Initialize-FileConversion-MediaPdf -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaPdf }
    # Initialize color conversion modules (in dependency order)
    if (Get-Command Initialize-FileConversion-MediaColorsNamed -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsNamed }
    if (Get-Command Initialize-FileConversion-MediaColorsHex -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsHex }
    if (Get-Command Initialize-FileConversion-MediaColorsHsl -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsHsl }
    if (Get-Command Initialize-FileConversion-MediaColorsHwb -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsHwb }
    if (Get-Command Initialize-FileConversion-MediaColorsCmyk -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsCmyk }
    if (Get-Command Initialize-FileConversion-MediaColorsNcol -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsNcol }
    if (Get-Command Initialize-FileConversion-MediaColorsLab -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsLab }
    if (Get-Command Initialize-FileConversion-MediaColorsOklab -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsOklab }
    if (Get-Command Initialize-FileConversion-MediaColorsLch -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsLch }
    if (Get-Command Initialize-FileConversion-MediaColorsOklch -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsOklch }
    if (Get-Command Initialize-FileConversion-MediaColorsParse -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsParse }
    if (Get-Command Initialize-FileConversion-MediaColorsConvert -ErrorAction SilentlyContinue) { Initialize-FileConversion-MediaColorsConvert }

    # Mark as initialized
    $global:FileConversionMediaInitialized = $true
}

# Lazy bulk initializer for specialized format conversion helpers
<#
.SYNOPSIS
    Initializes specialized format conversion utility functions on first use.
.DESCRIPTION
    Sets up all specialized format conversion utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads specialized conversion modules from the conversion-modules subdirectory.
#>
function Ensure-FileConversion-Specialized {
    if ($global:FileConversionSpecializedInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Specialized' -BaseDir $PSScriptRoot
    }

    # Initialize all specialized conversion modules (QR Code, JWT, Barcode)
    # Only initialize functions that exist (modules may not all be loaded)
    if (Get-Command Initialize-FileConversion-Specialized -ErrorAction SilentlyContinue) { Initialize-FileConversion-Specialized }

    # Mark as initialized
    $global:FileConversionSpecializedInitialized = $true
}

# ===============================================
# File Utility Modules - DEFERRED LOADING
# ===============================================
# Modules are now loaded on-demand via Ensure-FileUtilities function.
# See files-module-registry.ps1 for module mappings.
#
# OLD EAGER LOADING CODE (commented out for performance):
# $filesModulesDir = Join-Path $PSScriptRoot 'files-modules'
# if (Test-Path $filesModulesDir) {
#     # File inspection utilities (head/tail, hash, size, hexdump)
#     $inspectionDir = Join-Path $filesModulesDir 'inspection'
#     Import-FragmentModule -ModuleDir $inspectionDir -ModuleFile 'files-head-tail.ps1'
#     Import-FragmentModule -ModuleDir $inspectionDir -ModuleFile 'files-hash.ps1'
#     Import-FragmentModule -ModuleDir $inspectionDir -ModuleFile 'files-size.ps1'
#     Import-FragmentModule -ModuleDir $inspectionDir -ModuleFile 'files-hexdump.ps1'
#     
#     # File navigation utilities (directory listing, path navigation)
#     $navigationDir = Join-Path $filesModulesDir 'navigation'
#     Import-FragmentModule -ModuleDir $navigationDir -ModuleFile 'files-listing.ps1'
#     Import-FragmentModule -ModuleDir $navigationDir -ModuleFile 'files-navigation.ps1'
# }

# Lazy bulk initializer for file utility functions
<#
.SYNOPSIS
    Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads file utility modules from the files-modules subdirectory.
#>
function Ensure-FileUtilities {
    if ($global:FileUtilitiesInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileUtilities' -BaseDir $PSScriptRoot
    }

    # Initialize all file utility modules (head/tail, hash, size, hexdump)
    # Only initialize functions that exist (modules may not all be loaded)
    if (Get-Command Initialize-FileUtilities-HeadTail -ErrorAction SilentlyContinue) { Initialize-FileUtilities-HeadTail }
    if (Get-Command Initialize-FileUtilities-Hash -ErrorAction SilentlyContinue) { Initialize-FileUtilities-Hash }
    if (Get-Command Initialize-FileUtilities-Size -ErrorAction SilentlyContinue) { Initialize-FileUtilities-Size }
    if (Get-Command Initialize-FileUtilities-HexDump -ErrorAction SilentlyContinue) { Initialize-FileUtilities-HexDump }

    # Mark as initialized
    $global:FileUtilitiesInitialized = $true
}

# ===============================================
# Dev Tools Modules - DEFERRED LOADING
# ===============================================
# Modules are now loaded on-demand via Ensure-DevTools function.
# See files-module-registry.ps1 for module mappings.
#
# OLD EAGER LOADING CODE (commented out for performance):
# $devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
# if (Test-Path $devToolsModulesDir) {
#     # Encoding utilities (Base64, URL encoding, etc.)
#     $encodingDir = Join-Path $devToolsModulesDir 'encoding'
#     Import-FragmentModule -ModuleDir $encodingDir -ModuleFile 'base-encoding.ps1'
#     Import-FragmentModule -ModuleDir $encodingDir -ModuleFile 'encoding.ps1'
#     
#     # Cryptographic utilities (hashing, JWT)
#     $cryptoDir = Join-Path $devToolsModulesDir 'crypto'
#     Import-FragmentModule -ModuleDir $cryptoDir -ModuleFile 'hash.ps1'
#     Import-FragmentModule -ModuleDir $cryptoDir -ModuleFile 'jwt.ps1'
#     
#     # Formatting utilities (diff, regex)
#     $formatDir = Join-Path $devToolsModulesDir 'format'
#     Import-FragmentModule -ModuleDir $formatDir -ModuleFile 'diff.ps1'
#     Import-FragmentModule -ModuleDir $formatDir -ModuleFile 'regex.ps1'
#     
#     # QR code generation and parsing utilities
#     $qrcodeDir = Join-Path $formatDir 'qrcode'
#     Import-FragmentModule -ModuleDir $qrcodeDir -ModuleFile 'qrcode.ps1'
#     Import-FragmentModule -ModuleDir $qrcodeDir -ModuleFile 'qrcode-communication.ps1'
#     Import-FragmentModule -ModuleDir $qrcodeDir -ModuleFile 'qrcode-formats.ps1'
#     Import-FragmentModule -ModuleDir $qrcodeDir -ModuleFile 'qrcode-specialized.ps1'
#     
#     # Data generation and manipulation utilities (timestamps, UUIDs, Lorem ipsum, number bases, units)
#     $dataDir = Join-Path $devToolsModulesDir 'data'
#     Import-FragmentModule -ModuleDir $dataDir -ModuleFile 'timestamp.ps1'
#     Import-FragmentModule -ModuleDir $dataDir -ModuleFile 'uuid.ps1'
#     Import-FragmentModule -ModuleDir $dataDir -ModuleFile 'lorem.ps1'
#     Import-FragmentModule -ModuleDir $dataDir -ModuleFile 'number-base.ps1'
#     Import-FragmentModule -ModuleDir $dataDir -ModuleFile 'units.ps1'
# }

# Lazy bulk initializer for dev tools helpers
<#
.SYNOPSIS
    Initializes dev tools utility functions on first use.
.DESCRIPTION
    Sets up all dev tools utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads dev tools modules from the dev-tools-modules subdirectory.
#>
function Ensure-DevTools {
    if ($global:DevToolsInitialized) { return }

    # Load modules from registry (deferred loading - only loads when this function is called)
    if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
        Load-EnsureModules -EnsureFunctionName 'Ensure-DevTools' -BaseDir $PSScriptRoot
    }

    # Initialize all dev tools modules (crypto, encoding, formatting, data utilities)
    # Only initialize functions that exist (modules may not all be loaded)
    if (Get-Command Initialize-DevTools-Hash -ErrorAction SilentlyContinue) { Initialize-DevTools-Hash }
    if (Get-Command Initialize-DevTools-Jwt -ErrorAction SilentlyContinue) { Initialize-DevTools-Jwt }
    if (Get-Command Initialize-DevTools-Timestamp -ErrorAction SilentlyContinue) { Initialize-DevTools-Timestamp }
    if (Get-Command Initialize-DevTools-Uuid -ErrorAction SilentlyContinue) { Initialize-DevTools-Uuid }
    if (Get-Command Initialize-DevTools-Encoding -ErrorAction SilentlyContinue) { Initialize-DevTools-Encoding }
    if (Get-Command Initialize-DevTools-Diff -ErrorAction SilentlyContinue) { Initialize-DevTools-Diff }
    if (Get-Command Initialize-DevTools-Regex -ErrorAction SilentlyContinue) { Initialize-DevTools-Regex }
    if (Get-Command Initialize-DevTools-QrCode -ErrorAction SilentlyContinue) { Initialize-DevTools-QrCode }
    if (Get-Command Initialize-DevTools-BaseEncoding -ErrorAction SilentlyContinue) { Initialize-DevTools-BaseEncoding }
    if (Get-Command Initialize-DevTools-NumberBase -ErrorAction SilentlyContinue) { Initialize-DevTools-NumberBase }
    if (Get-Command Initialize-DevTools-Lorem -ErrorAction SilentlyContinue) { Initialize-DevTools-Lorem }
    if (Get-Command Initialize-DevTools-Units -ErrorAction SilentlyContinue) { Initialize-DevTools-Units }

    # Mark as initialized
    $global:DevToolsInitialized = $true
}
