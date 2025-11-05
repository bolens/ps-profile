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
