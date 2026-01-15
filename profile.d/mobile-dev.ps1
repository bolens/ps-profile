# ===============================================
# mobile-dev.ps1
# Mobile development tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Mobile development tools fragment.

.DESCRIPTION
    Provides wrapper functions for mobile development tools:
    - Android: Android Studio, ADB, scrcpy (screen mirroring), sndcpy (audio forwarding), APK Editor Studio, PixelFlasher
    - iOS: libimobiledevice, AltServer
    - General: qflipper (Flipper Zero)

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides mobile development and device management capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'mobile-dev') { return }
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
    # Connect-AndroidDevice - Connect Android device
    # ===============================================

    <#
    .SYNOPSIS
        Connects to an Android device via ADB.
    
    .DESCRIPTION
        Connects to an Android device using ADB (Android Debug Bridge).
        Can connect via USB or network (TCP/IP).
    
    .PARAMETER DeviceIp
        IP address for network connection. If not provided, connects via USB.
    
    .PARAMETER Port
        Port for network connection. Defaults to 5555.
    
    .PARAMETER ListDevices
        List all connected devices.
    
    .EXAMPLE
        Connect-AndroidDevice
        
        Connects to Android device via USB.
    
    .EXAMPLE
        Connect-AndroidDevice -DeviceIp "192.168.1.100"
        
        Connects to Android device via network.
    
    .EXAMPLE
        Connect-AndroidDevice -ListDevices
        
        Lists all connected Android devices.
    
    .OUTPUTS
        System.String[]. List of connected devices or connection status.
    #>
    function Connect-AndroidDevice {
        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [string]$DeviceIp,
            
            [int]$Port = 5555,
            
            [switch]$ListDevices
        )

        if (-not (Test-CachedCommand 'adb')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'adb' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'adb' -InstallHint $installHint
            }
            else {
                Write-Warning "adb is not installed. Install it with: scoop install adb"
            }
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'mobile.android.connect' -Context @{
                list_devices = $ListDevices.IsPresent
                device_ip    = $DeviceIp
                port         = $Port
            } -ScriptBlock {
                if ($ListDevices) {
                    $output = & adb devices 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list devices. Exit code: $LASTEXITCODE"
                    }
                    $devices = $output | Where-Object { $_ -match '^\S+\s+device' } | ForEach-Object {
                        ($_ -split '\s+')[0]
                    }
                    return $devices
                }
                elseif ($DeviceIp) {
                    $output = & adb connect "${DeviceIp}:${Port}" 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to connect to device. Exit code: $LASTEXITCODE"
                    }
                    Write-Host "Connected to device at ${DeviceIp}:${Port}"
                    return @("${DeviceIp}:${Port}")
                }
                else {
                    # USB connection - just verify device is connected
                    $output = & adb devices 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to check devices. Exit code: $LASTEXITCODE"
                    }
                    $devices = $output | Where-Object { $_ -match '^\S+\s+device' } | ForEach-Object {
                        ($_ -split '\s+')[0]
                    }
                    if ($devices.Count -eq 0) {
                        Write-Warning "No Android devices found. Connect a device via USB or use -DeviceIp for network connection."
                    }
                    return $devices
                }
            }
        }
        else {
            try {
                if ($ListDevices) {
                    $output = & adb devices 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $devices = $output | Where-Object { $_ -match '^\S+\s+device' } | ForEach-Object {
                            ($_ -split '\s+')[0]
                        }
                        return $devices
                    }
                    else {
                        Write-Error "Failed to list devices. Exit code: $LASTEXITCODE"
                        return @()
                    }
                }
                elseif ($DeviceIp) {
                    $output = & adb connect "${DeviceIp}:${Port}" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Connected to device at ${DeviceIp}:${Port}"
                        return @("${DeviceIp}:${Port}")
                    }
                    else {
                        Write-Error "Failed to connect to device. Exit code: $LASTEXITCODE"
                        return @()
                    }
                }
                else {
                    # USB connection - just verify device is connected
                    $output = & adb devices 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $devices = $output | Where-Object { $_ -match '^\S+\s+device' } | ForEach-Object {
                            ($_ -split '\s+')[0]
                        }
                        if ($devices.Count -eq 0) {
                            Write-Warning "No Android devices found. Connect a device via USB or use -DeviceIp for network connection."
                        }
                        return $devices
                    }
                    else {
                        Write-Error "Failed to check devices. Exit code: $LASTEXITCODE"
                        return @()
                    }
                }
            }
            catch {
                Write-Error "Failed to connect Android device: $($_.Exception.Message)"
                return @()
            }
        }
    }

    # ===============================================
    # Mirror-AndroidScreen - Mirror Android screen
    # ===============================================

    <#
    .SYNOPSIS
        Mirrors Android device screen using scrcpy.
    
    .DESCRIPTION
        Launches scrcpy to mirror and control Android device screen.
        Supports various display options and quality settings.
    
    .PARAMETER DeviceId
        Device ID to mirror. If not provided, uses first connected device.
    
    .PARAMETER Fullscreen
        Start in fullscreen mode.
    
    .PARAMETER StayAwake
        Keep device awake while mirroring.
    
    .PARAMETER MaxSize
        Maximum resolution (e.g., "1920" for 1920px width).
    
    .PARAMETER Bitrate
        Video bitrate in Mbps. Defaults to 8.
    
    .EXAMPLE
        Mirror-AndroidScreen
        
        Mirrors Android device screen.
    
    .EXAMPLE
        Mirror-AndroidScreen -Fullscreen -StayAwake
        
        Mirrors Android device screen in fullscreen with stay-awake enabled.
    
    .OUTPUTS
        None.
    #>
    function Mirror-AndroidScreen {
        [CmdletBinding()]
        param(
            [string]$DeviceId,
            
            [switch]$Fullscreen,
            
            [switch]$StayAwake,
            
            [int]$MaxSize,
            
            [int]$Bitrate = 8
        )

        if (-not (Test-CachedCommand 'scrcpy')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'scrcpy' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'scrcpy' -InstallHint $installHint
            }
            else {
                Write-Warning "scrcpy is not installed. Install it with: scoop install scrcpy"
            }
            return
        }

        $arguments = @()
        
        if ($DeviceId) {
            $arguments += '-s', $DeviceId
        }
        
        if ($Fullscreen) {
            $arguments += '--fullscreen'
        }
        
        if ($StayAwake) {
            $arguments += '--stay-awake'
        }
        
        if ($MaxSize) {
            $arguments += '--max-size', $MaxSize.ToString()
        }
        
        if ($Bitrate) {
            $arguments += '--bit-rate', ($Bitrate * 1000000).ToString()
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'mobile.android.mirror' -Context @{
                device_id  = $DeviceId
                fullscreen = $Fullscreen.IsPresent
                stay_awake = $StayAwake.IsPresent
                max_size   = $MaxSize
                bitrate    = $Bitrate
            } -ScriptBlock {
                Start-Process -FilePath 'scrcpy' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'scrcpy' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to mirror Android screen: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Install-Apk - Install APK files
    # ===============================================

    <#
    .SYNOPSIS
        Installs an APK file on Android device.
    
    .DESCRIPTION
        Installs an APK file on connected Android device using ADB.
        Supports installation options like replacing existing app or granting permissions.
    
    .PARAMETER ApkPath
        Path to the APK file to install.
    
    .PARAMETER DeviceId
        Device ID to install on. If not provided, uses first connected device.
    
    .PARAMETER ReplaceExisting
        Replace existing application if already installed.
    
    .PARAMETER GrantPermissions
        Grant all runtime permissions automatically.
    
    .EXAMPLE
        Install-Apk -ApkPath "app.apk"
        
        Installs an APK file on Android device.
    
    .EXAMPLE
        Install-Apk -ApkPath "app.apk" -ReplaceExisting -GrantPermissions
        
        Installs APK, replacing existing app and granting all permissions.
    
    .OUTPUTS
        System.Boolean. True if installation succeeded, false otherwise.
    #>
    function Install-Apk {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ApkPath,
            
            [string]$DeviceId,
            
            [switch]$ReplaceExisting,
            
            [switch]$GrantPermissions
        )

        if (-not (Test-CachedCommand 'adb')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'adb' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'adb' -InstallHint $installHint
            }
            else {
                Write-Warning "adb is not installed. Install it with: scoop install adb"
            }
            return $false
        }

        if (-not (Test-Path -LiteralPath $ApkPath)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("APK file not found: $ApkPath"),
                        'ApkFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $ApkPath
                    )) -OperationName 'mobile.android.install' -Context @{ apk_path = $ApkPath }
            }
            else {
                Write-Error "APK file not found: $ApkPath"
            }
            return $false
        }

        $arguments = @('install')
        
        if ($ReplaceExisting) {
            $arguments += '-r'
        }
        
        if ($GrantPermissions) {
            $arguments += '-g'
        }
        
        if ($DeviceId) {
            $arguments += '-s', $DeviceId
        }
        
        $arguments += $ApkPath

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'mobile.android.install' -Context @{
                apk_path          = $ApkPath
                device_id         = $DeviceId
                replace_existing  = $ReplaceExisting.IsPresent
                grant_permissions = $GrantPermissions.IsPresent
            } -ScriptBlock {
                $output = & adb $arguments 2>&1
                if ($LASTEXITCODE -ne 0 -and $output -notmatch 'Success') {
                    throw "APK installation failed. Exit code: $LASTEXITCODE"
                }
                Write-Host "APK installed successfully: $ApkPath"
                return $true
            }
        }
        else {
            try {
                $output = & adb $arguments 2>&1
                if ($LASTEXITCODE -eq 0 -or $output -match 'Success') {
                    Write-Host "APK installed successfully: $ApkPath"
                    return $true
                }
                else {
                    Write-Error "APK installation failed. Exit code: $LASTEXITCODE"
                    return $false
                }
            }
            catch {
                Write-Error "Failed to install APK: $($_.Exception.Message)"
                return $false
            }
        }
    }

    # ===============================================
    # Connect-IOSDevice - Connect iOS device
    # ===============================================

    <#
    .SYNOPSIS
        Connects to an iOS device using libimobiledevice.
    
    .DESCRIPTION
        Connects to an iOS device and lists connected devices.
        Uses libimobiledevice tools for iOS device management.
    
    .PARAMETER ListDevices
        List all connected iOS devices.
    
    .PARAMETER DeviceId
        Device UDID to connect to. If not provided, uses first connected device.
    
    .EXAMPLE
        Connect-IOSDevice
        
        Connects to iOS device.
    
    .EXAMPLE
        Connect-IOSDevice -ListDevices
        
        Lists all connected iOS devices.
    
    .OUTPUTS
        System.String[]. List of connected devices or device information.
    #>
    function Connect-IOSDevice {
        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [switch]$ListDevices,
            
            [string]$DeviceId
        )

        if (-not (Test-CachedCommand 'idevice_id')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'libimobiledevice' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'libimobiledevice' -InstallHint $installHint
            }
            else {
                Write-Warning "libimobiledevice is not installed. Install it with: scoop install libimobiledevice"
            }
            return @()
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'mobile.ios.connect' -Context @{
                list_devices = $ListDevices.IsPresent
                device_id    = $DeviceId
            } -ScriptBlock {
                if ($ListDevices -or -not $DeviceId) {
                    $output = & idevice_id -l 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list iOS devices. Exit code: $LASTEXITCODE"
                    }
                    $devices = $output | Where-Object { $_ -match '^[a-f0-9]{40}$' }
                    if ($devices.Count -eq 0) {
                        Write-Warning "No iOS devices found. Connect a device via USB."
                    }
                    return $devices
                }
                else {
                    # Verify specific device is connected
                    $output = & idevice_id -l 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to check iOS devices. Exit code: $LASTEXITCODE"
                    }
                    $devices = $output | Where-Object { $_ -match '^[a-f0-9]{40}$' }
                    if ($devices -contains $DeviceId) {
                        Write-Host "iOS device connected: $DeviceId"
                        return @($DeviceId)
                    }
                    else {
                        Write-Warning "Device $DeviceId not found. Available devices: $($devices -join ', ')"
                        return @()
                    }
                }
            }
        }
        else {
            try {
                if ($ListDevices -or -not $DeviceId) {
                    $output = & idevice_id -l 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $devices = $output | Where-Object { $_ -match '^[a-f0-9]{40}$' }
                        if ($devices.Count -eq 0) {
                            Write-Warning "No iOS devices found. Connect a device via USB."
                        }
                        return $devices
                    }
                    else {
                        Write-Error "Failed to list iOS devices. Exit code: $LASTEXITCODE"
                        return @()
                    }
                }
                else {
                    # Verify specific device is connected
                    $output = & idevice_id -l 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $devices = $output | Where-Object { $_ -match '^[a-f0-9]{40}$' }
                        if ($devices -contains $DeviceId) {
                            Write-Host "iOS device connected: $DeviceId"
                            return @($DeviceId)
                        }
                        else {
                            Write-Warning "Device $DeviceId not found. Available devices: $($devices -join ', ')"
                            return @()
                        }
                    }
                    else {
                        Write-Error "Failed to check iOS devices. Exit code: $LASTEXITCODE"
                        return @()
                    }
                }
            }
            catch {
                Write-Error "Failed to connect iOS device: $($_.Exception.Message)"
                return @()
            }
        }
    }

    # ===============================================
    # Flash-Android - Flash Android device
    # ===============================================

    <#
    .SYNOPSIS
        Flashes Android device firmware using PixelFlasher.
    
    .DESCRIPTION
        Launches PixelFlasher for flashing Android device firmware.
        PixelFlasher is a GUI tool for Android device flashing.
    
    .PARAMETER FirmwarePath
        Path to firmware file (optional - can be selected in GUI).
    
    .EXAMPLE
        Flash-Android
        
        Launches PixelFlasher.
    
    .EXAMPLE
        Flash-Android -FirmwarePath "firmware.zip"
        
        Launches PixelFlasher with firmware file path.
    
    .OUTPUTS
        None.
    #>
    function Flash-Android {
        [CmdletBinding()]
        param(
            [string]$FirmwarePath
        )

        if (-not (Test-CachedCommand 'pixelflasher')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'pixelflasher' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'pixelflasher' -InstallHint $installHint
            }
            else {
                Write-Warning "pixelflasher is not installed. Install it with: scoop install pixelflasher"
            }
            return
        }

        $arguments = @()
        
        if ($FirmwarePath) {
            if (-not (Test-Path -LiteralPath $FirmwarePath)) {
                Write-Error "Firmware file not found: $FirmwarePath"
                return
            }
            $arguments += $FirmwarePath
        }

        try {
            Start-Process -FilePath 'pixelflasher' -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch PixelFlasher: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Start-AndroidStudio - Launch Android Studio
    # ===============================================

    <#
    .SYNOPSIS
        Launches Android Studio IDE.
    
    .DESCRIPTION
        Launches Android Studio for Android app development.
        Prefers android-studio-canary, falls back to android-studio.
    
    .PARAMETER ProjectPath
        Optional path to project to open.
    
    .EXAMPLE
        Start-AndroidStudio
        
        Launches Android Studio.
    
    .EXAMPLE
        Start-AndroidStudio -ProjectPath "C:\Projects\MyApp"
        
        Launches Android Studio and opens a project.
    
    .OUTPUTS
        None.
    #>
    function Start-AndroidStudio {
        [CmdletBinding()]
        param(
            [string]$ProjectPath
        )

        # Prefer android-studio-canary, fallback to android-studio
        $tool = $null
        if (Test-CachedCommand 'android-studio-canary') {
            $tool = 'android-studio-canary'
        }
        elseif (Test-CachedCommand 'android-studio') {
            $tool = 'android-studio'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'android-studio-canary' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'android-studio-canary' -InstallHint $installHint
            }
            else {
                Write-Warning "android-studio-canary or android-studio is not installed. Install it with: scoop install android-studio-canary"
            }
            return
        }

        $arguments = @()
        
        if ($ProjectPath) {
            if (-not (Test-Path -LiteralPath $ProjectPath)) {
                Write-Error "Project path not found: $ProjectPath"
                return
            }
            $arguments += $ProjectPath
        }

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Android Studio: $($_.Exception.Message)"
        }
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Connect-AndroidDevice' -Body ${function:Connect-AndroidDevice}
        Set-AgentModeFunction -Name 'Mirror-AndroidScreen' -Body ${function:Mirror-AndroidScreen}
        Set-AgentModeFunction -Name 'Install-Apk' -Body ${function:Install-Apk}
        Set-AgentModeFunction -Name 'Connect-IOSDevice' -Body ${function:Connect-IOSDevice}
        Set-AgentModeFunction -Name 'Flash-Android' -Body ${function:Flash-Android}
        Set-AgentModeFunction -Name 'Start-AndroidStudio' -Body ${function:Start-AndroidStudio}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'mobile-dev'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: mobile-dev" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load mobile-dev fragment: $($_.Exception.Message)"
        }
    }
}

