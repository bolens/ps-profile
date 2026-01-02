# ===============================================
# Module Registry for Deferred Loading
# ===============================================
# This registry maps Ensure-* functions to the modules they need to load.
# Modules are loaded on-demand when their Ensure function is first called.

# Registry structure: EnsureFunctionName -> Array of module paths
$script:FileConversionModuleRegistry = @{
    'Ensure-FileConversion-Data'        = @(
        # Shared helpers
        @{ Dir = 'conversion-modules/helpers'; File = 'helpers-xml.ps1' }
        @{ Dir = 'conversion-modules/helpers'; File = 'helpers-toon.ps1' }
        # Core basic formats
        @{ Dir = 'conversion-modules/data/core'; File = 'json.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'yaml.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'csv.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'xml.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'json-extended.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'text-gaps.ps1' }
        # Base64
        @{ Dir = 'conversion-modules/data/base64'; File = 'base64.ps1' }
        # Compression
        @{ Dir = 'conversion-modules/data/compression'; File = 'gzip.ps1' }
        @{ Dir = 'conversion-modules/data/compression'; File = 'brotli.ps1' }
        @{ Dir = 'conversion-modules/data/compression'; File = 'zstd.ps1' }
        @{ Dir = 'conversion-modules/data/compression'; File = 'lz4.ps1' }
        @{ Dir = 'conversion-modules/data/compression'; File = 'snappy.ps1' }
        @{ Dir = 'conversion-modules/data/compression'; File = 'xz.ps1' }
        # Encoding
        @{ Dir = 'conversion-modules/data/encoding'; File = 'encoding.ps1' }
        # Time formats
        @{ Dir = 'conversion-modules/data/time'; File = 'unix.ps1' }
        @{ Dir = 'conversion-modules/data/time'; File = 'iso8601.ps1' }
        @{ Dir = 'conversion-modules/data/time'; File = 'human-readable.ps1' }
        @{ Dir = 'conversion-modules/data/time'; File = 'timezone.ps1' }
        @{ Dir = 'conversion-modules/data/time'; File = 'duration.ps1' }
        @{ Dir = 'conversion-modules/data/time'; File = 'rfc3339.ps1' }
        # Units
        @{ Dir = 'conversion-modules/data/units'; File = 'datasize.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'length.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'weight.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'temperature.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'volume.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'energy.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'speed.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'area.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'pressure.ps1' }
        @{ Dir = 'conversion-modules/data/units'; File = 'angle.ps1' }
        # Structured
        @{ Dir = 'conversion-modules/data/structured'; File = 'toon.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'toml.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'superjson.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'ini.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'hjson.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'jsonc.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'env.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'properties.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'sexpr.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'edifact.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'asn1.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'edn.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'cfg.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'ubjson.ps1' }
        @{ Dir = 'conversion-modules/data/structured'; File = 'ion.ps1' }
        # Digest
        @{ Dir = 'conversion-modules/data/digest'; File = 'digest.ps1' }
        # Binary
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-schema-protobuf.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-schema-avro.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-schema-flatbuffers.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-schema-thrift.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-simple.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-direct.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-to-text.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-protocol-capnp.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-protocol-orc.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-protocol-iceberg.ps1' }
        @{ Dir = 'conversion-modules/data/binary'; File = 'binary-protocol-delta.ps1' }
        # Columnar
        @{ Dir = 'conversion-modules/data/columnar'; File = 'columnar-parquet.ps1' }
        @{ Dir = 'conversion-modules/data/columnar'; File = 'columnar-arrow.ps1' }
        @{ Dir = 'conversion-modules/data/columnar'; File = 'columnar-direct.ps1' }
        @{ Dir = 'conversion-modules/data/columnar'; File = 'columnar-to-csv.ps1' }
        # Scientific
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-hdf5.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-netcdf.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-direct.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-to-columnar.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-fits.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-matlab.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-sas.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-spss.ps1' }
        @{ Dir = 'conversion-modules/data/scientific'; File = 'scientific-stata.ps1' }
        # Database
        @{ Dir = 'conversion-modules/data/database'; File = 'database-sqlite.ps1' }
        @{ Dir = 'conversion-modules/data/database'; File = 'database-sql-dump.ps1' }
        @{ Dir = 'conversion-modules/data/database'; File = 'database-dbf.ps1' }
        @{ Dir = 'conversion-modules/data/database'; File = 'database-access.ps1' }
        # Network
        @{ Dir = 'conversion-modules/data/network'; File = 'network-url-uri.ps1' }
        @{ Dir = 'conversion-modules/data/network'; File = 'network-query-string.ps1' }
        @{ Dir = 'conversion-modules/data/network'; File = 'network-http-headers.ps1' }
        @{ Dir = 'conversion-modules/data/network'; File = 'network-mime-types.ps1' }
    )
    
    'Ensure-FileConversion-Documents'   = @(
        @{ Dir = 'conversion-modules/document'; File = 'document-markdown.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-latex.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-rst.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-textile.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-fb2.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-djvu.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-common-html.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-common-docx.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-common-epub.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-odt.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-ods.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-odp.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-rtf.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-excel.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-plaintext.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-orgmode.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-office-asciidoc.ps1' }
        @{ Dir = 'conversion-modules/document'; File = 'document-ebook-mobi.ps1' }
    )
    
    'Ensure-FileConversion-Media'       = @(
        # Images
        @{ Dir = 'conversion-modules/media/images'; File = 'common.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'webp.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'avif.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'svg.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'heic.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'ico.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'bmp.ps1' }
        @{ Dir = 'conversion-modules/media/images'; File = 'tiff.ps1' }
        # Audio
        @{ Dir = 'conversion-modules/media/audio'; File = 'common.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'flac.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'ogg.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'wav.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'aac.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'opus.ps1' }
        @{ Dir = 'conversion-modules/media/audio'; File = 'video.ps1' }
        # Video
        @{ Dir = 'conversion-modules/media/video'; File = 'video.ps1' }
        # PDF
        @{ Dir = 'conversion-modules/media'; File = 'pdf.ps1' }
        # Colors
        @{ Dir = 'conversion-modules/media/colors'; File = 'named.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'hex.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'hsl.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'hwb.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'cmyk.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'ncol.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'lab.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'oklab.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'lch.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'oklch.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'parse.ps1' }
        @{ Dir = 'conversion-modules/media/colors'; File = 'convert.ps1' }
    )
    
    'Ensure-FileConversion-Specialized' = @(
        @{ Dir = 'conversion-modules/specialized'; File = 'specialized.ps1' }
    )
    
    'Ensure-FileUtilities'              = @(
        @{ Dir = 'files-modules/inspection'; File = 'files-head-tail.ps1' }
        @{ Dir = 'files-modules/inspection'; File = 'files-hash.ps1' }
        @{ Dir = 'files-modules/inspection'; File = 'files-size.ps1' }
        @{ Dir = 'files-modules/inspection'; File = 'files-hexdump.ps1' }
        @{ Dir = 'files-modules/navigation'; File = 'files-listing.ps1' }
        @{ Dir = 'files-modules/navigation'; File = 'files-navigation.ps1' }
    )
    
    'Ensure-DevTools'                   = @(
        @{ Dir = 'dev-tools-modules/encoding'; File = 'base-encoding.ps1' }
        @{ Dir = 'dev-tools-modules/encoding'; File = 'encoding.ps1' }
        @{ Dir = 'dev-tools-modules/crypto'; File = 'hash.ps1' }
        @{ Dir = 'dev-tools-modules/crypto'; File = 'jwt.ps1' }
        @{ Dir = 'dev-tools-modules/format'; File = 'diff.ps1' }
        @{ Dir = 'dev-tools-modules/format'; File = 'regex.ps1' }
        @{ Dir = 'dev-tools-modules/format/qrcode'; File = 'qrcode.ps1' }
        @{ Dir = 'dev-tools-modules/format/qrcode'; File = 'qrcode-communication.ps1' }
        @{ Dir = 'dev-tools-modules/format/qrcode'; File = 'qrcode-formats.ps1' }
        @{ Dir = 'dev-tools-modules/format/qrcode'; File = 'qrcode-specialized.ps1' }
        @{ Dir = 'dev-tools-modules/data'; File = 'timestamp.ps1' }
        @{ Dir = 'dev-tools-modules/data'; File = 'uuid.ps1' }
        @{ Dir = 'dev-tools-modules/data'; File = 'lorem.ps1' }
        @{ Dir = 'dev-tools-modules/data'; File = 'number-base.ps1' }
        @{ Dir = 'dev-tools-modules/data'; File = 'units.ps1' }
    )
    
    'Ensure-Utilities'                  = @(
        # System utilities (profile management, security, environment)
        @{ Dir = 'utilities-modules/system'; File = 'utilities-profile.ps1' }
        @{ Dir = 'utilities-modules/system'; File = 'utilities-security.ps1' }
        @{ Dir = 'utilities-modules/system'; File = 'utilities-env.ps1' }
        # Network utilities (connectivity, DNS, port checking)
        @{ Dir = 'utilities-modules/network'; File = 'utilities-network.ps1' }
        # Command history utilities (search, filtering, management)
        @{ Dir = 'utilities-modules/history'; File = 'utilities-history.ps1' }
        # Data utilities (encoding, date/time manipulation)
        @{ Dir = 'utilities-modules/data'; File = 'utilities-encoding.ps1' }
        @{ Dir = 'utilities-modules/data'; File = 'utilities-datetime.ps1' }
        # Filesystem utilities (path manipulation, directory operations)
        @{ Dir = 'utilities-modules/filesystem'; File = 'utilities-filesystem.ps1' }
    )
    
    'Ensure-System'                     = @(
        @{ Dir = 'system'; File = 'FileOperations.ps1' }
        @{ Dir = 'system'; File = 'SystemInfo.ps1' }
        @{ Dir = 'system'; File = 'NetworkOperations.ps1' }
        @{ Dir = 'system'; File = 'ArchiveOperations.ps1' }
        @{ Dir = 'system'; File = 'EditorAliases.ps1' }
        @{ Dir = 'system'; File = 'TextSearch.ps1' }
    )
    
    'Ensure-Git'                        = @(
        @{ Dir = 'git-modules/core'; File = 'git-helpers.ps1' }
        @{ Dir = 'git-modules/core'; File = 'git-basic.ps1' }
        @{ Dir = 'git-modules/core'; File = 'git-advanced.ps1' }
        @{ Dir = 'git-modules/integrations'; File = 'git-github.ps1' }
    )
}

<#
.SYNOPSIS
    Loads modules for a specific Ensure function from the registry.

.DESCRIPTION
    Loads all modules associated with an Ensure function from the module registry.
    This enables deferred loading - modules are only loaded when their Ensure function is called.

.PARAMETER EnsureFunctionName
    The name of the Ensure function (e.g., 'Ensure-FileConversion-Data').

.PARAMETER BaseDir
    The base directory for resolving module paths (typically $PSScriptRoot).

.EXAMPLE
    Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Data' -BaseDir $PSScriptRoot
#>
function Load-EnsureModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnsureFunctionName,
        
        [Parameter(Mandatory)]
        [string]$BaseDir
    )
    
    if (-not $script:FileConversionModuleRegistry.ContainsKey($EnsureFunctionName)) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "No module registry entry for $EnsureFunctionName"
        }
        return
    }
    
    $modules = $script:FileConversionModuleRegistry[$EnsureFunctionName]
    $loadedCount = 0
    $failedCount = 0
    
    # Use standardized Import-FragmentModule if available, otherwise fall back to direct loading
    $useStandardizedLoading = Get-Command Import-FragmentModule -ErrorAction SilentlyContinue
    
    foreach ($module in $modules) {
        if ($useStandardizedLoading) {
            # Use standardized module loading
            # Convert registry format (Dir = 'conversion-modules/helpers', File = 'helpers-xml.ps1')
            # to ModulePath array format: @('conversion-modules', 'helpers', 'helpers-xml.ps1')
            $pathSegments = $module.Dir -split '/'
            $modulePath = $pathSegments + $module.File
            
            $context = "Fragment: $EnsureFunctionName ($($module.File))"
            
            $success = Import-FragmentModule `
                -FragmentRoot $BaseDir `
                -ModulePath $modulePath `
                -Context $context `
                -CacheResults
            
            if ($success) {
                $loadedCount++
            }
            else {
                $failedCount++
            }
        }
        else {
            # Fallback: direct dot-sourcing (for environments where Import-FragmentModule is not available)
            $modulePath = Join-Path $BaseDir $module.Dir $module.File
            
            # Use cached path check if available
            $moduleExists = if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath)) {
                if (Get-Command Test-ModulePath -ErrorAction SilentlyContinue) {
                    Test-ModulePath -Path $modulePath
                }
                else {
                    Test-Path -LiteralPath $modulePath -ErrorAction SilentlyContinue
                }
            }
            else {
                $false
            }
            
            if ($moduleExists) {
                try {
                    . $modulePath
                    $loadedCount++
                }
                catch {
                    $failedCount++
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Failed to load module $($module.File): $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    
    if ($env:PS_PROFILE_DEBUG -and ($loadedCount -gt 0 -or $failedCount -gt 0)) {
        Write-Verbose "Loaded $loadedCount modules for $EnsureFunctionName (failed: $failedCount)"
    }
}
