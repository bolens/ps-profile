<#
scripts/utils/security/modules/SecurityPatterns.psm1

.SYNOPSIS
    Security pattern matching utilities.

.DESCRIPTION
    Provides functions for defining and matching security-related patterns.
#>

<#
.SYNOPSIS
    Gets compiled regex patterns for external command detection.

.DESCRIPTION
    Returns a hashtable of compiled regex patterns for detecting potentially unsafe external command execution.

.OUTPUTS
    Hashtable with pattern names as keys and compiled regex objects as values.
#>
function Get-ExternalCommandPatterns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        'InvokeExpression' = [regex]::new('Invoke-Expression\s+', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'StartProcess'     = [regex]::new('Start-Process\s+.*-FilePath\s+["'']([^"'']+)["'']', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'CallOperator'     = [regex]::new('&\s+\$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        'DynamicCommand'   = [regex]::new('&?\s*\([^)]+\)\s*\(', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
}

<#
.SYNOPSIS
    Gets compiled regex patterns for secret detection.

.DESCRIPTION
    Returns a hashtable of compiled regex patterns for detecting hardcoded secrets like passwords, API keys, and tokens.

.OUTPUTS
    Hashtable with pattern names as keys and compiled regex objects as values.
#>
function Get-SecretPatterns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $passwordPattern = '(?:password|passwd|pwd)\s*[=:]\s*["'']?([^"'']{8,})["'']?'
    $apiKeyPattern = '(?:apikey|api_key|api-key)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{20,})["'']?'
    $tokenPattern = '(?:token|access_token)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{20,})["'']?'
    $secretPattern = '(?:secret|secretkey|secret_key)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{16,})["'']?'
    $awsKeyPattern = 'AKIA[0-9A-Z]{16}(?!.*(?:example|test|sample|placeholder))'
    $privateKeyPattern = '-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----(?!.*(?:test|example|sample|placeholder))'

    return @{
        'HardcodedPassword' = [regex]::new($passwordPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'HardcodedAPIKey'   = [regex]::new($apiKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'HardcodedToken'    = [regex]::new($tokenPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'HardcodedSecret'   = [regex]::new($secretPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        'AWSKeyPattern'     = [regex]::new($awsKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        'PrivateKeyPattern' = [regex]::new($privateKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
}

<#
.SYNOPSIS
    Gets regex patterns for false positive detection.

.DESCRIPTION
    Returns an array of regex patterns that indicate a detected secret is likely a false positive (e.g., example/test values).

.OUTPUTS
    String array of regex patterns.
#>
function Get-FalsePositivePatterns {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        '(?:example|sample|test|placeholder|your[_-]?|changeme|replace|demo|fake|dummy|mock|temp|temporary)',
        '(?:test[_-]?(?:data|value|key|token|secret|password|api))',
        '(?:#|//|/\*|\*/\s*example|\s*example\s*$)',
        '(?:\$example|\$sample|\$test|\$placeholder|\$demo)',
        '(?:["''](?:example|test|sample|placeholder|your|changeme)[^"'']*["'']|["''][^"'']*(?:example|test|sample|placeholder|your|changeme)["''])'
    )
}

Export-ModuleMember -Function Get-ExternalCommandPatterns, Get-SecretPatterns, Get-FalsePositivePatterns

