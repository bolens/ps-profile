# ===============================================
# 02-files.ps1
# File utilities, conversions, listing, and navigation
# ===============================================

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
            Write-ProfileError -ErrorRecord $ErrorRecord -Context "Fragment: 02-files ($ModuleName)" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load $ModuleName : $($ErrorRecord.Exception.Message)"
        }
    }
}

# Helper functions for document conversion dependencies
<#
.SYNOPSIS
    Tests whether a supported LaTeX engine is available.
.DESCRIPTION
    Checks for pdflatex, xelatex, or luatex in the current environment and returns
    the first engine found so callers can select an appropriate --pdf-engine.
.OUTPUTS
    [string] - The name of the LaTeX engine if found; otherwise $null.
#>
function Test-DocumentLatexEngineAvailable {
    # Check PATH first
    if (Get-Command pdflatex -ErrorAction SilentlyContinue) { return 'pdflatex' }
    if (Get-Command xelatex -ErrorAction SilentlyContinue) { return 'xelatex' }
    if (Get-Command luatex -ErrorAction SilentlyContinue) { return 'luatex' }
    
    # Check Scoop MiKTeX installation if not in PATH
    # Check both global ($env:SCOOP_GLOBAL) and local ($env:SCOOP) Scoop installations
    if ($env:SCOOP_GLOBAL -or $env:SCOOP) {
        $scoopMiktexBinPaths = @()
        
        # If MiKTeX is installed in the global scoop directory
        if ($env:SCOOP_GLOBAL -and (Test-Path "$env:SCOOP_GLOBAL\apps\miktex\current")) {
            $scoopMiktexBinPaths += @(
                "$env:SCOOP_GLOBAL\apps\miktex\current\texmfs\install\miktex\bin\x64",
                "$env:SCOOP_GLOBAL\apps\miktex\current\texmfs\install\miktex\bin",
                "$env:SCOOP_GLOBAL\apps\miktex\current\miktex\bin\x64",
                "$env:SCOOP_GLOBAL\apps\miktex\current\miktex\bin"
            )
        }
        # If MiKTeX is installed in the local scoop directory
        if ($env:SCOOP -and (Test-Path "$env:SCOOP\apps\miktex\current")) {
            $scoopMiktexBinPaths += @(
                "$env:SCOOP\apps\miktex\current\texmfs\install\miktex\bin\x64",
                "$env:SCOOP\apps\miktex\current\texmfs\install\miktex\bin",
                "$env:SCOOP\apps\miktex\current\miktex\bin\x64",
                "$env:SCOOP\apps\miktex\current\miktex\bin"
            )
        }
        
        foreach ($binPath in $scoopMiktexBinPaths) {
            if (Test-Path $binPath) {
                # Check for engines in this directory
                if (Test-Path (Join-Path $binPath 'pdflatex.exe')) { return 'pdflatex' }
                if (Test-Path (Join-Path $binPath 'xelatex.exe')) { return 'xelatex' }
                if (Test-Path (Join-Path $binPath 'luatex.exe')) { return 'luatex' }
            }
        }
    }
    
    return $null
}

<#
.SYNOPSIS
    Ensures a LaTeX engine is available for PDF conversions.
.DESCRIPTION
    Invokes Test-DocumentLatexEngineAvailable and, when no engine is present,
    raises Write-MissingToolWarning with MiKTeX installation guidance before throwing.
.OUTPUTS
    [string] - The detected LaTeX engine name.
.NOTES
    The project assumes Scoop is installed; MiKTeX can be installed via `scoop install miktex`.
#>
function Ensure-DocumentLatexEngine {
    $engine = Test-DocumentLatexEngineAvailable
    if (-not $engine) {
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'MiKTeX (pdflatex)' -InstallHint "scoop install miktex"
        }
        throw "LaTeX engine (pdflatex/xelatex/luatex) not found. Install MiKTeX via 'scoop install miktex' or configure pandoc with --pdf-engine."
    }

    return $engine
}

# Import Node.js helper module (provides Node.js detection and execution utilities)
# Used by conversion and dev-tools modules that require Node.js
$nodeJsModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts' 'lib' 'NodeJs.psm1'
if (Test-Path $nodeJsModulePath) {
    try {
        Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'NodeJs module'
    }
}

# ===============================================
# Conversion Modules
# ===============================================
# Load conversion helper modules that provide format conversion utilities.
# These modules are loaded eagerly (not lazy) as they define initialization functions
# used by the lazy-loading Ensure-* functions below.

$conversionModulesDir = Join-Path $PSScriptRoot 'conversion-modules'
if (Test-Path $conversionModulesDir) {
    # Shared helper modules (XML parsing, TOML/JSON utilities)
    $helpersDir = Join-Path $conversionModulesDir 'helpers'
    try { . (Join-Path $helpersDir 'helpers-xml.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'helpers-xml.ps1' }
    
    try { . (Join-Path $helpersDir 'helpers-toon.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'helpers-toon.ps1' }
    
    # Data format conversion modules (organized by data type)
    $dataDir = Join-Path $conversionModulesDir 'data'
    $coreDir = Join-Path $dataDir 'core'
    try { . (Join-Path $coreDir 'core-basic.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'core-basic.ps1' }
    
    try { . (Join-Path $coreDir 'core-json-extended.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'core-json-extended.ps1' }
    
    try { . (Join-Path $coreDir 'core-text-gaps.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'core-text-gaps.ps1' }
    
    # Structured data conversion modules
    $structuredDir = Join-Path $dataDir 'structured'
    try { . (Join-Path $structuredDir 'toon.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'toon.ps1' }
    
    try { . (Join-Path $structuredDir 'toml.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'toml.ps1' }
    
    try { . (Join-Path $structuredDir 'superjson.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'superjson.ps1' }
    
    # Binary data conversion modules
    $binaryDir = Join-Path $dataDir 'binary'
    try { . (Join-Path $binaryDir 'binary-schema.ps1') }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'binary-schema.ps1' 
    }
    
    try { . (Join-Path $binaryDir 'binary-simple.ps1') }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'binary-simple.ps1'    
    }
    try { . (Join-Path $binaryDir 'binary-direct.ps1') }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'binary-direct.ps1'    
    }
    
    try { . (Join-Path $binaryDir 'binary-to-text.ps1') }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'binary-to-text.ps1'    
    }
    
    # Columnar data conversion modules
    $columnarDir = Join-Path $dataDir 'columnar'
    try { . (Join-Path $columnarDir 'columnar-parquet.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'columnar-parquet.ps1' }
    
    try { . (Join-Path $columnarDir 'columnar-arrow.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'columnar-arrow.ps1' }
    
    try { . (Join-Path $columnarDir 'columnar-direct.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'columnar-direct.ps1' }
    
    try { . (Join-Path $columnarDir 'columnar-to-csv.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'columnar-to-csv.ps1' }
    
    # Scientific data conversion modules
    $scientificDir = Join-Path $dataDir 'scientific'
    try { . (Join-Path $scientificDir 'scientific-hdf5.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'scientific-hdf5.ps1' }
    
    try { . (Join-Path $scientificDir 'scientific-netcdf.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'scientific-netcdf.ps1' }
    
    try { . (Join-Path $scientificDir 'scientific-direct.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'scientific-direct.ps1' }
    
    try { . (Join-Path $scientificDir 'scientific-to-columnar.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'scientific-to-columnar.ps1' }
    
    # Document conversion modules
    $documentDir = Join-Path $conversionModulesDir 'document'
    try { . (Join-Path $documentDir 'document-markdown.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'document-markdown.ps1' }
    
    try { . (Join-Path $documentDir 'document-latex.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'document-latex.ps1' }
    
    try { . (Join-Path $documentDir 'document-rst.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'document-rst.ps1' }
    
    try { . (Join-Path $documentDir 'document-common.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'document-common.ps1' }
    
    # Media conversion modules
    $mediaDir = Join-Path $conversionModulesDir 'media'
    try { . (Join-Path $mediaDir 'media-images.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'media-images.ps1' }
    
    try { . (Join-Path $mediaDir 'media-audio.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'media-audio.ps1' }
    
    try { . (Join-Path $mediaDir 'media-video.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'media-video.ps1' }
    
    try { . (Join-Path $mediaDir 'media-pdf.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'media-pdf.ps1' }
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

    # Initialize all data conversion modules (core, structured, binary, columnar, scientific)
    Initialize-FileConversion-CoreBasic
    Initialize-FileConversion-CoreJsonExtended
    Initialize-FileConversion-CoreTextGaps
    Initialize-FileConversion-Toon
    Initialize-FileConversion-Toml
    Initialize-FileConversion-SuperJson
    Initialize-FileConversion-BinarySchema
    Initialize-FileConversion-BinarySimple
    Initialize-FileConversion-BinaryDirect
    Initialize-FileConversion-BinaryToText
    Initialize-FileConversion-ColumnarParquet
    Initialize-FileConversion-ColumnarArrow
    Initialize-FileConversion-ColumnarDirect
    Initialize-FileConversion-ColumnarToCsv
    Initialize-FileConversion-ScientificHdf5
    Initialize-FileConversion-ScientificNetCdf
    Initialize-FileConversion-ScientificDirect
    Initialize-FileConversion-ScientificToColumnar

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

    # Initialize all document conversion modules (Markdown, LaTeX, reStructuredText, common utilities)
    Initialize-FileConversion-DocumentMarkdown
    Initialize-FileConversion-DocumentLaTeX
    Initialize-FileConversion-DocumentRst
    Initialize-FileConversion-DocumentCommon

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

    # Initialize all media conversion modules (images, audio, video, PDF)
    Initialize-FileConversion-MediaImages
    Initialize-FileConversion-MediaAudio
    Initialize-FileConversion-MediaVideo
    Initialize-FileConversion-MediaPdf

    # Mark as initialized
    $global:FileConversionMediaInitialized = $true
}

# ===============================================
# File Utility Modules
# ===============================================
# Load file utility modules that provide file inspection and navigation functions.
# These modules are loaded eagerly as they define initialization functions used by lazy-loading.

$filesModulesDir = Join-Path $PSScriptRoot 'files-modules'
if (Test-Path $filesModulesDir) {
    # File inspection utilities (head/tail, hash, size, hexdump)
    $inspectionDir = Join-Path $filesModulesDir 'inspection'
    try { . (Join-Path $inspectionDir 'files-head-tail.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-head-tail.ps1' }
    
    try { . (Join-Path $inspectionDir 'files-hash.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-hash.ps1' }
    
    try { . (Join-Path $inspectionDir 'files-size.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-size.ps1' }
    
    try { . (Join-Path $inspectionDir 'files-hexdump.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-hexdump.ps1' }
    
    # File navigation utilities (directory listing, path navigation)
    $navigationDir = Join-Path $filesModulesDir 'navigation'
    try { . (Join-Path $navigationDir 'files-listing.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-listing.ps1' }
    
    try { . (Join-Path $navigationDir 'files-navigation.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'files-navigation.ps1' }
}

# Lazy bulk initializer for file utility functions
<#
.SYNOPSIS
    Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads file utility modules from the files-modules subdirectory.
#>
function Ensure-FileUtilities {
    if ($global:FileUtilitiesInitialized) { return }

    # Initialize all file utility modules (head/tail, hash, size, hexdump)
    Initialize-FileUtilities-HeadTail
    Initialize-FileUtilities-Hash
    Initialize-FileUtilities-Size
    Initialize-FileUtilities-HexDump

    # Mark as initialized
    $global:FileUtilitiesInitialized = $true
}

# ===============================================
# Dev Tools Modules
# ===============================================
# Load development tool modules that provide encoding, crypto, formatting, and data utilities.
# These modules are loaded eagerly as they define initialization functions used by lazy-loading.

$devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
if (Test-Path $devToolsModulesDir) {
    # Encoding utilities (Base64, URL encoding, etc.)
    $encodingDir = Join-Path $devToolsModulesDir 'encoding'
    try { . (Join-Path $encodingDir 'base-encoding.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'base-encoding.ps1' }
    
    try { . (Join-Path $encodingDir 'encoding.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'encoding.ps1' }
    
    # Cryptographic utilities (hashing, JWT)
    $cryptoDir = Join-Path $devToolsModulesDir 'crypto'
    try { . (Join-Path $cryptoDir 'hash.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'hash.ps1' }
    
    try { . (Join-Path $cryptoDir 'jwt.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'jwt.ps1' }
    
    # Formatting utilities (diff, regex)
    $formatDir = Join-Path $devToolsModulesDir 'format'
    try { . (Join-Path $formatDir 'diff.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'diff.ps1' }
    
    try { . (Join-Path $formatDir 'regex.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'regex.ps1' }
    
    # QR code generation and parsing utilities
    $qrcodeDir = Join-Path $formatDir 'qrcode'
    try { . (Join-Path $qrcodeDir 'qrcode.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'qrcode.ps1' }
    
    try { . (Join-Path $qrcodeDir 'qrcode-communication.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'qrcode-communication.ps1' }
    
    try { . (Join-Path $qrcodeDir 'qrcode-formats.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'qrcode-formats.ps1' }
    
    try { . (Join-Path $qrcodeDir 'qrcode-specialized.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'qrcode-specialized.ps1' }
    
    # Data generation and manipulation utilities (timestamps, UUIDs, Lorem ipsum, number bases, units)
    $dataDir = Join-Path $devToolsModulesDir 'data'
    try { . (Join-Path $dataDir 'timestamp.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'timestamp.ps1' }
    
    try { . (Join-Path $dataDir 'uuid.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'uuid.ps1' }
    
    try { . (Join-Path $dataDir 'lorem.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'lorem.ps1' }
    
    try { . (Join-Path $dataDir 'number-base.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'number-base.ps1' }
    
    try { . (Join-Path $dataDir 'units.ps1') }
    catch { Write-SubModuleError -ErrorRecord $_ -ModuleName 'units.ps1' }
}

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

    # Initialize all dev tools modules (crypto, encoding, formatting, data utilities)
    Initialize-DevTools-Hash
    Initialize-DevTools-Jwt
    Initialize-DevTools-Timestamp
    Initialize-DevTools-Uuid
    Initialize-DevTools-Encoding
    Initialize-DevTools-Diff
    Initialize-DevTools-Regex
    Initialize-DevTools-QrCode
    Initialize-DevTools-BaseEncoding
    Initialize-DevTools-NumberBase
    Initialize-DevTools-Lorem
    Initialize-DevTools-Units

    # Mark as initialized
    $global:DevToolsInitialized = $true
}
