<#
scripts/utils/security/modules/SecurityRules.psm1

.SYNOPSIS
    Security rule configuration utilities.

.DESCRIPTION
    Provides functions for configuring PSScriptAnalyzer security rules.
#>

<#
.SYNOPSIS
    Gets the list of security-focused PSScriptAnalyzer rules.

.DESCRIPTION
    Returns an array of security-focused rule names to use with PSScriptAnalyzer.

.OUTPUTS
    String array of rule names.
#>
function Get-SecurityRules {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUserNameAndPasswordParams',
        'PSUsePSCredentialType',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidGlobalVars',
        'PSAvoidUsingWriteHost',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingPlainTextForPassword',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidNullOrEmptyHelpMessageAttribute'
    ) | Select-Object -Unique
}

Export-ModuleMember -Function Get-SecurityRules

