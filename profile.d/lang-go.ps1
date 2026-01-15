# ===============================================
# lang-go.ps1
# Go development tools (enhanced)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Go development tools fragment for enhanced Go development workflows.

.DESCRIPTION
    Provides wrapper functions for Go development tools that enhance the basic
    go.ps1 functionality:
    - goreleaser: Release automation for Go projects
    - mage: Build tool for Go projects
    - golangci-lint: Fast linter for Go code

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances go.ps1, which provides basic go operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-go') { return }
    }

    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }

        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # goreleaser - Release automation
    # ===============================================

    <#
    .SYNOPSIS
        Creates Go project releases using goreleaser.

    .DESCRIPTION
        Wrapper function for goreleaser, which automates the release process for
        Go projects including building binaries for multiple platforms, creating
        archives, and publishing releases.

    .PARAMETER Arguments
        Additional arguments to pass to goreleaser.
        Can be used multiple times or as an array.

    .EXAMPLE
        Release-GoProject
        Creates a release using goreleaser.

    .EXAMPLE
        Release-GoProject --snapshot
        Creates a snapshot release (dry-run).

    .EXAMPLE
        Release-GoProject --skip-publish
        Builds release artifacts without publishing.

    .OUTPUTS
        System.String. Output from goreleaser execution.
    #>
    function Release-GoProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'goreleaser')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'goreleaser' -ToolType 'go-package' -DefaultInstallCommand 'go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest (or scoop install goreleaser)'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'goreleaser' -RepoRoot $repoRoot
            }
            else {
                "Install with: go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest (or scoop install goreleaser)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'goreleaser' -InstallHint $installHint
            }
            else {
                Write-Warning "goreleaser not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'go.goreleaser.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & goreleaser @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & goreleaser @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run goreleaser: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Release-GoProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Release-GoProject' -Body ${function:Release-GoProject}
    }
    if (-not (Get-Alias goreleaser -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'goreleaser' -Target 'Release-GoProject'
        }
        else {
            Set-Alias -Name 'goreleaser' -Value 'Release-GoProject' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # mage - Build tool
    # ===============================================

    <#
    .SYNOPSIS
        Runs mage build targets for Go projects.

    .DESCRIPTION
        Wrapper function for mage, a build tool for Go that uses magefiles
        (Go files) to define build targets instead of Makefiles.

    .PARAMETER Target
        Mage target to run (optional, lists targets if not specified).

    .PARAMETER Arguments
        Additional arguments to pass to mage.
        Can be used multiple times or as an array.

    .EXAMPLE
        Invoke-Mage
        Lists available mage targets.

    .EXAMPLE
        Invoke-Mage build
        Runs the 'build' target.

    .EXAMPLE
        Invoke-Mage test -v
        Runs the 'test' target with verbose output.

    .OUTPUTS
        System.String. Output from mage execution.
    #>
    function Invoke-Mage {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Target,

            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'mage')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'mage' -RepoRoot $repoRoot
            }
            else {
                "Install with: go install github.com/magefile/mage@latest (or scoop install mage)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'mage' -InstallHint $installHint
            }
            else {
                Write-Warning "mage not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'go.mage.invoke' -Context @{
                target              = $Target
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @()
                if ($Target) {
                    $cmdArgs += $Target
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & mage @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @()
                if ($Target) {
                    $cmdArgs += $Target
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $result = & mage @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run mage: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Mage -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Mage' -Body ${function:Invoke-Mage}
    }
    if (-not (Get-Alias mage -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'mage' -Target 'Invoke-Mage'
        }
        else {
            Set-Alias -Name 'mage' -Value 'Invoke-Mage' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # golangci-lint - Linter
    # ===============================================

    <#
    .SYNOPSIS
        Lints Go code using golangci-lint.

    .DESCRIPTION
        Wrapper function for golangci-lint, a fast linter for Go code that runs
        multiple linters in parallel.

    .PARAMETER Arguments
        Additional arguments to pass to golangci-lint.
        Can be used multiple times or as an array.

    .EXAMPLE
        Lint-GoProject
        Lints the current Go project.

    .EXAMPLE
        Lint-GoProject --fix
        Lints and automatically fixes issues where possible.

    .EXAMPLE
        Lint-GoProject ./...
        Lints all packages recursively.

    .OUTPUTS
        System.String. Output from golangci-lint execution.
    #>
    function Lint-GoProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'golangci-lint')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'golangci-lint' -RepoRoot $repoRoot
            }
            else {
                "Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest (or scoop install golangci-lint)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'golangci-lint' -InstallHint $installHint
            }
            else {
                Write-Warning "golangci-lint not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'go.golangci-lint.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & golangci-lint @Arguments 2>&1
            }
        }
        else {
            try {
                $result = & golangci-lint @Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run golangci-lint: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Lint-GoProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Lint-GoProject' -Body ${function:Lint-GoProject}
    }
    if (-not (Get-Alias golangci-lint -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'golangci-lint' -Target 'Lint-GoProject'
        }
        else {
            Set-Alias -Name 'golangci-lint' -Value 'Lint-GoProject' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Build Go Project (enhanced)
    # ===============================================

    <#
    .SYNOPSIS
        Builds a Go project with common optimizations.

    .DESCRIPTION
        Wrapper function for building Go projects. This runs 'go build' with
        common flags for production builds.

    .PARAMETER Output
        Output binary name or path (optional).

    .PARAMETER Arguments
        Additional arguments to pass to go build.
        Can be used multiple times or as an array.

    .EXAMPLE
        Build-GoProject
        Builds the current Go project.

    .EXAMPLE
        Build-GoProject -Output myapp
        Builds and names the output binary 'myapp'.

    .EXAMPLE
        Build-GoProject -Arguments @('-ldflags', '-s -w')
        Builds with linker flags to strip symbols.

    .OUTPUTS
        System.String. Output from go build execution.
    #>
    function Build-GoProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Output,

            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'go')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'go' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install go"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
            }
            else {
                Write-Warning "go not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'go.build' -Context @{
                output              = $Output
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('build')
                if ($Output) {
                    $cmdArgs += '-o', $Output
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & go @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('build')
                if ($Output) {
                    $cmdArgs += '-o', $Output
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $result = & go @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run go build: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Build-GoProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Build-GoProject' -Body ${function:Build-GoProject}
    }
    if (-not (Get-Alias go-build-project -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'go-build-project' -Target 'Build-GoProject'
        }
        else {
            Set-Alias -Name 'go-build-project' -Value 'Build-GoProject' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Test Go Project (enhanced)
    # ===============================================

    <#
    .SYNOPSIS
        Runs Go tests with common options.

    .DESCRIPTION
        Wrapper function for running Go tests. This runs 'go test' with
        common flags for verbose output and coverage.

    .PARAMETER VerboseOutput
        Enable verbose test output (-v flag).

    .PARAMETER Coverage
        Generate coverage report (-cover flag).

    .PARAMETER Arguments
        Additional arguments to pass to go test.
        Can be used multiple times or as an array.

    .EXAMPLE
        Test-GoProject
        Runs tests in the current package.

    .EXAMPLE
        Test-GoProject -VerboseOutput
        Runs tests with verbose output.

    .EXAMPLE
        Test-GoProject -Coverage ./...
        Runs tests with coverage for all packages.

    .OUTPUTS
        System.String. Output from go test execution.
    #>
    function Test-GoProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [switch]$VerboseOutput,

            [Parameter()]
            [switch]$Coverage,

            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'go')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'go' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install go"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'go' -InstallHint $installHint
            }
            else {
                Write-Warning "go not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'go.test' -Context @{
                verbose_output      = $VerboseOutput.IsPresent
                coverage            = $Coverage.IsPresent
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('test')
                if ($VerboseOutput) {
                    $cmdArgs += '-v'
                }
                if ($Coverage) {
                    $cmdArgs += '-cover'
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & go @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('test')
                if ($VerboseOutput) {
                    $cmdArgs += '-v'
                }
                if ($Coverage) {
                    $cmdArgs += '-cover'
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $result = & go @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run go test: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Test-GoProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Test-GoProject' -Body ${function:Test-GoProject}
    }
    if (-not (Get-Alias go-test-project -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'go-test-project' -Target 'Test-GoProject'
        }
        else {
            Set-Alias -Name 'go-test-project' -Value 'Test-GoProject' -ErrorAction SilentlyContinue
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-go'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-go' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-go fragment: $($_.Exception.Message)"
    }
}
