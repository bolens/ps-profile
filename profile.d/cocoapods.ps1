# ===============================================
# cocoapods.ps1
# CocoaPods dependency manager (iOS/macOS)
# ===============================================

# CocoaPods aliases and functions
# Requires: pod (CocoaPods - https://cocoapods.org/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand pod)) {
    # CocoaPods install - install dependencies
    <#
    .SYNOPSIS
        Installs CocoaPods dependencies.
    .DESCRIPTION
        Installs dependencies from Podfile. Creates Pods directory and workspace.
    .EXAMPLE
        Install-CocoaPodsDependencies
        Installs all dependencies.
    #>
    function Install-CocoaPodsDependencies {
        [CmdletBinding()]
        param()
        
        & pod install
    }
    Set-Alias -Name podinstall -Value Install-CocoaPodsDependencies -ErrorAction SilentlyContinue

    # CocoaPods update - update dependencies
    <#
    .SYNOPSIS
        Updates CocoaPods dependencies.
    .DESCRIPTION
        Updates dependencies to latest versions allowed by Podfile.
    .PARAMETER Pods
        Specific pod names to update (optional, updates all if omitted).
    .EXAMPLE
        Update-CocoaPodsDependencies
        Updates all dependencies.
    .EXAMPLE
        Update-CocoaPodsDependencies Alamofire
        Updates specific pod.
    #>
    function Update-CocoaPodsDependencies {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Pods
        )
        
        if ($Pods) {
            & pod update @Pods
        }
        else {
            & pod update
        }
    }
    Set-Alias -Name podupdate -Value Update-CocoaPodsDependencies -ErrorAction SilentlyContinue

    # CocoaPods deintegrate - remove CocoaPods
    <#
    .SYNOPSIS
        Removes CocoaPods integration from project.
    .DESCRIPTION
        Removes Pods directory and workspace files.
    .EXAMPLE
        Remove-CocoaPodsIntegration
        Removes CocoaPods from project.
    #>
    function Remove-CocoaPodsIntegration {
        [CmdletBinding()]
        param()
        
        & pod deintegrate
    }
    Set-Alias -Name poddeintegrate -Value Remove-CocoaPodsIntegration -ErrorAction SilentlyContinue
}
else {
    # Check if gem is available - if not, suggest installing ruby first
    $hasGem = Test-CachedCommand gem
    $hasScoop = Test-CachedCommand scoop
    
    $defaultHint = if ($hasGem) {
        'gem install cocoapods'
    }
    elseif ($hasScoop) {
        'scoop install ruby (then: gem install cocoapods)'
    }
    else {
        'gem install cocoapods (requires Ruby: https://www.ruby-lang.org/ or scoop install ruby)'
    }
    
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'cocoapods' -ToolType 'ruby-package' -DefaultInstallCommand $defaultHint
    }
    else {
        if ($defaultHint -notmatch '^Install with:') {
            "Install with: $defaultHint"
        }
        else {
            $defaultHint
        }
    }
    Write-MissingToolWarning -Tool 'pod' -InstallHint $installHint
}
