@{
    # PSScriptAnalyzer settings for this repository.
    # Customize 'IncludeRules', 'ExcludeRules', and 'Rules' to suit your style.
    # See: https://github.com/PowerShell/PSScriptAnalyzer/blob/main/Documentation/DetectingIssues.md

    # Uncomment and list the rules you want to explicitly include
    IncludeRules = @(
        # Security-focused rules
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUserNameAndPasswordParams',
        'PSUsePSCredentialType'
    )

    # List rules to exclude (rule names are case-sensitive). These are disabled
    # because interactive profile code intentionally uses aliases, Write-Host,
    # non-approved verbs for tiny wrapper functions, and other patterns that are
    # noisy in this context.
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseApprovedVerbs',
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingComputerNameHardcoded'
    )

    # Per-rule configuration (Enable = $true/$false; Severity = 'Error'|'Warning'|'Information')
    Rules        = @{
        # Profiles frequently use short helper aliases and interactive Write-Host.
        # Disable the alias avoidance rule to avoid noisy reports for intentional aliases.
        'PSAvoidUsingCmdletAliases' = @{ Enable = $false }

        # Allow Write-Host in interactive helpers; set to $true to re-enable rule.
        'PSAvoidUsingWriteHost'     = @{ Enable = $false }
    }
}

# Note: Per-file suppressions should be added directly in code using
# [Diagnostics.CodeAnalysis.SuppressMessageAttribute()] attributes, not in settings file.
# The rules listed above in ExcludeRules are already globally excluded.
#   - These are intentional shortcuts for interactive use
#   - Consider: Keep excluded for profile.d scripts, but could enable for utility scripts
#
# PSAvoidUsingWriteHost
#   - Write-Host is appropriate for interactive profile output
#   - Profile code is meant for user interaction, not programmatic consumption
#   - Consider: Keep excluded for profile.d scripts, but could enable for utility scripts
#
# PSAvoidUsingComputerNameHardcoded
#   - Profile code may reference localhost or specific machine names for local configuration
#   - Hardcoded computer names are acceptable in profile context
#   - Consider: Could be enabled for utility scripts that should be portable
ExcludeRules = @(
    'PSUseShouldProcessForStateChangingFunctions',
    'PSAvoidUsingEmptyCatchBlock',
    'PSUseBOMForUnicodeEncodedFile',
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSUseApprovedVerbs',
    'PSAvoidUsingWriteHost',
    'PSAvoidUsingComputerNameHardcoded'
)

# Per-rule configuration (Enable = $true/$false; Severity = 'Error'|'Warning'|'Information')
Rules        = @{
    # Profiles frequently use short helper aliases and interactive Write-Host.
    # Disable the alias avoidance rule to avoid noisy reports for intentional aliases.
    'PSAvoidUsingCmdletAliases' = @{ Enable = $false }

    # Allow Write-Host in interactive helpers; set to $true to re-enable rule.
    'PSAvoidUsingWriteHost'     = @{ Enable = $false }
}
}

# Note: Per-file suppressions should be added directly in code using
# [Diagnostics.CodeAnalysis.SuppressMessageAttribute()] attributes, not in settings file.
# The rules listed above in ExcludeRules are already globally excluded.
