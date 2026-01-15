# mobile-dev.ps1

Mobile development tools fragment.

## Overview

This fragment provides wrapper functions for mobile development tools, including Android development (Android Studio, ADB, scrcpy, APK installation, flashing) and iOS development (libimobiledevice). Functions support device connection, screen mirroring, APK installation, and device management.

## Functions

### Connect-AndroidDevice

Connects to an Android device via ADB (Android Debug Bridge).

**Syntax:**

```powershell
Connect-AndroidDevice [-DeviceIp <string>] [-Port <int>] [-ListDevices] [<CommonParameters>]
```

**Parameters:**

- `-DeviceIp` (Optional): IP address for network connection. If not provided, connects via USB.
- `-Port` (Optional): Port for network connection. Defaults to 5555.
- `-ListDevices` (Switch): List all connected devices.

**Examples:**

```powershell
# Connect to Android device via USB
Connect-AndroidDevice

# Connect to Android device via network
Connect-AndroidDevice -DeviceIp "192.168.1.100"

# List all connected devices
Connect-AndroidDevice -ListDevices
```

**Supported Tools:**

- `adb` - Android Debug Bridge (required)

**Notes:**

- Returns array of device IDs on success
- Returns empty array if no devices found
- Network connection requires device to be in USB debugging mode with network debugging enabled

---

### Mirror-AndroidScreen

Mirrors Android device screen using scrcpy.

**Syntax:**

```powershell
Mirror-AndroidScreen [-DeviceId <string>] [-Fullscreen] [-StayAwake] [-MaxSize <int>] [-Bitrate <int>] [<CommonParameters>]
```

**Parameters:**

- `-DeviceId` (Optional): Device ID to mirror. If not provided, uses first connected device.
- `-Fullscreen` (Switch): Start in fullscreen mode.
- `-StayAwake` (Switch): Keep device awake while mirroring.
- `-MaxSize` (Optional): Maximum resolution (e.g., 1920 for 1920px width).
- `-Bitrate` (Optional): Video bitrate in Mbps. Defaults to 8.

**Examples:**

```powershell
# Mirror Android device screen
Mirror-AndroidScreen

# Mirror in fullscreen with stay-awake enabled
Mirror-AndroidScreen -Fullscreen -StayAwake

# Mirror with specific device and quality settings
Mirror-AndroidScreen -DeviceId "device123" -MaxSize 1920 -Bitrate 16
```

**Supported Tools:**

- `scrcpy` - Android screen mirroring tool (required)

**Notes:**

- Creates process asynchronously (non-blocking)
- Supports touch input and screen control
- Returns nothing on success

---

### Install-Apk

Installs an APK file on Android device.

**Syntax:**

```powershell
Install-Apk -ApkPath <string> [-DeviceId <string>] [-ReplaceExisting] [-GrantPermissions] [<CommonParameters>]
```

**Parameters:**

- `-ApkPath` (Required): Path to the APK file to install.
- `-DeviceId` (Optional): Device ID to install on. If not provided, uses first connected device.
- `-ReplaceExisting` (Switch): Replace existing application if already installed.
- `-GrantPermissions` (Switch): Grant all runtime permissions automatically.

**Examples:**

```powershell
# Install an APK file
Install-Apk -ApkPath "app.apk"

# Install APK, replacing existing app and granting permissions
Install-Apk -ApkPath "app.apk" -ReplaceExisting -GrantPermissions

# Install on specific device
Install-Apk -ApkPath "app.apk" -DeviceId "device123"
```

**Supported Tools:**

- `adb` - Android Debug Bridge (required)

**Notes:**

- Returns `$true` if installation succeeded, `$false` otherwise
- Validates APK file exists before installation
- Requires device to be connected and authorized

---

### Connect-IOSDevice

Connects to an iOS device using libimobiledevice.

**Syntax:**

```powershell
Connect-IOSDevice [-ListDevices] [-DeviceId <string>] [<CommonParameters>]
```

**Parameters:**

- `-ListDevices` (Switch): List all connected iOS devices.
- `-DeviceId` (Optional): Device UDID to connect to. If not provided, uses first connected device.

**Examples:**

```powershell
# Connect to iOS device
Connect-IOSDevice

# List all connected iOS devices
Connect-IOSDevice -ListDevices

# Connect to specific device
Connect-IOSDevice -DeviceId "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
```

**Supported Tools:**

- `libimobiledevice` - iOS device library (provides `idevice_id` command)

**Notes:**

- Returns array of device UDIDs on success
- Returns empty array if no devices found
- Requires device to be connected via USB and trusted

---

### Flash-Android

Flashes Android device firmware using PixelFlasher.

**Syntax:**

```powershell
Flash-Android [-FirmwarePath <string>] [<CommonParameters>]
```

**Parameters:**

- `-FirmwarePath` (Optional): Path to firmware file (optional - can be selected in GUI).

**Examples:**

```powershell
# Launch PixelFlasher
Flash-Android

# Launch PixelFlasher with firmware file
Flash-Android -FirmwarePath "firmware.zip"
```

**Supported Tools:**

- `pixelflasher` - Android flasher tool (required)

**Notes:**

- PixelFlasher is a GUI tool for Android device flashing
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Start-AndroidStudio

Launches Android Studio IDE.

**Syntax:**

```powershell
Start-AndroidStudio [-ProjectPath <string>] [<CommonParameters>]
```

**Parameters:**

- `-ProjectPath` (Optional): Path to project to open.

**Examples:**

```powershell
# Launch Android Studio
Start-AndroidStudio

# Launch Android Studio and open a project
Start-AndroidStudio -ProjectPath "C:\Projects\MyApp"
```

**Supported Tools:**

- `android-studio-canary` - Android Studio canary build (preferred)
- `android-studio` - Android Studio stable build (fallback)

**Notes:**

- Prefers android-studio-canary over android-studio when both are available
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

## Installation

Install mobile development tools using Scoop:

```powershell
# Android tools
scoop install adb
scoop install scrcpy
scoop install android-studio-canary
scoop install pixelflasher
scoop install apk-editor-studio

# iOS tools
scoop install libimobiledevice
scoop install altserver

# General
scoop install qflipper
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null`, empty arrays, or `$false` when tools are unavailable
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless explicitly requested with `-ErrorAction Stop`)

## Testing

Comprehensive test coverage includes:

- Unit tests for Android functions (Connect-AndroidDevice, Mirror-AndroidScreen, Install-Apk, Flash-Android, Start-AndroidStudio)
- Unit tests for iOS functions (Connect-IOSDevice)
- Integration tests for module loading and function registration
- Performance tests for load time and execution speed
- Graceful degradation tests for missing tools

Run tests:

```powershell
# Unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/mobile-dev.ps1

# Integration tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/tools/mobile-dev.tests.ps1

# Performance tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/performance/mobile-dev-performance.tests.ps1
```

## Notes

- All device operations require physical device connection (USB or network)
- Android devices must have USB debugging enabled
- iOS devices must be trusted and connected via USB
- Screen mirroring and device operations are non-blocking (asynchronous)
- APK installation requires device authorization
