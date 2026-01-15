# ===============================================
# re-tools.ps1
# Reverse engineering and analysis tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Reverse engineering and analysis tools fragment.

.DESCRIPTION
    Provides wrapper functions for reverse engineering and analysis tools:
    - Java/Dex decompilers: jadx, bytecode-viewer, recaf
    - .NET decompilers: dnspy, dnspyex
    - PE analyzers: exeinfo-pe, pe-bear, detect-it-easy
    - Android tools: apktool, baksmali, smali, dex2jar, axmlprinter, classyshark
    - IL2CPP tools: il2cppdumper
    - Hex editors: hxd, hexed, hexyl
    - General: ghidra, boomerang, hollows-hunter

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides reverse engineering and binary analysis capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 're-tools') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Decompile-Java - Decompile Java/Dex files
    # ===============================================

    <#
    .SYNOPSIS
        Decompiles Java or Dex files using jadx.
    
    .DESCRIPTION
        Decompiles Java class files or Android Dex files to Java source code using jadx.
        Supports .class, .jar, .dex, and .apk files.
    
    .PARAMETER InputFile
        Path to the Java/Dex file to decompile.
    
    .PARAMETER OutputPath
        Directory to save decompiled source. Defaults to current directory.
    
    .PARAMETER DecompileResources
        Also decompile resources (for APK files).
    
    .EXAMPLE
        Decompile-Java -InputFile "app.dex"
        
        Decompiles a Dex file to Java source.
    
    .EXAMPLE
        Decompile-Java -InputFile "app.apk" -DecompileResources
        
        Decompiles an APK file including resources.
    
    .OUTPUTS
        System.String. Path to the output directory.
    #>
    function Decompile-Java {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputFile,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [switch]$DecompileResources
        )

        if (-not (Test-CachedCommand 'jadx')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'jadx' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'jadx' -InstallHint $installHint
            }
            else {
                Write-Warning "jadx is not installed. Install it with: scoop install jadx"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputFile)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Input file not found: $InputFile"),
                        'InputFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $InputFile
                    )) -OperationName 're-tools.decompile-java' -Context @{ input_file = $InputFile }
            }
            else {
                Write-Error "Input file not found: $InputFile"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('-d', $OutputPath)
        
        if ($DecompileResources) {
            $arguments += '--no-res'
        }
        
        $arguments += $InputFile

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 're-tools.decompile-java' -Context @{
                input_file          = $InputFile
                output_path         = $OutputPath
                decompile_resources = $DecompileResources.IsPresent
            } -ScriptBlock {
                $output = & jadx $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Decompilation failed. Exit code: $LASTEXITCODE"
                }
                return $OutputPath
            }
        }
        else {
            try {
                $output = & jadx $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $OutputPath
                }
                else {
                    Write-Error "Decompilation failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to decompile Java/Dex file: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Decompile-DotNet - Decompile .NET assemblies
    # ===============================================

    <#
    .SYNOPSIS
        Decompiles .NET assemblies using dnspy or dnspyex.
    
    .DESCRIPTION
        Decompiles .NET assemblies (.dll, .exe) to C# source code.
        Prefers dnspyex if available, falls back to dnspy.
    
    .PARAMETER InputFile
        Path to the .NET assembly to decompile.
    
    .PARAMETER OutputPath
        Directory to save decompiled source. Defaults to current directory.
    
    .PARAMETER OutputFormat
        Output format: 'cs' (C#) or 'il' (IL). Defaults to 'cs'.
    
    .EXAMPLE
        Decompile-DotNet -InputFile "app.dll"
        
        Decompiles a .NET assembly to C# source.
    
    .OUTPUTS
        System.String. Path to the output file.
    #>
    function Decompile-DotNet {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputFile,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [ValidateSet('cs', 'il')]
            [string]$OutputFormat = 'cs'
        )

        # Prefer dnspyex, fallback to dnspy
        $tool = $null
        if (Test-CachedCommand 'dnspyex') {
            $tool = 'dnspyex'
        }
        elseif (Test-CachedCommand 'dnspy') {
            $tool = 'dnspy'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'dnspyex' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'dnspyex' -InstallHint $installHint
            }
            else {
                Write-Warning "dnspyex or dnspy is not installed. Install it with: scoop install dnspyex"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputFile)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Input file not found: $InputFile"),
                        'InputFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $InputFile
                    )) -OperationName 're-tools.decompile-dotnet' -Context @{ input_file = $InputFile }
            }
            else {
                Write-Error "Input file not found: $InputFile"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $outputFile = Join-Path $OutputPath ([System.IO.Path]::GetFileNameWithoutExtension($InputFile) + ".$OutputFormat")

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 're-tools.decompile-dotnet' -Context @{
                input_file    = $InputFile
                output_path   = $OutputPath
                output_format = $OutputFormat
                tool          = $tool
            } -ScriptBlock {
                # dnspy/dnspyex are GUI tools, but can be used via command line
                # Note: Command-line support may be limited
                $arguments = @('-o', $outputFile, $InputFile)
                
                $output = & $tool $arguments 2>&1
                if ($LASTEXITCODE -eq 0 -or (Test-Path -LiteralPath $outputFile)) {
                    return $outputFile
                }
                else {
                    Write-Warning "Decompilation may have failed. dnspy/dnspyex are primarily GUI tools. Check output file: $outputFile"
                    return $outputFile
                }
            }
        }
        else {
            try {
                # dnspy/dnspyex are GUI tools, but can be used via command line
                # Note: Command-line support may be limited
                $arguments = @('-o', $outputFile, $InputFile)
                
                $output = & $tool $arguments 2>&1
                if ($LASTEXITCODE -eq 0 -or (Test-Path -LiteralPath $outputFile)) {
                    return $outputFile
                }
                else {
                    Write-Warning "Decompilation may have failed. dnspy/dnspyex are primarily GUI tools. Check output file: $outputFile"
                    return $outputFile
                }
            }
            catch {
                Write-Error "Failed to decompile .NET assembly: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Analyze-PE - Analyze PE files
    # ===============================================

    <#
    .SYNOPSIS
        Analyzes PE (Portable Executable) files.
    
    .DESCRIPTION
        Analyzes Windows PE files (.exe, .dll) for metadata, imports, exports, and structure.
        Prefers pe-bear if available, falls back to exeinfo-pe or detect-it-easy.
    
    .PARAMETER InputFile
        Path to the PE file to analyze.
    
    .PARAMETER OutputPath
        File to save analysis results. Optional.
    
    .PARAMETER Detailed
        Show detailed analysis information.
    
    .EXAMPLE
        Analyze-PE -InputFile "app.exe"
        
        Analyzes a PE file and displays results.
    
    .OUTPUTS
        System.String. Analysis results or path to output file.
    #>
    function Analyze-PE {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputFile,
            
            [string]$OutputPath,
            
            [switch]$Detailed
        )

        # Prefer pe-bear, fallback to exeinfo-pe or detect-it-easy
        $tool = $null
        if (Test-CachedCommand 'pe-bear') {
            $tool = 'pe-bear'
        }
        elseif (Test-CachedCommand 'exeinfo-pe') {
            $tool = 'exeinfo-pe'
        }
        elseif (Test-CachedCommand 'detect-it-easy') {
            $tool = 'detect-it-easy'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'pe-bear' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'pe-bear' -InstallHint $installHint
            }
            else {
                Write-Warning "pe-bear, exeinfo-pe, or detect-it-easy is not installed. Install it with: scoop install pe-bear"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputFile)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Input file not found: $InputFile"),
                        'InputFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $InputFile
                    )) -OperationName 're-tools.analyze-pe' -Context @{ input_file = $InputFile }
            }
            else {
                Write-Error "Input file not found: $InputFile"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 're-tools.analyze-pe' -Context @{
                input_file  = $InputFile
                output_path = $OutputPath
                detailed    = $Detailed.IsPresent
                tool        = $tool
            } -ScriptBlock {
                if ($tool -eq 'pe-bear') {
                    # pe-bear is primarily a GUI tool
                    if ($OutputPath) {
                        $arguments = @('-o', $OutputPath, $InputFile)
                    }
                    else {
                        $arguments = @($InputFile)
                    }
                    
                    $output = & pe-bear $arguments 2>&1
                    if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
                        return $OutputPath
                    }
                    return "Analysis started. pe-bear is a GUI tool - check the application window."
                }
                elseif ($tool -eq 'exeinfo-pe') {
                    $arguments = @($InputFile)
                    if ($OutputPath) {
                        $arguments += '-o', $OutputPath
                    }
                    
                    $output = & exeinfo-pe $arguments 2>&1
                    if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
                        return $OutputPath
                    }
                    return $output
                }
                elseif ($tool -eq 'detect-it-easy') {
                    # detect-it-easy is primarily a GUI tool
                    $output = & detect-it-easy $InputFile 2>&1
                    return "Analysis started. detect-it-easy is a GUI tool - check the application window."
                }
            }
        }
        else {
            try {
                if ($tool -eq 'pe-bear') {
                    # pe-bear is primarily a GUI tool
                    if ($OutputPath) {
                        $arguments = @('-o', $OutputPath, $InputFile)
                    }
                    else {
                        $arguments = @($InputFile)
                    }
                    
                    $output = & pe-bear $arguments 2>&1
                    if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
                        return $OutputPath
                    }
                    return "Analysis started. pe-bear is a GUI tool - check the application window."
                }
                elseif ($tool -eq 'exeinfo-pe') {
                    $arguments = @($InputFile)
                    if ($OutputPath) {
                        $arguments += '-o', $OutputPath
                    }
                    
                    $output = & exeinfo-pe $arguments 2>&1
                    if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
                        return $OutputPath
                    }
                    return $output
                }
                elseif ($tool -eq 'detect-it-easy') {
                    # detect-it-easy is primarily a GUI tool
                    $output = & detect-it-easy $InputFile 2>&1
                    return "Analysis started. detect-it-easy is a GUI tool - check the application window."
                }
            }
            catch {
                Write-Error "Failed to analyze PE file: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Extract-AndroidApk - Extract Android APK
    # ===============================================

    <#
    .SYNOPSIS
        Extracts and decompiles Android APK files.
    
    .DESCRIPTION
        Extracts Android APK files using apktool.
        Can extract resources, decompile to smali, or both.
    
    .PARAMETER InputFile
        Path to the APK file to extract.
    
    .PARAMETER OutputPath
        Directory to save extracted files. Defaults to current directory.
    
    .PARAMETER Decompile
        Decompile to smali code (default: extract resources only).
    
    .PARAMETER NoResources
        Do not extract resources.
    
    .EXAMPLE
        Extract-AndroidApk -InputFile "app.apk"
        
        Extracts resources from an APK file.
    
    .EXAMPLE
        Extract-AndroidApk -InputFile "app.apk" -Decompile
        
        Extracts and decompiles an APK file to smali.
    
    .OUTPUTS
        System.String. Path to the output directory.
    #>
    function Extract-AndroidApk {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputFile,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [switch]$Decompile,
            
            [switch]$NoResources
        )

        if (-not (Test-CachedCommand 'apktool')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'apktool' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'apktool' -InstallHint $installHint
            }
            else {
                Write-Warning "apktool is not installed. Install it with: scoop install apktool"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputFile)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Input file not found: $InputFile"),
                        'InputFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $InputFile
                    )) -OperationName 're-tools.extract-apk' -Context @{ input_file = $InputFile }
            }
            else {
                Write-Error "Input file not found: $InputFile"
            }
            return
        }

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
        $finalOutputPath = Join-Path $OutputPath $baseName

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('d', '-o', $finalOutputPath)
        
        if ($NoResources) {
            $arguments += '--no-res'
        }
        
        if (-not $Decompile) {
            $arguments += '--no-src'
        }
        
        $arguments += $InputFile

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 're-tools.extract-apk' -Context @{
                input_file   = $InputFile
                output_path  = $OutputPath
                decompile    = $Decompile.IsPresent
                no_resources = $NoResources.IsPresent
            } -ScriptBlock {
                $output = & apktool $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "APK extraction failed. Exit code: $LASTEXITCODE"
                }
                return $finalOutputPath
            }
        }
        else {
            try {
                $output = & apktool $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $finalOutputPath
                }
                else {
                    Write-Error "APK extraction failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to extract Android APK: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Dump-IL2CPP - Dump IL2CPP metadata
    # ===============================================

    <#
    .SYNOPSIS
        Dumps IL2CPP metadata from Unity games.
    
    .DESCRIPTION
        Extracts IL2CPP metadata and type information from Unity games.
        Requires the game's global-metadata.dat file and the IL2CPP binary.
    
    .PARAMETER MetadataFile
        Path to global-metadata.dat file.
    
    .PARAMETER BinaryFile
        Path to the IL2CPP binary (GameAssembly.dll or libil2cpp.so).
    
    .PARAMETER OutputPath
        Directory to save dumped metadata. Defaults to current directory.
    
    .PARAMETER UnityVersion
        Unity version (optional, for better compatibility).
    
    .EXAMPLE
        Dump-IL2CPP -MetadataFile "global-metadata.dat" -BinaryFile "GameAssembly.dll"
        
        Dumps IL2CPP metadata from a Unity game.
    
    .OUTPUTS
        System.String. Path to the output directory.
    #>
    function Dump-IL2CPP {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$MetadataFile,
            
            [Parameter(Mandatory = $true)]
            [string]$BinaryFile,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [string]$UnityVersion
        )

        if (-not (Test-CachedCommand 'il2cppdumper')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'il2cppdumper' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'il2cppdumper' -InstallHint $installHint
            }
            else {
                Write-Warning "il2cppdumper is not installed. Install it with: scoop install il2cppdumper"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $MetadataFile)) {
            Write-Error "Metadata file not found: $MetadataFile"
            return
        }

        if (-not (Test-Path -LiteralPath $BinaryFile)) {
            Write-Error "Binary file not found: $BinaryFile"
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @($BinaryFile, $MetadataFile, $OutputPath)
        
        if ($UnityVersion) {
            $arguments += '-v', $UnityVersion
        }

        try {
            $output = & il2cppdumper $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "IL2CPP dump failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to dump IL2CPP metadata: $($_.Exception.Message)"
        }
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Decompile-Java' -Body ${function:Decompile-Java}
        Set-AgentModeFunction -Name 'Decompile-DotNet' -Body ${function:Decompile-DotNet}
        Set-AgentModeFunction -Name 'Analyze-PE' -Body ${function:Analyze-PE}
        Set-AgentModeFunction -Name 'Extract-AndroidApk' -Body ${function:Extract-AndroidApk}
        Set-AgentModeFunction -Name 'Dump-IL2CPP' -Body ${function:Dump-IL2CPP}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 're-tools'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: re-tools" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load re-tools fragment: $($_.Exception.Message)"
        }
    }
}
