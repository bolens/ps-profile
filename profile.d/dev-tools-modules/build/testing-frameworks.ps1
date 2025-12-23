# ===============================================
# Testing framework helper functions
# JavaScript testing framework wrappers with npx fallback
# ===============================================

<#
.SYNOPSIS
    JavaScript testing framework helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common JavaScript testing frameworks.
    Functions check for tool availability and fall back to npx if not installed globally.
    Functions check for tool/npx availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.TestingFrameworks
    Author: PowerShell Profile
#>

# Jest - JavaScript testing framework
<#
.SYNOPSIS
    Executes Jest test runner.

.DESCRIPTION
    Wrapper for jest command. Uses globally installed jest if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to jest.

.EXAMPLE
    Invoke-Jest --version

.EXAMPLE
    Invoke-Jest test
#>
function Invoke-Jest {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand jest) {
        jest @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx jest @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'jest or npx' -InstallHint 'Install with: npm install -g jest or npm install -g npm'
    }
}

# Vitest - next generation testing framework
<#
.SYNOPSIS
    Executes Vitest test runner.

.DESCRIPTION
    Wrapper for vitest command. Uses globally installed vitest if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to vitest.

.EXAMPLE
    Invoke-Vitest --version

.EXAMPLE
    Invoke-Vitest run
#>
function Invoke-Vitest {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand vitest) {
        vitest @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx vitest @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'vitest or npx' -InstallHint 'Install with: npm install -g vitest or npm install -g npm'
    }
}

# Playwright - end-to-end testing framework
<#
.SYNOPSIS
    Executes Playwright commands.

.DESCRIPTION
    Wrapper for playwright command. Uses globally installed playwright if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to playwright.

.EXAMPLE
    Invoke-Playwright --version

.EXAMPLE
    Invoke-Playwright test
#>
function Invoke-Playwright {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand playwright) {
        playwright @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx playwright @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'playwright or npx' -InstallHint 'Install with: npm install -g playwright or npm install -g npm'
    }
}

# Cypress - JavaScript end-to-end testing framework
<#
.SYNOPSIS
    Executes Cypress commands.

.DESCRIPTION
    Wrapper for cypress command. Uses globally installed cypress if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to cypress.

.EXAMPLE
    Invoke-Cypress --version

.EXAMPLE
    Invoke-Cypress open
#>
function Invoke-Cypress {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand cypress) {
        cypress @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx cypress @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'cypress or npx' -InstallHint 'Install with: npm install -g cypress or npm install -g npm'
    }
}

# Mocha - feature-rich JavaScript test framework
<#
.SYNOPSIS
    Executes Mocha test runner.

.DESCRIPTION
    Wrapper for mocha command. Uses globally installed mocha if available, otherwise falls back to npx.

.PARAMETER Arguments
    Arguments to pass to mocha.

.EXAMPLE
    Invoke-Mocha --version

.EXAMPLE
    Invoke-Mocha test
#>
function Invoke-Mocha {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand mocha) {
        mocha @Arguments
    }
    elseif (Test-CachedCommand npx) {
        npx mocha @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'mocha or npx' -InstallHint 'Install with: npm install -g mocha or npm install -g npm'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jest' -Target 'Invoke-Jest'
    Set-AgentModeAlias -Name 'vitest' -Target 'Invoke-Vitest'
    Set-AgentModeAlias -Name 'playwright' -Target 'Invoke-Playwright'
    Set-AgentModeAlias -Name 'cypress' -Target 'Invoke-Cypress'
    Set-AgentModeAlias -Name 'mocha' -Target 'Invoke-Mocha'
}
else {
    Set-Alias -Name 'jest' -Value 'Invoke-Jest' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vitest' -Value 'Invoke-Vitest' -ErrorAction SilentlyContinue
    Set-Alias -Name 'playwright' -Value 'Invoke-Playwright' -ErrorAction SilentlyContinue
    Set-Alias -Name 'cypress' -Value 'Invoke-Cypress' -ErrorAction SilentlyContinue
    Set-Alias -Name 'mocha' -Value 'Invoke-Mocha' -ErrorAction SilentlyContinue
}
