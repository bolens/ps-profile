<#
scripts/utils/docs/modules/DocParserRegex.psm1

.SYNOPSIS
    Documentation parser regex pattern definitions.

.DESCRIPTION
    Provides compiled regex patterns for parsing PowerShell comment-based help.
#>

# Compile regex patterns once for better performance
$script:regexCommentBlock = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexParameter = [regex]::new('(?s)\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexExample = [regex]::new('(?s)\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.(?:EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexLink = [regex]::new('(?s)\.LINK\s*\n\s*(.+?)(?=\n\s*\.(?:LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexEmptyLine = [regex]::new('^\s*$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexCodeLine = [regex]::new('^\s*[A-Za-z]', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Export regex patterns as module variables
Export-ModuleMember -Variable @(
    'regexCommentBlock',
    'regexParameter',
    'regexExample',
    'regexLink',
    'regexEmptyLine',
    'regexCodeLine'
)

