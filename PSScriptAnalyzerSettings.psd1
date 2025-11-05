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

    # Example per-file suppressions (uncomment and edit as needed)
    Suppressions = @(
        @{ File = 'profile.d\00-bootstrap.ps1'; Rule = 'PSUseShouldProcessForStateChangingFunctions'; Justification = 'Profile bootstrap functions are safe in this context' }
        @{ File = 'profile.d\00-bootstrap.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable in bootstrap code' }
        @{ File = 'profile.d\00-bootstrap.ps1'; Rule = 'PSUseDeclaredVarsMoreThanAssignments'; Justification = 'Variable is used in error handling context' }
        @{ File = 'profile.d\02-prompt.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\03-files.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\05-utilities.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\06-oh-my-posh.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable in oh-my-posh setup' }
        @{ File = 'profile.d\09-wsl.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\10-git.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\10-git.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\10-psreadline.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\11-ansible.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\13-shortcuts.ps1'; Rule = 'PSUseApprovedVerbs'; Justification = 'Utility functions use convenient unapproved verbs by design' }
        @{ File = 'profile.d\20-containers.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable in container setup' }
        @{ File = 'profile.d\21-container-utils.ps1'; Rule = 'PSUseShouldProcessForStateChangingFunctions'; Justification = 'Container preference setting is safe in profile context' }
        @{ File = 'profile.d\24-minio.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\28-aws.ps1'; Rule = 'PSAvoidUsingWriteHost'; Justification = 'AWS setup uses Write-Host for user feedback' }
        @{ File = 'profile.d\30-aliases.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable in alias setup' }
        @{ File = 'profile.d\30-dev.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
    )
}
        @{ File = 'profile.d\21-container-utils.ps1'; Rule = 'PSUseShouldProcessForStateChangingFunctions'; Justification = 'Container preference setting is safe in profile context' }
        @{ File = 'profile.d\24-minio.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\28-aws.ps1'; Rule = 'PSAvoidUsingWriteHost'; Justification = 'AWS setup uses Write-Host for user feedback' }
        @{ File = 'profile.d\30-aliases.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable in alias setup' }
        @{ File = 'profile.d\30-dev.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\00-bootstrap.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Profile bootstrap uses global variables for state tracking' }
        @{ File = 'profile.d\00-bootstrap.ps1'; Rule = 'PSUseProcessBlockForPipelineCommand'; Justification = 'Pipeline functions are simple wrappers' }
        @{ File = 'profile.d\05-utilities.ps1'; Rule = 'PSAvoidOverwritingBuiltInCmdlets'; Justification = 'Get-History wrapper extends functionality' }
        @{ File = 'profile.d\11-git.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\12-psreadline.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'PSReadLine configuration uses global variables' }
        @{ File = 'profile.d\23-starship.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Starship prompt uses global variables for state' }
        @{ File = 'profile.d\23-starship.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Event handlers need to assign to eventArgs' }
        @{ File = 'profile.d\23-starship.ps1'; Rule = 'PSReviewUnusedParameter'; Justification = 'Event handler parameters may be unused' }
        @{ File = 'profile.d\27-minio.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\59-diagnostics.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Diagnostics uses global variables for tracking' }
        @{ File = 'profile.d\59-diagnostics.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\63-gum.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Wrapper functions assign to args for passthrough' }
        @{ File = 'profile.d\67-uv.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Wrapper functions assign to Args for passthrough' }
        @{ File = 'profile.d\68-pixi.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Wrapper functions assign to Args for passthrough' }
        @{ File = 'profile.d\69-pnpm.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Wrapper functions assign to Args for passthrough' }
        @{ File = 'profile.d\70-profile-updates.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\72-error-handling.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Error handling uses global variables for state' }
        @{ File = 'profile.d\73-performance-insights.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Performance tracking uses global variables' }
        @{ File = 'profile.d\73-performance-insights.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Event handlers need to assign to eventArgs' }
        @{ File = 'profile.d\73-performance-insights.ps1'; Rule = 'PSReviewUnusedParameter'; Justification = 'Event handler parameters may be unused' }
        @{ File = 'profile.d\73-performance-insights.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\74-enhanced-history.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Regex matches assignment is intentional' }
        @{ File = 'profile.d\74-enhanced-history.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\75-system-monitor.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'System monitor uses global variables for state' }
        @{ File = 'profile.d\75-system-monitor.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'profile.d\76-smart-navigation.ps1'; Rule = 'PSAvoidGlobalVars'; Justification = 'Navigation tracking uses global variables' }
        @{ File = 'profile.d\76-smart-navigation.ps1'; Rule = 'PSUseProcessBlockForPipelineCommand'; Justification = 'Pipeline function is a simple wrapper' }
        @{ File = 'profile.d\76-smart-navigation.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'scripts\checks\check-commit-messages.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch block is acceptable for error handling' }
        @{ File = 'scripts\utils\generate-docs.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch block is acceptable for error handling' }
        @{ File = 'scripts\utils\generate-docs.ps1'; Rule = 'PSPossibleIncorrectComparisonWithNull'; Justification = 'Null comparison order is acceptable here' }
        @{ File = 'scripts\utils\generate-fragment-readmes.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable for error handling' }
        @{ File = 'scripts\utils\generate-fragment-readmes.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'scripts\utils\benchmark-startup.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch block is acceptable for error handling' }
        @{ File = 'scripts\utils\benchmark-startup.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'scripts\utils\check-module-updates.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'scripts\utils\init_wrangler_config.ps1'; Rule = 'PSUseBOMForUnicodeEncodedFile'; Justification = 'File contains Unicode characters that require BOM' }
        @{ File = 'scripts\utils\generate-changelog.ps1'; Rule = 'PSAvoidAssignmentToAutomaticVariable'; Justification = 'Wrapper functions assign to args for passthrough' }
        @{ File = 'scripts\git\hooks\install-githooks.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable for error handling' }
        @{ File = 'scripts\git\hooks\install-pre-commit-hook.ps1'; Rule = 'PSAvoidUsingEmptyCatchBlock'; Justification = 'Empty catch blocks are acceptable for error handling' }
    )
}
