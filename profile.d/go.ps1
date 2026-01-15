# ===============================================
# go.ps1
# Go programming language helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Go programming language helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Go operations.
    Functions check for go availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Go
    Author: PowerShell Profile
#>

# Go run wrapper - run Go programs
<#
.SYNOPSIS
    Runs Go programs.

.DESCRIPTION
    Wrapper for go run command.

.PARAMETER Arguments
    Arguments to pass to go run.

.EXAMPLE
    Invoke-GoRun main.go

.EXAMPLE
    Invoke-GoRun ./cmd/server
#>
function Invoke-GoRun {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go run @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Go build wrapper - compile Go programs
<#
.SYNOPSIS
    Builds Go programs.

.DESCRIPTION
    Wrapper for go build command.

.PARAMETER Arguments
    Arguments to pass to go build.

.EXAMPLE
    Build-GoProgram

.EXAMPLE
    Build-GoProgram -o myapp
#>
function Build-GoProgram {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go build @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Go module management - manage Go modules
<#
.SYNOPSIS
    Manages Go modules.

.DESCRIPTION
    Wrapper for go mod command.

.PARAMETER Arguments
    Arguments to pass to go mod.

.EXAMPLE
    Invoke-GoModule init

.EXAMPLE
    Invoke-GoModule tidy
#>
function Invoke-GoModule {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go mod @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Go test runner - run Go tests
<#
.SYNOPSIS
    Runs Go tests.

.DESCRIPTION
    Wrapper for go test command.

.PARAMETER Arguments
    Arguments to pass to go test.

.EXAMPLE
    Test-GoPackage

.EXAMPLE
    Test-GoPackage -v ./...
#>
function Test-GoPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go test @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'go-run' -Target 'Invoke-GoRun'
    Set-AgentModeAlias -Name 'go-build' -Target 'Build-GoProgram'
    Set-AgentModeAlias -Name 'go-mod' -Target 'Invoke-GoModule'
    Set-AgentModeAlias -Name 'go-test' -Target 'Test-GoPackage'
}
else {
    Set-Alias -Name 'go-run' -Value 'Invoke-GoRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-build' -Value 'Build-GoProgram' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-mod' -Value 'Invoke-GoModule' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-test' -Value 'Test-GoPackage' -ErrorAction SilentlyContinue
}

# Go update dependencies - update all dependencies
<#
.SYNOPSIS
    Updates Go development tools to their latest versions.
.DESCRIPTION
    Updates all Go tools from golang.org/x/tools to their latest versions.
    This is equivalent to running 'go install golang.org/x/tools/cmd/...@latest'.
.EXAMPLE
    Update-GoTools
    Updates all Go development tools to their latest versions.
#>
function Update-GoTools {
    [CmdletBinding()]
    param()
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go install golang.org/x/tools/cmd/...@latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'go-run' -Target 'Invoke-GoRun'
    Set-AgentModeAlias -Name 'go-build' -Target 'Build-GoProgram'
    Set-AgentModeAlias -Name 'go-mod' -Target 'Invoke-GoModule'
    Set-AgentModeAlias -Name 'go-test' -Target 'Test-GoPackage'
    Set-AgentModeAlias -Name 'go-update' -Target 'Update-GoDependencies'
    Set-AgentModeAlias -Name 'go-tools-update' -Target 'Update-GoTools'
}
else {
    Set-Alias -Name 'go-run' -Value 'Invoke-GoRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-build' -Value 'Build-GoProgram' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-mod' -Value 'Invoke-GoModule' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-test' -Value 'Test-GoPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-update' -Value 'Update-GoDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-tools-update' -Value 'Update-GoTools' -ErrorAction SilentlyContinue
}
<#
.SYNOPSIS
    Removes Go module dependencies.
.DESCRIPTION
    Removes packages from go.mod using go mod edit -droprequire.
.PARAMETER Packages
    Package paths to remove (e.g., github.com/user/package).
.EXAMPLE
    Remove-GoDependency github.com/gin-gonic/gin
    Removes gin from dependencies.
#>
function Remove-GoDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        foreach ($package in $Packages) {
            & go mod edit -droprequire $package
        }
        & go mod tidy
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Go install - install packages globally
<#
.SYNOPSIS
    Installs Go packages globally.
.DESCRIPTION
    Installs packages as global binaries using go install.
.PARAMETER Packages
    Package paths to install (e.g., github.com/user/cmd/tool@latest).
.EXAMPLE
    Install-GoPackage github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    Installs golangci-lint globally.
#>
function Install-GoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages
    )
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go install @Packages
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Go update dependencies - update all dependencies
<#
.SYNOPSIS
    Updates Go development tools to their latest versions.
.DESCRIPTION
    Updates all Go tools from golang.org/x/tools to their latest versions.
    This is equivalent to running 'go install golang.org/x/tools/cmd/...@latest'.
.EXAMPLE
    Update-GoTools
    Updates all Go development tools to their latest versions.
#>
function Update-GoTools {
    [CmdletBinding()]
    param()
    
    # Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
    if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
        & go install golang.org/x/tools/cmd/...@latest
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'go-package' -DefaultInstallCommand 'scoop install go'
        }
        else {
            'Install with: scoop install go'
        }
        Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'go-run' -Target 'Invoke-GoRun'
    Set-AgentModeAlias -Name 'go-build' -Target 'Build-GoProgram'
    Set-AgentModeAlias -Name 'go-mod' -Target 'Invoke-GoModule'
    Set-AgentModeAlias -Name 'go-test' -Target 'Test-GoPackage'
    Set-AgentModeAlias -Name 'go-update' -Target 'Update-GoDependencies'
    Set-AgentModeAlias -Name 'go-tools-update' -Target 'Update-GoTools'
}
else {
    Set-Alias -Name 'go-run' -Value 'Invoke-GoRun' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-build' -Value 'Build-GoProgram' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-mod' -Value 'Invoke-GoModule' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-test' -Value 'Test-GoPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-update' -Value 'Update-GoDependencies' -ErrorAction SilentlyContinue
    Set-Alias -Name 'go-tools-update' -Value 'Update-GoTools' -ErrorAction SilentlyContinue
}
