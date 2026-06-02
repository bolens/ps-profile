# ===============================================
# lang-go-basic.ps1
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

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-go-basic') { return }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go run @Arguments
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go build @Arguments
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go mod @Arguments
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go test @Arguments
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go install golang.org/x/tools/cmd/...@latest
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            foreach ($package in $Packages) {
                & go mod edit -droprequire $package
            }
            & go mod tidy
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

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

        if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand go)) {
            & go install @Packages
        }
        else {
            Invoke-MissingToolWarning -ToolName 'go' -ToolType 'go-package'
        }
    }

    # Register functions
    Set-AgentModeFunction -Name 'Invoke-GoRun' -Body ${function:Invoke-GoRun}
    Set-AgentModeFunction -Name 'Build-GoProgram' -Body ${function:Build-GoProgram}
    Set-AgentModeFunction -Name 'Invoke-GoModule' -Body ${function:Invoke-GoModule}
    Set-AgentModeFunction -Name 'Test-GoPackage' -Body ${function:Test-GoPackage}
    Set-AgentModeFunction -Name 'Update-GoTools' -Body ${function:Update-GoTools}
    Set-AgentModeFunction -Name 'Remove-GoDependency' -Body ${function:Remove-GoDependency}
    Set-AgentModeFunction -Name 'Install-GoPackage' -Body ${function:Install-GoPackage}

    # Aliases
    Set-AgentModeAlias -Name 'go-run' -Target 'Invoke-GoRun'
    Set-AgentModeAlias -Name 'go-build' -Target 'Build-GoProgram'
    Set-AgentModeAlias -Name 'go-mod' -Target 'Invoke-GoModule'
    Set-AgentModeAlias -Name 'go-test' -Target 'Test-GoPackage'
    Set-AgentModeAlias -Name 'go-tools-update' -Target 'Update-GoTools'
    Set-AgentModeAlias -Name 'go-install' -Target 'Install-GoPackage'
    Set-AgentModeAlias -Name 'go-remove' -Target 'Remove-GoDependency'

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-go-basic'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-go-basic' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-go-basic: $($_.Exception.Message)"
    }
}
