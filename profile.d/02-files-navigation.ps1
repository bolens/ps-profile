# ===============================================
# 02-files-navigation.ps1
# File navigation utilities
# ===============================================

# Lazy bulk initializer for file navigation helpers
<#
.SYNOPSIS
    Initializes file navigation utility functions on first use.
.DESCRIPTION
    Sets up all file navigation utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileNavigation")) {
    function Ensure-FileNavigation {
        Set-Item -Path Function:\global:__FileNavigation_UpOne -Value { Set-Location .. } -Force | Out-Null
        Set-Item -Path Function:\global:__FileNavigation_UpTwo -Value { Set-Location ..\..\ } -Force | Out-Null
        Set-Item -Path Function:\global:__FileNavigation_UpThree -Value { Set-Location ..\..\..\ } -Force | Out-Null

        $resolveHome = {
            if (Test-Path Function:\Get-UserHome) {
                Get-UserHome
            }
            elseif ($env:HOME) {
                $env:HOME
            }
            else {
                $env:USERPROFILE
            }
        }.GetNewClosure()

        $homeScript = {
            $resolvedHome = & $resolveHome
            if ($resolvedHome) {
                Set-Location $resolvedHome
            }
            else {
                throw 'Unable to determine user home directory.'
            }
        }.GetNewClosure()
        Set-Item -Path Function:\global:__FileNavigation_Home -Value $homeScript -Force | Out-Null

        $desktopScript = {
            $resolvedHome = & $resolveHome
            if (-not $resolvedHome) {
                throw 'Unable to determine user home directory.'
            }

            $desktop = Join-Path $resolvedHome 'Desktop'
            if (Test-Path $desktop) {
                Set-Location $desktop
            }
            else {
                Write-Warning 'Desktop directory not found. This may not be available on your platform.'
            }
        }.GetNewClosure()
        Set-Item -Path Function:\global:__FileNavigation_Desktop -Value $desktopScript -Force | Out-Null

        $downloadsScript = {
            $resolvedHome = & $resolveHome
            if (-not $resolvedHome) {
                throw 'Unable to determine user home directory.'
            }

            $downloads = Join-Path $resolvedHome 'Downloads'
            if (Test-Path $downloads) {
                Set-Location $downloads
            }
            else {
                Write-Warning 'Downloads directory not found. This may not be available on your platform.'
            }
        }.GetNewClosure()
        Set-Item -Path Function:\global:__FileNavigation_Downloads -Value $downloadsScript -Force | Out-Null

        $documentsScript = {
            $resolvedHome = & $resolveHome
            if (-not $resolvedHome) {
                throw 'Unable to determine user home directory.'
            }

            $documents = Join-Path $resolvedHome 'Documents'
            if (Test-Path $documents) {
                Set-Location $documents
            }
            else {
                Write-Warning 'Documents directory not found. This may not be available on your platform.'
            }
        }.GetNewClosure()
        Set-Item -Path Function:\global:__FileNavigation_Documents -Value $documentsScript -Force | Out-Null
    }
}

# Up one directory
<#
.SYNOPSIS
    Changes to the parent directory.
.DESCRIPTION
    Moves up one directory level in the file system.
#>
function .. {
    if (-not (Test-Path Function:\__FileNavigation_UpOne)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_UpOne)) {
        throw 'File navigation helper "__FileNavigation_UpOne" failed to initialize.'
    }

    return & __FileNavigation_UpOne @args
}

# Up two directories
<#
.SYNOPSIS
    Changes to the grandparent directory.
.DESCRIPTION
    Moves up two directory levels in the file system.
#>
function ... {
    if (-not (Test-Path Function:\__FileNavigation_UpTwo)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_UpTwo)) {
        throw 'File navigation helper "__FileNavigation_UpTwo" failed to initialize.'
    }

    return & __FileNavigation_UpTwo @args
}

# Up three directories
<#
.SYNOPSIS
    Changes to the great-grandparent directory.
.DESCRIPTION
    Moves up three directory levels in the file system.
#>
function .... {
    if (-not (Test-Path Function:\__FileNavigation_UpThree)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_UpThree)) {
        throw 'File navigation helper "__FileNavigation_UpThree" failed to initialize.'
    }

    return & __FileNavigation_UpThree @args
}

# Go to user home directory
Set-Item -Path Function:\~ -Value {
    if (-not (Test-Path Function:\__FileNavigation_Home)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_Home)) {
        throw 'File navigation helper "__FileNavigation_Home" failed to initialize.'
    }

    return & __FileNavigation_Home @args
} -Force | Out-Null

# Go to Desktop directory
<#
.SYNOPSIS
    Changes to the Desktop directory.
.DESCRIPTION
    Navigates to the user's Desktop folder.
#>
function Set-LocationDesktop {
    if (-not (Test-Path Function:\__FileNavigation_Desktop)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_Desktop)) {
        throw 'File navigation helper "__FileNavigation_Desktop" failed to initialize.'
    }

    return & __FileNavigation_Desktop @args
}
Set-Alias -Name desktop -Value Set-LocationDesktop -ErrorAction SilentlyContinue

# Go to Downloads directory
<#
.SYNOPSIS
    Changes to the Downloads directory.
.DESCRIPTION
    Navigates to the user's Downloads folder.
#>
function Set-LocationDownloads {
    if (-not (Test-Path Function:\__FileNavigation_Downloads)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_Downloads)) {
        throw 'File navigation helper "__FileNavigation_Downloads" failed to initialize.'
    }

    return & __FileNavigation_Downloads @args
}
Set-Alias -Name downloads -Value Set-LocationDownloads -ErrorAction SilentlyContinue

# Go to Documents directory
<#
.SYNOPSIS
    Changes to the Documents directory.
.DESCRIPTION
    Navigates to the user's Documents folder.
#>
function Set-LocationDocuments {
    if (-not (Test-Path Function:\__FileNavigation_Documents)) {
        Ensure-FileNavigation
    }

    if (-not (Test-Path Function:\__FileNavigation_Documents)) {
        throw 'File navigation helper "__FileNavigation_Documents" failed to initialize.'
    }

    return & __FileNavigation_Documents @args
}
Set-Alias -Name docs -Value Set-LocationDocuments -ErrorAction SilentlyContinue
