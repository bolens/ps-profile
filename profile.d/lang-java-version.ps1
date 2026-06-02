# ===============================================
# lang-java-version.ps1
# Java version management
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Java version management.

.DESCRIPTION
    Provides wrapper functions for Java development tools:
    - Set-JavaVersion: Switch between Java versions via JAVA_HOME

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-java-version') { return }
    }

    # ===============================================
    # Java Version Management
    # ===============================================

    <#
    .SYNOPSIS
        Switches Java version using JAVA_HOME.

    .DESCRIPTION
        Helper function to switch Java versions by setting JAVA_HOME environment variable.
        This is a simple wrapper that sets JAVA_HOME to point to a specific Java installation.

    .PARAMETER Version
        Java version to switch to (e.g., '17', '21', '11').
        If not specified, displays current Java version.

    .PARAMETER JavaHome
        Full path to Java installation directory.
        If not specified, attempts to find Java in common locations.

    .EXAMPLE
        Set-JavaVersion -Version 17
        Switches to Java 17 (if available).

    .EXAMPLE
        Set-JavaVersion -JavaHome "C:\Program Files\Java\jdk-17"
        Sets JAVA_HOME to the specified path.

    .OUTPUTS
        System.String. Current Java version information.
    #>
    function Set-JavaVersion {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Version,

            [Parameter()]
            [string]$JavaHome
        )

        # If no parameters, show current Java version
        if (-not $Version -and -not $JavaHome) {
            # First check if JAVA_HOME or JRE_HOME is already set
            if ($env:JAVA_HOME -and (Test-Path -LiteralPath $env:JAVA_HOME -PathType Container)) {
                Write-Host "JAVA_HOME is set to: $env:JAVA_HOME" -ForegroundColor Cyan
            }
            if ($env:JRE_HOME -and (Test-Path -LiteralPath $env:JRE_HOME -PathType Container)) {
                Write-Host "JRE_HOME is set to: $env:JRE_HOME" -ForegroundColor Cyan
            }
            if ($env:JDK_HOME -and (Test-Path -LiteralPath $env:JDK_HOME -PathType Container)) {
                Write-Host "JDK_HOME is set to: $env:JDK_HOME" -ForegroundColor Cyan
            }
            
            if (Test-CachedCommand 'java') {
                try {
                    $versionOutput = & java -version 2>&1
                    return $versionOutput
                }
                catch {
                    Write-Warning "Failed to get Java version: $($_.Exception.Message)"
                    return $null
                }
            }
            else {
                Write-Warning "Java not found in PATH. Set JAVA_HOME or install Java."
                return $null
            }
        }

        # If JavaHome is specified, use it directly
        if ($JavaHome) {
            if (Test-Path -LiteralPath $JavaHome -PathType Container) {
                $env:JAVA_HOME = $JavaHome
                $env:PATH = (Join-Path $JavaHome "bin") + [System.IO.Path]::PathSeparator + $env:PATH
                Write-Host "JAVA_HOME set to: $JavaHome" -ForegroundColor Green
                return "JAVA_HOME set to: $JavaHome"
            }
            else {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.DirectoryNotFoundException]::new("Java installation not found at: $JavaHome"),
                        'JavaHomeNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $JavaHome
                    )) -OperationName 'java.version.set' -Context @{ java_home = $JavaHome }
                }
                else {
                    Write-Error "Java installation not found at: $JavaHome"
                }
                return $null
            }
        }

        # If Version is specified, try to find it
        if ($Version) {
            $javaBin = if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') { 'java.exe' } else { 'java' }

            # First, check standard environment variables (highest priority)
            # Check if existing JAVA_HOME matches the requested version
            if ($env:JAVA_HOME -and (Test-Path -LiteralPath $env:JAVA_HOME -PathType Container)) {
                $javaExe = Join-Path $env:JAVA_HOME 'bin' $javaBin
                if (Test-Path -LiteralPath $javaExe) {
                    try {
                        $currentVersion = & $javaExe -version 2>&1 | Select-String -Pattern "version `"(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                        if ($currentVersion -eq $Version) {
                            Write-Host "Java $Version already set via JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
                            return "Java $Version already set via JAVA_HOME: $env:JAVA_HOME"
                        }
                    }
                    catch {
                        # Ignore version check errors, continue searching
                    }
                }
            }
            
            # Check other Java-related environment variables that packages might set
            $javaEnvVars = @('JRE_HOME', 'JDK_HOME', 'JAVA_ROOT', 'JAVA_PATH')
            foreach ($envVar in $javaEnvVars) {
                $envVariable = Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue
                $envValue = if ($null -ne $envVariable) { $envVariable.Value } else { $null }
                if ($envValue -and (Test-Path -LiteralPath $envValue -PathType Container)) {
                    $javaExe = Join-Path $envValue 'bin' $javaBin
                    if (Test-Path -LiteralPath $javaExe) {
                        try {
                            $currentVersion = & $javaExe -version 2>&1 | Select-String -Pattern "version `"(\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
                            if ($currentVersion -eq $Version) {
                                Write-Host "Java $Version found via ${envVar}: $envValue" -ForegroundColor Green
                                $env:JAVA_HOME = $envValue
                                $env:PATH = (Join-Path $envValue "bin") + [System.IO.Path]::PathSeparator + $env:PATH
                                return "Java $Version set via ${envVar}: $envValue"
                            }
                        }
                        catch {
                            # Ignore version check errors, continue searching
                        }
                    }
                }
            }
            
            $commonPaths = @()

            $isWin = $IsWindows -or $PSVersionTable.Platform -eq 'Win32NT'

            if ($isWin) {
                # Standard Java installation paths (Windows)
                $commonPaths += "$env:ProgramFiles\Java\jdk-$Version"
                $commonPaths += "$env:ProgramFiles\Java\jdk-$Version*"

                # ProgramFiles(x86) if it exists
                $programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
                if ($programFilesX86) {
                    $commonPaths += "$programFilesX86\Java\jdk-$Version"
                    $commonPaths += "$programFilesX86\Java\jdk-$Version*"
                }

                # Eclipse Adoptium (Temurin) paths
                $commonPaths += "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-$Version*"
                $commonPaths += "$env:ProgramFiles\Eclipse Adoptium\jdk-$Version*"

                # Microsoft OpenJDK paths
                $commonPaths += "$env:ProgramFiles\Microsoft\jdk-$Version"
                $commonPaths += "$env:ProgramFiles\Microsoft\jdk-$Version*"
            }
            else {
                # Standard Java installation paths (Linux/macOS)
                $commonPaths += "/usr/lib/jvm/java-$Version-openjdk-amd64"
                $commonPaths += "/usr/lib/jvm/java-$Version-openjdk-arm64"
                $commonPaths += "/usr/lib/jvm/java-$Version*"
                $commonPaths += "/usr/lib/jvm/temurin-$Version*"
                $commonPaths += "/usr/lib/jvm/jdk-$Version*"
                # macOS (Homebrew / SDKMAN)
                $commonPaths += "/Library/Java/JavaVirtualMachines/jdk-$Version*.jdk/Contents/Home"
                $commonPaths += "/Library/Java/JavaVirtualMachines/temurin-$Version.jdk/Contents/Home"
                # SDKMAN
                $sdkmanDir = if ($env:SDKMAN_DIR) { $env:SDKMAN_DIR } else { Join-Path ($env:HOME ?? '~') '.sdkman' }
                $commonPaths += "$sdkmanDir/candidates/java/$Version*"
            }
            
            # Scoop installation paths (if Scoop is installed)
            $scoopRoot = $null
            if (Get-Command Get-ScoopRoot -ErrorAction SilentlyContinue) {
                $scoopRoot = Get-ScoopRoot
            }
            else {
                # Fallback: Try common Scoop locations
                $scoopRoot = $env:SCOOP
                if (-not $scoopRoot) {
                    $userHome = if (Get-Command Get-UserHome -ErrorAction SilentlyContinue) {
                        Get-UserHome
                    }
                    elseif ($env:HOME) {
                        $env:HOME
                    }
                    elseif ($env:USERPROFILE) {
                        $env:USERPROFILE
                    }
                    else {
                        $null
                    }

                    if ($userHome) {
                        $scoopRoot = Join-Path $userHome 'scoop'
                    }

                    if (-not (Test-Path -LiteralPath $scoopRoot -ErrorAction SilentlyContinue)) {
                        if ($env:LOCALAPPDATA) {
                            $scoopRoot = Join-Path $env:LOCALAPPDATA 'scoop'
                        }
                    }
                }
            }
            
            if ($scoopRoot -and (Test-Path -LiteralPath $scoopRoot -ErrorAction SilentlyContinue)) {
                # Temurin JDK (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jdk' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jdk' "*$Version*")
                
                # Temurin JRE (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jre' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'temurin-jre' "*$Version*")
                
                # Microsoft OpenJDK (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjdk' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjdk' "*$Version*")
                
                # Microsoft OpenJRE (Scoop)
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjre' 'current')
                $commonPaths += (Join-Path $scoopRoot 'apps' 'microsoft-openjre' "*$Version*")
            }
            
            # Chocolatey installation paths (if Chocolatey is installed)
            $chocoRoot = $null
            if (Get-Command Get-ChocolateyRoot -ErrorAction SilentlyContinue) {
                $chocoRoot = Get-ChocolateyRoot
            }
            else {
                # Fallback: Try common Chocolatey locations
                $chocoRoot = $env:ChocolateyInstall
                if (-not $chocoRoot) {
                    if ($env:ProgramData) {
                        $chocoRoot = Join-Path $env:ProgramData 'chocolatey'
                    }
                    if (-not (Test-Path -LiteralPath $chocoRoot -ErrorAction SilentlyContinue)) {
                        $chocoRoot = 'C:\ProgramData\chocolatey'
                    }
                }
            }
            
            if ($chocoRoot -and (Test-Path -LiteralPath $chocoRoot -ErrorAction SilentlyContinue)) {
                # Get Chocolatey lib directory
                $chocoLib = $null
                if (Get-Command Get-ChocolateyLibPath -ErrorAction SilentlyContinue) {
                    $chocoLib = Get-ChocolateyLibPath -ChocolateyRoot $chocoRoot
                }
                else {
                    $chocoLib = Join-Path $chocoRoot 'lib'
                }
                
                if ($chocoLib -and (Test-Path -LiteralPath $chocoLib -PathType Container)) {
                    # Look for JDK packages (temurin, microsoft-openjdk, etc.)
                    $commonPaths += (Join-Path $chocoLib "temurin*$Version*")
                    $commonPaths += (Join-Path $chocoLib "microsoft-openjdk*$Version*")
                    $commonPaths += (Join-Path $chocoLib "openjdk*$Version*")
                    $commonPaths += (Join-Path $chocoLib "jdk*$Version*")
                }
            }

            $foundPath = $null
            foreach ($path in $commonPaths) {
                if (Test-Path -LiteralPath $path -PathType Container) {
                    $foundPath = $path
                    break
                }
                # Try wildcard matching
                $parentPath = Split-Path -Parent $path
                $filter = Split-Path -Leaf $path
                if (Test-Path -LiteralPath $parentPath -PathType Container) {
                    $wildcardPaths = Get-ChildItem -Path $parentPath -Filter $filter -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
                    if ($wildcardPaths) {
                        $foundPath = $wildcardPaths[0].FullName
                        break
                    }
                }
            }

            if ($foundPath) {
                $env:JAVA_HOME = $foundPath
                $env:PATH = (Join-Path $foundPath "bin") + [System.IO.Path]::PathSeparator + $env:PATH
                Write-Host "Switched to Java $Version at: $foundPath" -ForegroundColor Green
                return "Switched to Java $Version at: $foundPath"
            }
            else {
                Write-Warning "Java $Version not found in common locations. Use -JavaHome to specify the path."
                return $null
            }
        }

        return $null
    }

    Set-AgentModeFunction -Name 'Set-JavaVersion' -Body ${function:Set-JavaVersion}
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-java-version'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-java-version' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-java-version fragment: $($_.Exception.Message)"
    }
}
