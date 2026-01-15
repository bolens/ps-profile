# ===============================================
# dart.ps1
# Dart and Flutter package management
# ===============================================

# Dart/Flutter aliases and functions
# Requires: dart or flutter (https://dart.dev/, https://flutter.dev/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand dart)) {
    # Dart pub outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Dart packages.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'dart pub outdated'.
    #>
    function Test-DartOutdated {
        [CmdletBinding()]
        param()
        
        & dart pub outdated
    }
    Set-Alias -Name dart-outdated -Value Test-DartOutdated -ErrorAction SilentlyContinue

    # Dart pub upgrade - update packages
    <#
    .SYNOPSIS
        Updates Dart packages.
    .DESCRIPTION
        Updates all packages to their latest versions within version constraints.
    #>
    function Update-DartPackages {
        [CmdletBinding()]
        param()
        
        & dart pub upgrade
    }
    Set-Alias -Name dart-upgrade -Value Update-DartPackages -ErrorAction SilentlyContinue

    # Dart pub add - add packages
    <#
    .SYNOPSIS
        Adds packages to Dart project.
    .DESCRIPTION
        Adds packages to pubspec.yaml. Supports --dev flag.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Dev
        Add as dev dependency (--dev).
    .EXAMPLE
        Add-DartPackage http
        Adds http as a production dependency.
    .EXAMPLE
        Add-DartPackage build_runner -Dev
        Adds build_runner as a dev dependency.
    #>
    function Add-DartPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        & dart pub add @args @Packages
    }
    Set-Alias -Name dart-add -Value Add-DartPackage -ErrorAction SilentlyContinue

    # Dart pub remove - remove packages
    <#
    .SYNOPSIS
        Removes packages from Dart project.
    .DESCRIPTION
        Removes packages from pubspec.yaml.
    .PARAMETER Packages
        Package names to remove.
    .EXAMPLE
        Remove-DartPackage http
        Removes http from dependencies.
    #>
    function Remove-DartPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        & dart pub remove @Packages
    }
    Set-Alias -Name dart-remove -Value Remove-DartPackage -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'dart' -ToolType 'dart-package' -DefaultInstallCommand 'Install Dart from: https://dart.dev/get-dart or use: scoop install dart-sdk'
    }
    else {
        'Install Dart from: https://dart.dev/get-dart or use: scoop install dart-sdk'
    }
    Write-MissingToolWarning -Tool 'dart' -InstallHint $installHint
}

# Flutter-specific helpers (if flutter is available but dart is not)
# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand flutter)) {
    # Flutter pub outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Flutter packages.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'flutter pub outdated'.
    #>
    function Test-FlutterOutdated {
        [CmdletBinding()]
        param()
        
        & flutter pub outdated
    }
    Set-Alias -Name flutter-outdated -Value Test-FlutterOutdated -ErrorAction SilentlyContinue

    # Flutter pub upgrade - update packages
    <#
    .SYNOPSIS
        Updates Flutter packages.
    .DESCRIPTION
        Updates all packages to their latest versions within version constraints.
    #>
    function Update-FlutterPackages {
        [CmdletBinding()]
        param()
        
        & flutter pub upgrade
    }
    Set-Alias -Name flutter-upgrade -Value Update-FlutterPackages -ErrorAction SilentlyContinue

    # Flutter pub add - add packages
    <#
    .SYNOPSIS
        Adds packages to Flutter project.
    .DESCRIPTION
        Adds packages to pubspec.yaml. Supports --dev flag.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Dev
        Add as dev dependency (--dev).
    .EXAMPLE
        Add-FlutterPackage http
        Adds http as a production dependency.
    .EXAMPLE
        Add-FlutterPackage flutter_test -Dev
        Adds flutter_test as a dev dependency.
    #>
    function Add-FlutterPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        & flutter pub add @args @Packages
    }
    Set-Alias -Name flutter-add -Value Add-FlutterPackage -ErrorAction SilentlyContinue

    # Flutter pub remove - remove packages
    <#
    .SYNOPSIS
        Removes packages from Flutter project.
    .DESCRIPTION
        Removes packages from pubspec.yaml.
    .PARAMETER Packages
        Package names to remove.
    .EXAMPLE
        Remove-FlutterPackage http
        Removes http from dependencies.
    #>
    function Remove-FlutterPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        & flutter pub remove @Packages
    }
    Set-Alias -Name flutter-remove -Value Remove-FlutterPackage -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'flutter' -ToolType 'dart-package' -DefaultInstallCommand 'Install Flutter from: https://flutter.dev/docs/get-started/install or use: scoop install flutter'
    }
    else {
        'Install Flutter from: https://flutter.dev/docs/get-started/install or use: scoop install flutter'
    }
    Write-MissingToolWarning -Tool 'flutter' -InstallHint $installHint
}
