<#
scripts/utils/docs/modules/FragmentReadmeRegex.psm1

.SYNOPSIS
    Fragment README regex pattern definitions.

.DESCRIPTION
    Provides compiled regex patterns for parsing PowerShell fragments to generate README files.
#>

# Compile regex patterns once for better performance
$script:regexCommentLine = [regex]::new('^\s*#\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexFunction = [regex]::new('^\s*function\s+([A-Za-z0-9_\-\.\~]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexDecorativeEquals = [regex]::new('^# =+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexDecorativeDashes = [regex]::new('^# -+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexMultilineCommentStart = [regex]::new('^\s*<#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexMultilineCommentEnd = [regex]::new('^\s*#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexCommentStart = [regex]::new('^\s*#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexEmptyLine = [regex]::new('^\s*$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexIfStatement = [regex]::new('^\s*if\s*\(', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:regexInlineComment = [regex]::new("# (.+)$", [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Export regex patterns as module variables
Export-ModuleMember -Variable @(
    'regexCommentLine',
    'regexFunction',
    'regexDecorativeEquals',
    'regexDecorativeDashes',
    'regexMultilineCommentStart',
    'regexMultilineCommentEnd',
    'regexCommentStart',
    'regexEmptyLine',
    'regexIfStatement',
    'regexInlineComment'
)

