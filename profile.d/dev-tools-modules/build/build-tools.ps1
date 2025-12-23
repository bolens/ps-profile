# ===============================================
# Build tools and dev server helper functions
# JavaScript build tool wrappers with npx fallback
# ===============================================

<#
.SYNOPSIS
    JavaScript build tool helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common JavaScript build tools.
    Functions check for tool availability and fall back to npx if not installed globally.
    Functions check for tool/npx availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.BuildTools
    Author: PowerShell Profile
#>

# turbo - monorepo build system and task runner
<#
.SYNOPSIS
    Executes Turbo commands.

.DESCRIPTION
    Wrapper for turbo command. Uses globally installed turbo if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to turbo.

.EXAMPLE
    Invoke-Turbo --version

.EXAMPLE
    Invoke-Turbo build
#>
function Invoke-Turbo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand turbo) {
        turbo @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx turbo @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'turbo or npx' -InstallHint 'Install with: npm install -g turbo or npm install -g npm'
    }
}

# esbuild - extremely fast JavaScript bundler
<#
.SYNOPSIS
    Executes esbuild commands.

.DESCRIPTION
    Wrapper for esbuild command. Uses globally installed esbuild if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to esbuild.

.EXAMPLE
    Invoke-Esbuild --version

.EXAMPLE
    Invoke-Esbuild app.js --bundle --outfile=app.bundle.js
#>
function Invoke-Esbuild {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand esbuild) {
        esbuild @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx esbuild @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'esbuild or npx' -InstallHint 'Install with: npm install -g esbuild or npm install -g npm'
    }
}

# rollup - JavaScript module bundler
<#
.SYNOPSIS
    Executes Rollup commands.

.DESCRIPTION
    Wrapper for rollup command. Uses globally installed rollup if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to rollup.

.EXAMPLE
    Invoke-Rollup --version

.EXAMPLE
    Invoke-Rollup -c rollup.config.js
#>
function Invoke-Rollup {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand rollup) {
        rollup @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx rollup @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'rollup or npx' -InstallHint 'Install with: npm install -g rollup or npm install -g npm'
    }
}

# serve - static file serving and directory listing
<#
.SYNOPSIS
    Serves static files.

.DESCRIPTION
    Wrapper for serve command. Uses globally installed serve if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to serve.

.EXAMPLE
    Invoke-Serve

.EXAMPLE
    Invoke-Serve -p 3000
#>
function Invoke-Serve {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand serve) {
        serve @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx serve @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'serve or npx' -InstallHint 'Install with: npm install -g serve or npm install -g npm'
    }
}

# http-server - simple zero-configuration command-line http server
<#
.SYNOPSIS
    Starts HTTP server.

.DESCRIPTION
    Wrapper for http-server command. Uses globally installed http-server if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to http-server.

.EXAMPLE
    Invoke-HttpServer

.EXAMPLE
    Invoke-HttpServer -p 8080
#>
function Invoke-HttpServer {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand http-server) {
        http-server @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx http-server @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'http-server or npx' -InstallHint 'Install with: npm install -g http-server or npm install -g npm'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'turbo' -Target 'Invoke-Turbo'
    Set-AgentModeAlias -Name 'esbuild' -Target 'Invoke-Esbuild'
    Set-AgentModeAlias -Name 'rollup' -Target 'Invoke-Rollup'
    Set-AgentModeAlias -Name 'serve' -Target 'Invoke-Serve'
    Set-AgentModeAlias -Name 'http-server' -Target 'Invoke-HttpServer'
}
else {
    Set-Alias -Name 'turbo' -Value 'Invoke-Turbo' -ErrorAction SilentlyContinue
    Set-Alias -Name 'esbuild' -Value 'Invoke-Esbuild' -ErrorAction SilentlyContinue
    Set-Alias -Name 'rollup' -Value 'Invoke-Rollup' -ErrorAction SilentlyContinue
    Set-Alias -Name 'serve' -Value 'Invoke-Serve' -ErrorAction SilentlyContinue
    Set-Alias -Name 'http-server' -Value 'Invoke-HttpServer' -ErrorAction SilentlyContinue
}

