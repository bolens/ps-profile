# ===============================================
# Image media format conversion utilities - Common Helpers
# Shared helper functions for all image format conversions
# ===============================================

<#
.SYNOPSIS
    Initializes common image conversion helper functions.
.DESCRIPTION
    Sets up shared helper functions used by all image format conversion modules.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaImagesCommon {
    # Helper function to check for ImageMagick or GraphicsMagick
    Set-Item -Path Function:Global:_Ensure-ImageMagick -Value {
        # Try ImageMagick 7+ first ('magick' command)
        $magickCmd = Get-Command magick -ErrorAction SilentlyContinue
        if ($magickCmd) {
            return @{ Name = 'magick'; Type = 'ImageMagick7' }
        }
        
        # Try ImageMagick 6 ('convert' command - but need to distinguish from GraphicsMagick)
        $convertCmd = Get-Command convert -ErrorAction SilentlyContinue
        if ($convertCmd) {
            # Check if it's ImageMagick or GraphicsMagick by checking version output
            try {
                $versionOutput = & convert -version 2>&1 | Out-String
                if ($versionOutput -match 'ImageMagick') {
                    return @{ Name = 'convert'; Type = 'ImageMagick6' }
                }
                elseif ($versionOutput -match 'GraphicsMagick') {
                    return @{ Name = 'convert'; Type = 'GraphicsMagick' }
                }
            }
            catch {
                # If version check fails, assume ImageMagick 6
                return @{ Name = 'convert'; Type = 'ImageMagick6' }
            }
        }
        
        # Try GraphicsMagick 'gm' command
        $gmCmd = Get-Command gm -ErrorAction SilentlyContinue
        if ($gmCmd) {
            return @{ Name = 'gm'; Type = 'GraphicsMagick' }
        }
        
        throw "ImageMagick or GraphicsMagick command not found. Please install one of them to use image conversion functions. " +
        "ImageMagick: scoop install imagemagick (Windows), apt install imagemagick (Linux), or brew install imagemagick (macOS). " +
        "GraphicsMagick: scoop install graphicsmagick (Windows), apt install graphicsmagick (Linux), or brew install graphicsmagick (macOS)"
    } -Force

    # Helper function for generic image conversion
    Set-Item -Path Function:Global:_Convert-ImageFormat -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [hashtable]$Options = @{}
        )
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            $magickInfo = _Ensure-ImageMagick
            $magickCmd = $magickInfo.Name
            $magickType = $magickInfo.Type
            
            if (-not $OutputPath) {
                throw "OutputPath parameter is required"
            }
            
            # Build command arguments based on tool type
            if ($magickType -eq 'GraphicsMagick' -and $magickCmd -eq 'gm') {
                # GraphicsMagick 'gm' command format: gm convert input [options] output
                $magickArgs = @('convert', $InputPath)
                
                # Add custom options
                foreach ($key in $Options.Keys) {
                    if ($Options[$key] -is [switch] -and $Options[$key]) {
                        $magickArgs += "-$key"
                    }
                    elseif ($Options[$key] -is [switch] -and -not $Options[$key]) {
                        # Skip false switches
                    }
                    else {
                        $magickArgs += "-$key"
                        $magickArgs += $Options[$key]
                    }
                }
                
                $magickArgs += $OutputPath
            }
            else {
                # ImageMagick format (magick or convert): command input [options] output
                $magickArgs = @($InputPath)
                
                # Add custom options
                foreach ($key in $Options.Keys) {
                    if ($Options[$key] -is [switch] -and $Options[$key]) {
                        $magickArgs += "-$key"
                    }
                    elseif ($Options[$key] -is [switch] -and -not $Options[$key]) {
                        # Skip false switches
                    }
                    else {
                        $magickArgs += "-$key"
                        $magickArgs += $Options[$key]
                    }
                }
                
                $magickArgs += $OutputPath
            }
            
            # Execute command
            $errorOutput = & $magickCmd $magickArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $toolName = if ($magickType -eq 'GraphicsMagick') { 'GraphicsMagick' } else { 'ImageMagick' }
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                $optionsSummary = if ($Options -and $Options.Keys.Count -gt 0) {
                    ($Options.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
                }
                else {
                    'none'
                }
                throw "$toolName failed with exit code $exitCode while converting image from '$InputPath' to '$OutputPath' (options: $optionsSummary). Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert image: $($_.Exception.Message)"
            throw
        }
    } -Force
}

