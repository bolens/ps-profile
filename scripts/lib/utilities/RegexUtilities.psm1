<#
scripts/lib/RegexUtilities.psm1

.SYNOPSIS
    Regex utilities for creating compiled regex patterns.

.DESCRIPTION
    Provides functions for creating compiled regex patterns with consistent options.
    Compiled regex patterns offer better performance for repeated matching operations.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Creates a compiled regex pattern.

.DESCRIPTION
    Creates a compiled regex pattern with consistent options for better performance.
    Compiled regex patterns are cached by the .NET runtime and offer significant
    performance improvements for repeated matching operations.

.PARAMETER Pattern
    The regex pattern string.

.PARAMETER Options
    Additional regex options. Can be combined with bitwise OR (e.g., IgnoreCase -bor Multiline).
    Common options: IgnoreCase, Multiline, Singleline, Compiled.

.PARAMETER Compiled
    If specified, includes Compiled option for better performance. Defaults to true.

.OUTPUTS
    System.Text.RegularExpressions.Regex. A compiled regex object.

.EXAMPLE
    $regex = New-CompiledRegex -Pattern 'function\s+(\w+)'
    $matches = $regex.Matches($content)

.EXAMPLE
    $regex = New-CompiledRegex -Pattern '^#.*' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
    $commentLines = $regex.Matches($content)
#>
function New-CompiledRegex {
    [CmdletBinding()]
    [OutputType([System.Text.RegularExpressions.Regex])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern,

        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None,

        [bool]$Compiled = $true
    )

    $finalOptions = $Options
    if ($Compiled) {
        $finalOptions = $finalOptions -bor [System.Text.RegularExpressions.RegexOptions]::Compiled
    }

    return [regex]::new($Pattern, $finalOptions)
}

<#
.SYNOPSIS
    Gets common compiled regex patterns for PowerShell code analysis.

.DESCRIPTION
    Returns a hashtable of commonly used compiled regex patterns for analyzing
    PowerShell code, including function definitions, comment blocks, and common patterns.

.OUTPUTS
    Hashtable with pattern names as keys and compiled regex objects as values.

.EXAMPLE
    $patterns = Get-CommonRegexPatterns
    $functionMatches = $patterns['FunctionDefinition'].Matches($content)
    $commentMatches = $patterns['CommentBlock'].Matches($content)
#>
function Get-CommonRegexPatterns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        'FunctionDefinition'    = New-CompiledRegex -Pattern 'function\s+([A-Za-z0-9_-]+)\s*\{'
        'CommentBlock'          = New-CompiledRegex -Pattern '<#[\s\S]*?#>'
        'CommentBlockMultiline' = New-CompiledRegex -Pattern '^[\s]*<#
[\s\S]*?
.PARAMETER Text
    Input text to normalize or inspect.
.EXAMPLE
    Escape-RegexLiteral

#>' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
        'SingleLineComment'     = New-CompiledRegex -Pattern '^\s*#.*$' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
        'ExitCall'              = New-CompiledRegex -Pattern '\bexit\s+(\d+)\b'
        'ExitVariable'          = New-CompiledRegex -Pattern '\bexit\s+\$EXIT'
        'ImportModule'          = New-CompiledRegex -Pattern 'Import-Module' -Options ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
}

function Escape-RegexLiteral {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    return [regex]::Escape($Text)
}

<#
.SYNOPSIS
    Gets built-in natural language regex catalog entries.

.DESCRIPTION
    Returns a catalog of common regex intents mapped to patterns and aliases.
    Use this to discover supported natural language descriptions.

.OUTPUTS
    Ordered hashtable with catalog entry names as keys.

.EXAMPLE
    $catalog = Get-NaturalLanguageRegexCatalog
    $catalog['email'].Pattern
#>
function Get-NaturalLanguageRegexCatalog {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return [ordered]@{
        'email'              = @{
            Pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
            Aliases = @('e-mail', 'email address', 'email addresses')
            Notes   = @('Matches common email address formats.')
        }
        'url'                = @{
            Pattern = 'https?://[^\s/$.?#].[^\s]*'
            Aliases = @('website', 'web address', 'http url', 'https url')
            Notes   = @('Matches HTTP and HTTPS URLs.')
        }
        'ipv4'               = @{
            Pattern = '(?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d)'
            Aliases = @('ip address', 'ip v4', 'ipv4 address')
            Notes   = @('Matches dotted-decimal IPv4 addresses.')
        }
        'ipv6'               = @{
            Pattern = '(?:[A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,7}:|(?:[A-Fa-f0-9]{1,4}:){1,6}:[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,5}(?::[A-Fa-f0-9]{1,4}){1,2}|(?:[A-Fa-f0-9]{1,4}:){1,4}(?::[A-Fa-f0-9]{1,4}){1,3}|(?:[A-Fa-f0-9]{1,4}:){1,3}(?::[A-Fa-f0-9]{1,4}){1,4}|(?:[A-Fa-f0-9]{1,4}:){1,2}(?::[A-Fa-f0-9]{1,4}){1,5}|[A-Fa-f0-9]{1,4}:(?::[A-Fa-f0-9]{1,4}){1,6}|:(?::[A-Fa-f0-9]{1,4}){1,7}|::'
            Aliases = @('ip v6', 'ipv6 address')
            Notes   = @('Matches common IPv6 address forms.')
        }
        'mac-address'        = @{
            Pattern = '(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}'
            Aliases = @('mac address', 'mac', 'hardware address')
            Notes   = @('Matches MAC addresses with colon or hyphen separators.')
        }
        'uuid'               = @{
            Pattern = '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[1-5][0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}'
            Aliases = @('guid', 'uuid v4')
            Notes   = @('Matches canonical UUID strings.')
        }
        'phone-number'       = @{
            Pattern = '(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'
            Aliases = @('phone', 'telephone number', 'us phone number')
            Notes   = @('Matches common North American phone number formats.')
        }
        'zip-code'           = @{
            Pattern = '\d{5}(?:-\d{4})?'
            Aliases = @('zipcode', 'zip code', 'postal code', 'us zip code')
            Notes   = @('Matches US ZIP and ZIP+4 codes.')
        }
        'hex-color'          = @{
            Pattern = '#(?:[0-9A-Fa-f]{3}){1,2}\b'
            Aliases = @('hex colour', 'color code', 'colour code', 'css color')
            Notes   = @('Matches 3- or 6-digit CSS hex colors.')
        }
        'date-iso'           = @{
            Pattern = '\d{4}-\d{2}-\d{2}'
            Aliases = @('iso date', 'date yyyy-mm-dd', 'date')
            Notes   = @('Matches ISO 8601 calendar dates.')
        }
        'time-24h'           = @{
            Pattern = '(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?'
            Aliases = @('24 hour time', 'time', 'time hh:mm')
            Notes   = @('Matches 24-hour clock times.')
        }
        'integer'            = @{
            Pattern = '-?\d+'
            Aliases = @('whole number', 'signed integer', 'number')
            Notes   = @('Matches optional negative integers.')
        }
        'decimal-number'     = @{
            Pattern = '-?\d+(?:\.\d+)?'
            Aliases = @('float', 'floating point number', 'decimal')
            Notes   = @('Matches signed decimal numbers.')
        }
        'alphanumeric'       = @{
            Pattern = '[A-Za-z0-9]+'
            Aliases = @('letters and numbers', 'alpha numeric', 'alphanumeric string')
            Notes   = @('Matches one or more letters or digits.')
        }
        'letters'            = @{
            Pattern = '[A-Za-z]+'
            Aliases = @('alphabetic', 'alpha', 'letters only', 'alphabetic characters')
            Notes   = @('Matches one or more alphabetic characters.')
        }
        'digits'             = @{
            Pattern = '\d+'
            Aliases = @('numbers', 'numeric digits', 'digits only', 'numbers only')
            Notes   = @('Matches one or more digits.')
        }
        'word-characters'    = @{
            Pattern = '\w+'
            Aliases = @('word', 'words', 'word characters')
            Notes   = @('Matches one or more word characters.')
        }
        'whitespace'         = @{
            Pattern = '\s+'
            Aliases = @('spaces', 'white space', 'blank space')
            Notes   = @('Matches one or more whitespace characters.')
        }
        'slug'               = @{
            Pattern = '[a-z0-9]+(?:-[a-z0-9]+)*'
            Aliases = @('url slug', 'kebab case slug', 'hyphenated slug')
            Notes   = @('Matches lowercase hyphenated slugs.')
        }
        'semver'             = @{
            Pattern = '\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?'
            Aliases = @('semantic version', 'version number')
            Notes   = @('Matches semantic version strings.')
        }
        'username'           = @{
            Pattern = '[A-Za-z0-9_]{3,20}'
            Aliases = @('user name', 'handle')
            Notes   = @('Matches 3-20 character usernames.')
        }
        'domain-name'        = @{
            Pattern = '(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}'
            Aliases = @('domain', 'hostname', 'host name')
            Notes   = @('Matches common domain names.')
        }
        'credit-card'        = @{
            Pattern = '(?:\d{4}[-\s]?){3}\d{4}'
            Aliases = @('credit card number', 'card number')
            Notes   = @('Matches grouped 16-digit card numbers.')
        }
        'ssn'                = @{
            Pattern = '\d{3}-\d{2}-\d{4}'
            Aliases = @('social security number', 'us ssn')
            Notes   = @('Matches US Social Security numbers.')
        }
        'iban'               = @{
            Pattern = '[A-Z]{2}\d{2}[A-Z0-9]{11,30}'
            Aliases = @('international bank account number', 'bank account number')
            Notes   = @('Matches simplified IBAN strings.')
        }
        'e164-phone'         = @{
            Pattern = '\+\d{8,15}'
            Aliases = @('international phone', 'international phone number', 'e164', 'e.164')
            Notes   = @('Matches E.164 international phone numbers.')
        }
        'uk-postcode'        = @{
            Pattern = '[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}'
            Aliases = @('uk postal code', 'british postcode', 'postcode uk')
            Notes   = @('Matches common UK postcodes.')
        }
        'ca-postal-code'     = @{
            Pattern = '[A-Z]\d[A-Z]\s?\d[A-Z]\d'
            Aliases = @('canadian postal code', 'canada postal code')
            Notes   = @('Matches Canadian postal codes.')
        }
        'iso-datetime'       = @{
            Pattern = '\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?'
            Aliases = @('iso 8601 datetime', 'iso timestamp', 'datetime')
            Notes   = @('Matches common ISO 8601 date-time strings.')
        }
        'base64'             = @{
            Pattern = '(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?'
            Aliases = @('base64 string', 'base 64')
            Notes   = @('Matches base64-encoded strings.')
        }
        'md5-hash'           = @{
            Pattern = '\b[a-fA-F0-9]{32}\b'
            Aliases = @('md5', 'md5 checksum')
            Notes   = @('Matches 32-character MD5 hashes.')
        }
        'sha256-hash'        = @{
            Pattern = '\b[a-fA-F0-9]{64}\b'
            Aliases = @('sha256', 'sha-256', 'sha256 checksum')
            Notes   = @('Matches 64-character SHA-256 hashes.')
        }
        'mime-type'          = @{
            Pattern = '[A-Za-z0-9!#$&^_.+-]+/[A-Za-z0-9!#$&^_.+-]+'
            Aliases = @('mime', 'content type', 'media type')
            Notes   = @('Matches common MIME type strings.')
        }
        'port-number'        = @{
            Pattern = '(?:[1-9]\d{0,3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])'
            Aliases = @('tcp port', 'udp port', 'network port')
            Notes   = @('Matches valid TCP/UDP port numbers (1-65535).')
        }
        'percentage'         = @{
            Pattern = '-?\d+(?:\.\d+)?%'
            Aliases = @('percent', 'percent value')
            Notes   = @('Matches percentage values with a trailing percent sign.')
        }
        'currency-usd'     = @{
            Pattern = '\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?'
            Aliases = @('usd amount', 'dollar amount', 'money', 'currency')
            Notes   = @('Matches US dollar amounts.')
        }
        'ipv4-cidr'          = @{
            Pattern = '(?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d)/(?:[0-9]|[1-2][0-9]|3[0-2])'
            Aliases = @('cidr', 'cidr block', 'ip cidr')
            Notes   = @('Matches IPv4 CIDR notation.')
        }
        'latitude'           = @{
            Pattern = '[+-]?(?:[0-8]?\d(?:\.\d+)?|90(?:\.0+)?)'
            Aliases = @('lat', 'gps latitude')
            Notes   = @('Matches latitude values between -90 and 90.')
        }
        'longitude'          = @{
            Pattern = '[+-]?(?:1[0-7]\d(?:\.\d+)?|[0-9]?\d(?:\.\d+)?|180(?:\.0+)?)'
            Aliases = @('lon', 'lng', 'gps longitude')
            Notes   = @('Matches longitude values between -180 and 180.')
        }
        'coordinates'        = @{
            Pattern = '[+-]?(?:[0-8]?\d(?:\.\d+)?|90(?:\.0+)?)\s*,\s*[+-]?(?:1[0-7]\d(?:\.\d+)?|[0-9]?\d(?:\.\d+)?|180(?:\.0+)?)'
            Aliases = @('lat long', 'latitude longitude', 'gps coordinates', 'geo coordinates')
            Notes   = @('Matches comma-separated latitude and longitude pairs.')
        }
        'html-tag'           = @{
            Pattern = '</?[A-Za-z][A-Za-z0-9]*(?:\s+[^>]*)?>'
            Aliases = @('html element', 'xml tag', 'markup tag')
            Notes   = @('Matches simple HTML or XML tags.')
        }
        'unix-path'          = @{
            Pattern = '(?:/[A-Za-z0-9._-]+)+/?'
            Aliases = @('linux path', 'posix path', 'unix file path')
            Notes   = @('Matches simple absolute Unix-style paths.')
        }
        'windows-path'       = @{
            Pattern = '[A-Za-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*'
            Aliases = @('win path', 'windows file path', 'dos path')
            Notes   = @('Matches simple Windows file paths.')
        }
        'camel-case'         = @{
            Pattern = '[a-z][A-Za-z0-9]*'
            Aliases = @('camelcase', 'camel case identifier', 'camelCase')
            Notes   = @('Matches camelCase identifiers.')
        }
        'snake-case'         = @{
            Pattern = '[a-z][a-z0-9]*(?:_[a-z0-9]+)*'
            Aliases = @('snake_case', 'snake case identifier', 'underscore identifier')
            Notes   = @('Matches snake_case identifiers.')
        }
        'isbn-13'            = @{
            Pattern = '(?:978|979)-\d{1,5}-\d{1,7}-\d{1,7}-\d'
            Aliases = @('isbn', 'isbn13', 'isbn 13')
            Notes   = @('Matches ISBN-13 values with hyphen separators.')
        }
        'jwt-token'          = @{
            Pattern = '[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
            Aliases = @('jwt', 'json web token', 'bearer token')
            Notes   = @('Matches JWT-shaped token strings.')
        }
        'cron-expression'    = @{
            Pattern = '(?:\*|(?:\d+|\d+-\d+|\d+/\d+|\d+(?:,\d+)+))(?:\s+(?:\*|(?:\d+|\d+-\d+|\d+/\d+|\d+(?:,\d+)+))){4}'
            Aliases = @('cron', 'cron schedule', 'crontab')
            Notes   = @('Matches basic 5-field cron expressions.')
        }
        'any-character'      = @{
            Pattern = '.'
            Aliases = @('any char', 'single character')
            Notes   = @('Matches any character except newline by default.')
        }
        'line'               = @{
            Pattern = '^.+$'
            Aliases = @('non-empty line', 'single line', 'line of text')
            Notes   = @('Matches a full non-empty line.')
        }
    }
}

function Resolve-NaturalLanguageRegexCatalogEntry {
    <#
    .SYNOPSIS
        Resolves a catalog entry from a natural language phrase.

    .DESCRIPTION
        Matches catalog names and aliases after normalizing whitespace and case.

    .PARAMETER Phrase
        Natural language phrase to look up.

    .OUTPUTS
        System.Collections.Hashtable with Name, Pattern, and Notes, or null.

    .EXAMPLE
        Resolve-NaturalLanguageRegexCatalogEntry -Phrase 'email address'
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Phrase
    )

    $normalized = ($Phrase -replace '\s+', ' ').Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $null
    }

    $catalog = Get-NaturalLanguageRegexCatalog
    foreach ($entry in $catalog.GetEnumerator()) {
        if ($normalized -eq $entry.Key) {
            return @{
                Name    = $entry.Key
                Pattern = $entry.Value.Pattern
                Notes   = $entry.Value.Notes
            }
        }

        foreach ($alias in $entry.Value.Aliases) {
            if ($normalized -eq $alias) {
                return @{
                    Name    = $entry.Key
                    Pattern = $entry.Value.Pattern
                    Notes   = $entry.Value.Notes
                }
            }
        }
    }

    return $null
}

function Resolve-NaturalLanguageRegexToken {
    <#
    .SYNOPSIS
        Converts a natural language token into a regex fragment.

    .DESCRIPTION
        Checks the built-in catalog first, then applies token maps and quantity
        phrases such as "at least 3 digits" or "starts with 'user-'".

    .PARAMETER Token
        Token or short phrase to convert.

    .OUTPUTS
        System.String. Regex fragment for the token.

    .EXAMPLE
        Resolve-NaturalLanguageRegexToken -Token 'one or more digits'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Token
    )

    $trimmed = ($Token -replace '\s+', ' ').Trim()
    $normalized = $trimmed.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return ''
    }

    $catalogEntry = Resolve-NaturalLanguageRegexCatalogEntry -Phrase $trimmed
    if ($null -ne $catalogEntry) {
        return $catalogEntry.Pattern
    }

    $tokenMap = [ordered]@{
        'digit'             = '\d'
        'digits'            = '\d+'
        'number'            = '\d'
        'numbers'           = '\d+'
        'letter'            = '[A-Za-z]'
        'letters'           = '[A-Za-z]+'
        'alphabetic'        = '[A-Za-z]+'
        'alpha'             = '[A-Za-z]+'
        'alphanumeric'      = '[A-Za-z0-9]+'
        'word'              = '\w+'
        'words'             = '\w+'
        'whitespace'        = '\s+'
        'space'             = ' '
        'spaces'            = '\s+'
        'dot'               = '\.'
        'period'            = '\.'
        'hyphen'            = '-'
        'dash'              = '-'
        'underscore'        = '_'
        'at sign'           = '@'
        'hash'              = '#'
        'pound sign'        = '#'
    }

    if ($tokenMap.Contains($normalized)) {
        return $tokenMap[$normalized]
    }

    if ($normalized -match "^(?:exactly|precisely)\s+(\d+)\s+(digits?|numbers?|letters?|characters?|words?)$") {
        $count = [int]$Matches[1]
        $unit = $Matches[2]
        if ($unit -match 'digit|number') { return "\d{$count}" }
        if ($unit -match 'letter|character') { return "[A-Za-z]{$count}" }
        if ($unit -match 'word') { return "\w{$count}" }
    }

    if ($normalized -match '^(?:at least|minimum of|min)\s+(\d+)\s+(digits?|numbers?|letters?|characters?|words?)$') {
        $count = [int]$Matches[1]
        $unit = $Matches[2]
        if ($unit -match 'digit|number') { return "\d{$count,}" }
        if ($unit -match 'letter|character') { return "[A-Za-z]{$count,}" }
        if ($unit -match 'word') { return "\w{$count,}" }
    }

    if ($normalized -match '^(?:at most|up to|maximum of|max)\s+(\d+)\s+(digits?|numbers?|letters?|characters?|words?)$') {
        $count = [int]$Matches[1]
        $unit = $Matches[2]
        if ($unit -match 'digit|number') { return "\d{0,$count}" }
        if ($unit -match 'letter|character') { return "[A-Za-z]{0,$count}" }
        if ($unit -match 'word') { return "\w{0,$count}" }
    }

    if ($normalized -match '^(?:between)\s+(\d+)\s+and\s+(\d+)\s+(digits?|numbers?|letters?|characters?|words?)$') {
        $minCount = [int]$Matches[1]
        $maxCount = [int]$Matches[2]
        $unit = $Matches[3]
        if ($unit -match 'digit|number') { return "\d{$minCount,$maxCount}" }
        if ($unit -match 'letter|character') { return "[A-Za-z]{$minCount,$maxCount}" }
        if ($unit -match 'word') { return "\w{$minCount,$maxCount}" }
    }

    if ($normalized -match '^(?:one or more|1 or more)\s+(digits?|numbers?|letters?|characters?|words?)$') {
        $unit = $Matches[1]
        if ($unit -match 'digit|number') { return '\d+' }
        if ($unit -match 'letter|character') { return '[A-Za-z]+' }
        if ($unit -match 'word') { return '\w+' }
    }

    if ($normalized -match '^(?:zero or more|optional)\s+(digits?|numbers?|letters?|characters?|words?)$') {
        $unit = $Matches[1]
        if ($unit -match 'digit|number') { return '\d*' }
        if ($unit -match 'letter|character') { return '[A-Za-z]*' }
        if ($unit -match 'word') { return '\w*' }
    }

    if ($trimmed -match "^(?i)(?:starts with|begins with|starting with)\s+(.+)$") {
        $literal = $Matches[1].Trim().Trim('"', "'")
        return "^{0}" -f (Escape-RegexLiteral -Text $literal)
    }

    if ($trimmed -match "^(?i)(?:ends with|ending with)\s+(.+)$") {
        $literal = $Matches[1].Trim().Trim('"', "'")
        return "{0}$" -f (Escape-RegexLiteral -Text $literal)
    }

    if ($trimmed -match "^(?i)(?:contains|including|has|with)\s+(.+)$") {
        $literal = $Matches[1].Trim().Trim('"', "'")
        return ".*{0}.*" -f (Escape-RegexLiteral -Text $literal)
    }

    if ($trimmed -match "^(?i)(?:the (?:word|text|literal|string))\s+['""](.+?)['""]$") {
        return Escape-RegexLiteral -Text $Matches[1]
    }

    if ($trimmed -match "^['""](.+?)['""]$") {
        return Escape-RegexLiteral -Text $Matches[1]
    }

    if ($normalized -match '^all uppercase letters?$') {
        return '[A-Z]+'
    }

    if ($normalized -match '^all lowercase letters?$') {
        return '[a-z]+'
    }

    if ($normalized -match '^(?:hexadecimal|hex)(?:\s+number)?$') {
        return '[0-9A-Fa-f]+'
    }

    if ($normalized -match '^(?:binary)(?:\s+number)?$') {
        return '[01]+'
    }

    if ($normalized -match '^(?:newline|line break)$') {
        return '\n'
    }

    if ($normalized -match '^tab$') {
        return '\t'
    }

    if ($trimmed -match "^(?i)(?:separated by|delimited by)\s+['""](.+?)['""]$") {
        $delimiter = Escape-RegexLiteral -Text $Matches[1]
        return "(?:[A-Za-z0-9]+(?:$delimiter[A-Za-z0-9]+)*)"
    }

    return Escape-RegexLiteral -Text $trimmed
}

function Resolve-NaturalLanguageRegexAlternation {
    <#
.SYNOPSIS
        Builds a non-capturing alternation pattern from an either/or phrase.

    .PARAMETER Phrase
        Phrase beginning with "one of" or "either" followed by options joined by "or".

    .OUTPUTS
        System.String. Non-capturing alternation pattern, or null when parsing fails.

    .EXAMPLE
.DESCRIPTION
    Builds a non-capturing alternation pattern from an either/or phrase.
    .PARAMETER Phrase
    Phrase beginning with "one of" or "either" followed by options joined by "or".
    .OUTPUTS
    System.String. Non-capturing alternation pattern, or null when parsing fails.
    .EXAMPLE
        Resolve-NaturalLanguageRegexAlternation -Phrase 'either digits or letters'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Phrase
    )

    if ($Phrase -notmatch '^(?i)(?:one of|either)\s+(.+)$') {
        return $null
    }

    $options = $Matches[1] -split '(?i)\s+or\s+'
    $patterns = foreach ($option in $options) {
        $trimmedOption = $option.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedOption)) {
            continue
        }

        $catalogEntry = Resolve-NaturalLanguageRegexCatalogEntry -Phrase $trimmedOption
        if ($null -ne $catalogEntry) {
            $catalogEntry.Pattern
            continue
        }

        Resolve-NaturalLanguageRegexToken -Token $trimmedOption
    }

    $resolvedPatterns = @($patterns | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($resolvedPatterns.Count -lt 2) {
        return $null
    }

    return '(?:{0})' -f ($resolvedPatterns -join '|')
}

function Search-NaturalLanguageRegexCatalog {
    <#
    .SYNOPSIS
        Searches natural language regex catalog entries.

    .DESCRIPTION
        Finds catalog entries whose names or aliases match a query string.

    .PARAMETER Query
        Search text to match against catalog names and aliases.

    .OUTPUTS
        PSCustomObject[] with Name, Pattern, Aliases, and MatchType members.

    .EXAMPLE
        Search-NaturalLanguageRegexCatalog -Query 'email'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query
    )

    process {
        $normalizedQuery = ($Query -replace '\s+', ' ').Trim().ToLowerInvariant()
        $catalog = Get-NaturalLanguageRegexCatalog
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()

        foreach ($entry in $catalog.GetEnumerator()) {
            $matchType = $null
            if ($entry.Key -eq $normalizedQuery) {
                $matchType = 'name'
            }
            elseif ($entry.Key -like "*$normalizedQuery*") {
                $matchType = 'name-contains'
            }
            else {
                foreach ($alias in $entry.Value.Aliases) {
                    if ($alias -eq $normalizedQuery) {
                        $matchType = 'alias'
                        break
                    }
                    if ($alias -like "*$normalizedQuery*") {
                        $matchType = 'alias-contains'
                    }
                }
            }

            if ($null -ne $matchType) {
                $results.Add([PSCustomObject]@{
                        Name      = $entry.Key
                        Pattern   = $entry.Value.Pattern
                        Aliases   = $entry.Value.Aliases
                        Notes     = $entry.Value.Notes
                        MatchType = $matchType
                    })
            }
        }

        $results | Sort-Object Name
    }
}

function Resolve-RegexPatternFromAiResponse {
    <#
    .SYNOPSIS
        Extracts a regex pattern from an AI model response.

    .DESCRIPTION
        Normalizes AI output by removing markdown fences, labels, and surrounding
        delimiters before validating the resulting regex pattern.

    .PARAMETER Response
        Raw text returned by an AI model.

    .OUTPUTS
        PSCustomObject with Pattern, IsValid, and Notes members.

    .EXAMPLE
        Resolve-RegexPatternFromAiResponse -Response '```regex\n\d+\n```'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Response
    )

    $notes = [System.Collections.Generic.List[string]]::new()
    $candidate = ($Response -replace '\r\n?', "`n").Trim()

    if ($candidate -match '```(?:regex|regexp)?\s*\n([\s\S]*?)\n```') {
        $candidate = $Matches[1].Trim()
        $notes.Add('Extracted pattern from fenced code block.')
    }

    $candidate = $candidate -replace '^(?i)(?:pattern|regex|regular expression)\s*:\s*', ''
    $candidate = $candidate.Trim().Trim('`').Trim()

    if (
        ($candidate.StartsWith('/') -and $candidate.EndsWith('/')) -or
        ($candidate.StartsWith('^/') -and $candidate.EndsWith('/$'))
    ) {
        $candidate = $candidate.Trim('^', '$').Trim('/')
        $notes.Add('Removed slash delimiters from AI response.')
    }

    $candidate = $candidate.Trim('"', "'")

    $isValid = $false
    try {
        $null = [regex]::new($candidate)
        $isValid = $true
    }
    catch {
        $notes.Add("AI pattern failed validation: $($_.Exception.Message)")
    }

    [PSCustomObject]@{
        Pattern = $candidate
        IsValid = $isValid
        Notes   = $notes.ToArray()
    }
}

function Test-NaturalLanguageRegexNeedsAiFallback {
    <#
    .SYNOPSIS
        Determines whether a conversion result should fall back to AI assistance.

    .DESCRIPTION
        Returns true when token-based conversion only escaped the original text
        verbatim, indicating the catalog and token rules did not understand it.

    .PARAMETER Result
        Conversion result object from ConvertTo-RegexFromNaturalLanguage.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-NaturalLanguageRegexNeedsAiFallback -Result $conversion
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Result
    )

    if ($Result.Source -ne 'token') {
        return $false
    }

    $escapedDescription = Escape-RegexLiteral -Text (($Result.Description -replace '\s+', ' ').Trim())
    return $Result.Pattern -eq $escapedDescription
}

function Test-NaturalLanguageRegexSamples {
    <#
.SYNOPSIS
        Evaluates sample strings against a regex pattern.

    .PARAMETER Pattern
        Regular expression pattern to test.

    .PARAMETER IgnoreCase
        Uses case-insensitive matching when true.

    .PARAMETER SampleMatch
        Strings expected to match the pattern.

    .PARAMETER SampleNoMatch
        Strings expected not to match the pattern.

    .OUTPUTS
        PSCustomObject[] with Input, Expected, Success, and ActualMatch members.

    .EXAMPLE
.DESCRIPTION
    Evaluates sample strings against a regex pattern.
    .PARAMETER Pattern
    Regular expression pattern to test.
    .PARAMETER IgnoreCase
    Uses case-insensitive matching when true.
    .PARAMETER SampleMatch
    Strings expected to match the pattern.
    .PARAMETER SampleNoMatch
    Strings expected not to match the pattern.
    .OUTPUTS
    PSCustomObject[] with Input, Expected, Success, and ActualMatch members.
    .EXAMPLE
        Test-NaturalLanguageRegexSamples -Pattern '\d+' -SampleMatch '42' -SampleNoMatch 'abc'
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern,

        [bool]$IgnoreCase = $false,

        [string[]]$SampleMatch = @(),

        [string[]]$SampleNoMatch = @()
    )

    $options = if ($IgnoreCase) {
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }
    else {
        [System.Text.RegularExpressions.RegexOptions]::None
    }

    $regex = [regex]::new($Pattern, $options)
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($sample in $SampleMatch) {
        $matched = $regex.IsMatch($sample)
        $results.Add([PSCustomObject]@{
                Input       = $sample
                Expected    = 'match'
                Success     = $matched
                ActualMatch = $matched
            })
    }

    foreach ($sample in $SampleNoMatch) {
        $matched = $regex.IsMatch($sample)
        $results.Add([PSCustomObject]@{
                Input       = $sample
                Expected    = 'no-match'
                Success     = -not $matched
                ActualMatch = $matched
            })
    }

    return $results.ToArray()
}

function ConvertTo-RegexFromNaturalLanguage {
    <#
    .SYNOPSIS
        Converts a natural language description into a regular expression pattern.

    .DESCRIPTION
        Translates common natural language regex descriptions into regular expression
        patterns. Supports built-in catalog entries such as email, URL, IPv4, UUID,
        and compositional phrases such as "starts with foo and ends with bar".

    .PARAMETER Description
        Natural language description of the desired pattern.

    .PARAMETER Anchored
        When specified, wraps the resulting pattern with ^ and $ if they are not already present.

    .PARAMETER IgnoreCase
        When specified, marks the result as case-insensitive. The returned object includes
        this flag for callers to apply when constructing a Regex object.

    .PARAMETER SampleMatch
        Optional sample strings that are expected to match the generated pattern.

    .PARAMETER SampleNoMatch
        Optional sample strings that are expected not to match the generated pattern.

    .PARAMETER AiPattern
        Optional regex pattern produced by an external AI provider. When the rule-based
        converter cannot interpret the description, this value is used instead.

    .OUTPUTS
        PSCustomObject with Pattern, Description, Source, IgnoreCase, Notes, IsValid,
        CatalogName, NeedsAiFallback, and SampleResults members.

    .EXAMPLE
        ConvertTo-RegexFromNaturalLanguage -Description 'email'

        Returns a regex pattern for email addresses.

    .EXAMPLE
        ConvertTo-RegexFromNaturalLanguage -Description "starts with 'user-' followed by digits" -Anchored

        Returns a composed regex pattern anchored to the full input.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [switch]$Anchored,

        [switch]$IgnoreCase,

        [string[]]$SampleMatch = @(),

        [string[]]$SampleNoMatch = @(),

        [string]$AiPattern
    )

    process {
        $normalized = ($Description -replace '\s+', ' ').Trim()
        $notes = [System.Collections.Generic.List[string]]::new()
        $ignoreCaseRequested = [bool]$IgnoreCase.IsPresent
        $catalogName = $null
        $source = 'token'
        $pattern = $null

        if ($normalized -match '(?i)\bcase[- ]?insensitive\b') {
            $ignoreCaseRequested = $true
            $normalized = ($normalized -replace '(?i)\bcase[- ]?insensitive\b', '').Trim()
            $notes.Add('Applied case-insensitive flag from description.')
        }

        $alternationPattern = Resolve-NaturalLanguageRegexAlternation -Phrase $normalized
        if ($null -ne $alternationPattern) {
            $pattern = $alternationPattern
            $source = 'alternation'
            $notes.Add('Built alternation pattern from one-of description.')
        }
        else {
            $catalogEntry = Resolve-NaturalLanguageRegexCatalogEntry -Phrase $normalized
            if ($null -ne $catalogEntry) {
                $pattern = $catalogEntry.Pattern
                $source = 'catalog'
                $catalogName = $catalogEntry.Name
                foreach ($note in @($catalogEntry.Notes)) {
                    $notes.Add([string]$note)
                }
            }
            else {
                $segments = $normalized -split '(?i)\s+(?:and|then|followed by|,)\s+'
                $segmentPatterns = foreach ($segment in $segments) {
                    $trimmedSegment = $segment.Trim()
                    if ([string]::IsNullOrWhiteSpace($trimmedSegment)) {
                        continue
                    }

                    Resolve-NaturalLanguageRegexToken -Token $trimmedSegment
                }

                $pattern = ($segmentPatterns -join '')
                $source = if ($segments.Count -gt 1) { 'composed' } else { 'token' }
                $notes.Add('Built pattern from natural language phrase segments.')
            }
        }

        if ($Anchored) {
            if (-not $pattern.StartsWith('^')) {
                $pattern = "^{0}" -f $pattern
            }
            if (-not $pattern.EndsWith('$')) {
                $pattern = "{0}$" -f $pattern
            }
            $notes.Add('Anchored pattern to full input with ^ and $.')
        }

        $needsAiFallback = Test-NaturalLanguageRegexNeedsAiFallback -Result ([PSCustomObject]@{
                Pattern     = $pattern
                Description = $Description
                Source      = $source
            })

        if (-not [string]::IsNullOrWhiteSpace($AiPattern)) {
            $pattern = $AiPattern.Trim()
            $source = 'ai'
            $catalogName = $null
            $needsAiFallback = $false
            $notes.Add('Applied AI-generated regex pattern.')
        }

        $result = [PSCustomObject]@{
            Pattern          = $pattern
            Description      = $Description
            Source           = $source
            IgnoreCase       = $ignoreCaseRequested
            Notes            = $notes.ToArray()
            IsValid          = $false
            CatalogName      = $catalogName
            NeedsAiFallback  = $needsAiFallback
        }

        try {
            $null = [regex]::new($pattern)
            $result.IsValid = $true
        }
        catch {
            $result.IsValid = $false
            $notes.Add("Generated pattern failed validation: $($_.Exception.Message)")
            $result.Notes = $notes.ToArray()
        }

        if ($SampleMatch.Count -gt 0 -or $SampleNoMatch.Count -gt 0) {
            $sampleResults = Test-NaturalLanguageRegexSamples `
                -Pattern $result.Pattern `
                -IgnoreCase $result.IgnoreCase `
                -SampleMatch $SampleMatch `
                -SampleNoMatch $SampleNoMatch
            $result | Add-Member -NotePropertyName 'SampleResults' -NotePropertyValue $sampleResults -Force
        }

        $result
    }
}

function Get-NaturalLanguageRegexCatalogItems {
    <#
.SYNOPSIS
        Returns catalog entries as pipeline-friendly objects.

    .OUTPUTS
        PSCustomObject[] with Name, Pattern, Aliases, AliasCount, and Notes members.

    .EXAMPLE
.DESCRIPTION
    Returns catalog entries as pipeline-friendly objects.
    .OUTPUTS
    PSCustomObject[] with Name, Pattern, Aliases, AliasCount, and Notes members.
    .EXAMPLE
        Get-NaturalLanguageRegexCatalogItems | Where-Object Name -eq 'email'
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $catalog = Get-NaturalLanguageRegexCatalog
    $catalog.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.Key
            Pattern    = $_.Value.Pattern
            Aliases    = ($_.Value.Aliases -join ', ')
            AliasCount = $_.Value.Aliases.Count
            Notes      = ($_.Value.Notes -join ' ')
        }
    } | Sort-Object Name
}

function Split-RegexAlternationOptions {
    <#
.SYNOPSIS
        Splits a regex alternation body on top-level pipe characters.

    .PARAMETER Body
        Inner body of a non-capturing alternation group.

    .OUTPUTS
        System.String[]

    .EXAMPLE
.DESCRIPTION
    Splits a regex alternation body on top-level pipe characters.
    .PARAMETER Body
    Inner body of a non-capturing alternation group.
    .OUTPUTS
    System.String[]
    .EXAMPLE
        Split-RegexAlternationOptions -Body 'foo|bar|baz'
#>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    $options = [System.Collections.Generic.List[string]]::new()
    $current = [System.Text.StringBuilder]::new()
    $depth = 0

    foreach ($char in $Body.ToCharArray()) {
        if ($char -eq '(') {
            $depth++
        }
        elseif ($char -eq ')') {
            $depth--
        }

        if ($char -eq '|' -and $depth -eq 0) {
            $options.Add($current.ToString())
            [void]$current.Clear()
            continue
        }

        [void]$current.Append($char)
    }

    if ($current.Length -gt 0) {
        $options.Add($current.ToString())
    }

    return $options.ToArray()
}

function Resolve-OutermostRegexGroupBody {
    <#
.SYNOPSIS
        Extracts the inner body of an outermost non-capturing group.

    .PARAMETER Pattern
        Regex pattern that may begin with (?:

    .OUTPUTS
        System.String. Group body without the wrapping (?:...), or null.

    .EXAMPLE
.DESCRIPTION
    Extracts the inner body of an outermost non-capturing group.
    .PARAMETER Pattern
    Regex pattern that may begin with (?:
    .OUTPUTS
    System.String. Group body without the wrapping (?:...), or null.
    .EXAMPLE
        Resolve-OutermostRegexGroupBody -Pattern '(?:foo|bar)'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    if (-not $Pattern.StartsWith('(?:')) {
        return $null
    }

    $depth = 0

    for ($i = 0; $i -lt $Pattern.Length; $i++) {
        if ($i -le ($Pattern.Length - 3) -and $Pattern.Substring($i).StartsWith('(?:')) {
            $depth++
            $i += 2
            continue
        }

        if ($Pattern[$i] -eq '(') {
            $depth++
            continue
        }

        if ($Pattern[$i] -eq ')') {
            $depth--
            if ($depth -eq 0 -and $i -gt 3) {
                return $Pattern.Substring(3, $i - 3)
            }
        }
    }

    return $null
}

function Resolve-RegexCatalogEntryByPattern {
    <#
.SYNOPSIS
        Finds a catalog entry that matches a regex pattern.

    .PARAMETER Pattern
        Regex pattern to reverse-map into catalog metadata.

    .OUTPUTS
        System.Collections.Hashtable with Name, Pattern, Aliases, and Notes, or null.

    .EXAMPLE
.DESCRIPTION
    Finds a catalog entry that matches a regex pattern.
    .PARAMETER Pattern
    Regex pattern to reverse-map into catalog metadata.
    .OUTPUTS
    System.Collections.Hashtable with Name, Pattern, Aliases, and Notes, or null.
    .EXAMPLE
        Resolve-RegexCatalogEntryByPattern -Pattern '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $candidates = @($Pattern)
    $startsAnchored = $Pattern.StartsWith('^')
    $endsAnchored = $Pattern.EndsWith('$')
    $core = $Pattern
    if ($startsAnchored) { $core = $core.Substring(1) }
    if ($endsAnchored -and $core.EndsWith('$')) { $core = $core.Substring(0, $core.Length - 1) }
    $candidates += $core

    $catalog = Get-NaturalLanguageRegexCatalog
    foreach ($candidate in $candidates | Select-Object -Unique) {
        foreach ($entry in $catalog.GetEnumerator()) {
            if ($entry.Value.Pattern -eq $candidate) {
                return @{
                    Name    = $entry.Key
                    Pattern = $entry.Value.Pattern
                    Aliases = $entry.Value.Aliases
                    Notes   = $entry.Value.Notes
                }
            }
        }
    }

    return $null
}

function Resolve-RegexPatternExplanationComponents {
    <#
.SYNOPSIS
        Decomposes a regex pattern into plain-language components.

    .PARAMETER Pattern
        Regex pattern core without leading ^ or trailing $ anchors.

    .OUTPUTS
        System.String[]

    .EXAMPLE
.DESCRIPTION
    Decomposes a regex pattern into plain-language components.
    .PARAMETER Pattern
    Regex pattern core without leading ^ or trailing $ anchors.
    .OUTPUTS
    System.String[]
    .EXAMPLE
        Resolve-RegexPatternExplanationComponents -Pattern '\d+'
#>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $components = [System.Collections.Generic.List[string]]::new()
    $remaining = $Pattern

    $rules = @(
        @{ Regex = '^\\d\{(\d+),(\d+)\}'; Text = { param($m) "between $($m.Groups[1].Value) and $($m.Groups[2].Value) digits" } }
        @{ Regex = '^\\d\{(\d+),\}'; Text = { param($m) "at least $($m.Groups[1].Value) digits" } }
        @{ Regex = '^\\d\{(\d+)\}'; Text = { param($m) "exactly $($m.Groups[1].Value) digits" } }
        @{ Regex = '^\\w\{(\d+),(\d+)\}'; Text = { param($m) "between $($m.Groups[1].Value) and $($m.Groups[2].Value) word characters" } }
        @{ Regex = '^\\w\+'; Text = { 'one or more word characters' } }
        @{ Regex = '^\\w\*'; Text = { 'zero or more word characters' } }
        @{ Regex = '^\\w'; Text = { 'a word character' } }
        @{ Regex = '^\\d\+'; Text = { 'one or more digits' } }
        @{ Regex = '^\\d\*'; Text = { 'zero or more digits' } }
        @{ Regex = '^\\d'; Text = { 'a digit' } }
        @{ Regex = '^\[A-Za-z0-9\]\+'; Text = { 'one or more alphanumeric characters' } }
        @{ Regex = '^\[A-Za-z0-9\]\*'; Text = { 'zero or more alphanumeric characters' } }
        @{ Regex = '^\[A-Za-z\]\+'; Text = { 'one or more letters' } }
        @{ Regex = '^\[A-Za-z\]\*'; Text = { 'zero or more letters' } }
        @{ Regex = '^\[A-Za-z\]'; Text = { 'a letter' } }
        @{ Regex = '^\[A-Z\]\+'; Text = { 'one or more uppercase letters' } }
        @{ Regex = '^\[a-z\]\+'; Text = { 'one or more lowercase letters' } }
        @{ Regex = '^\\s\+'; Text = { 'one or more whitespace characters' } }
        @{ Regex = '^\\s\*'; Text = { 'zero or more whitespace characters' } }
        @{ Regex = '^\\s'; Text = { 'whitespace' } }
        @{ Regex = '^\.\*'; Text = { 'any characters' } }
        @{ Regex = '^\.\+'; Text = { 'one or more characters' } }
        @{ Regex = '^\\n'; Text = { 'a newline' } }
        @{ Regex = '^\\t'; Text = { 'a tab' } }
        @{ Regex = '^\\.'; Text = { param($m) "literal '$($m.Value.Substring(1))'" } }
        @{ Regex = '^\.'; Text = { 'any character' } }
    )

    while (-not [string]::IsNullOrEmpty($remaining)) {
        $consumed = $false

        foreach ($rule in $rules) {
            $match = [regex]::Match($remaining, $rule.Regex)
            if ($match.Success) {
                $text = & $rule.Text $match
                $components.Add([string]$text)
                $remaining = $remaining.Substring($match.Length)
                $consumed = $true
                break
            }
        }

        if ($consumed) {
            continue
        }

        if ($remaining.StartsWith('\')) {
            if ($remaining.Length -ge 2) {
                $components.Add("literal '$($remaining.Substring(1, 1))'")
                $remaining = $remaining.Substring(2)
                continue
            }
        }

        $literalMatch = [regex]::Match($remaining, '^[^\[\(\\]+')
        if ($literalMatch.Success -and -not [string]::IsNullOrEmpty($literalMatch.Value)) {
            $components.Add("literal '$($literalMatch.Value)'")
            $remaining = $remaining.Substring($literalMatch.Length)
            continue
        }

        $components.Add("literal '$($remaining.Substring(0, 1))'")
        $remaining = $remaining.Substring(1)
    }

    return $components.ToArray()
}

function ConvertFrom-RegexToNaturalLanguage {
    <#
    .SYNOPSIS
        Explains a regular expression pattern in plain language.

    .DESCRIPTION
        Reverse direction of the natural language regex converter. Attempts to map
        known catalog patterns back to descriptions and decomposes common regex
        constructs into readable phrases.

    .PARAMETER Pattern
        Regular expression pattern to explain.

    .PARAMETER Detailed
        When specified, includes per-component explanations.

    .OUTPUTS
        PSCustomObject with Pattern, Description, Components, CatalogName, Source,
        Confidence, StartsAnchored, EndsAnchored, and IsValid members.

    .EXAMPLE
        ConvertFrom-RegexToNaturalLanguage -Pattern '^\d+$' -Detailed
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern,

        [switch]$Detailed
    )

    process {
        $isValid = $true
        try {
            $null = [regex]::new($Pattern)
        }
        catch {
            $isValid = $false
        }

        $startsAnchored = $Pattern.StartsWith('^')
        $endsAnchored = $Pattern.EndsWith('$')
        $core = $Pattern
        if ($startsAnchored) { $core = $core.Substring(1) }
        if ($endsAnchored -and $core.EndsWith('$')) { $core = $core.Substring(0, $core.Length - 1) }

        $catalogEntry = Resolve-RegexCatalogEntryByPattern -Pattern $Pattern
        if ($null -ne $catalogEntry) {
            $description = if ($catalogEntry.Aliases.Count -gt 0) { $catalogEntry.Aliases[0] } else { $catalogEntry.Name -replace '-', ' ' }
            if ($startsAnchored -and $endsAnchored) { $description = "exactly $description" }
            elseif ($startsAnchored) { $description = "starts with $description" }
            elseif ($endsAnchored) { $description = "ends with $description" }

            return [PSCustomObject]@{
                Pattern        = $Pattern
                Description    = $description
                Components     = if ($Detailed) { @($description) } else { @() }
                CatalogName    = $catalogEntry.Name
                Source         = 'catalog'
                Confidence     = 'high'
                StartsAnchored = $startsAnchored
                EndsAnchored   = $endsAnchored
                IsValid        = $isValid
            }
        }

        $alternationBody = Resolve-OutermostRegexGroupBody -Pattern $core
        $isWrappedAlternation = $null -ne $alternationBody -and "(?:$alternationBody)" -eq $core
        if ($isWrappedAlternation -and $alternationBody.Contains('|')) {
            $options = Split-RegexAlternationOptions -Body $alternationBody
            if ($options.Count -ge 2) {
                $optionDescriptions = foreach ($option in $options) {
                    $sub = ConvertFrom-RegexToNaturalLanguage -Pattern $option.Trim()
                    $sub.Description
                }
                $description = 'either {0}' -f ($optionDescriptions -join ' or ')
                if ($startsAnchored -and $endsAnchored) { $description = "exactly matches $description" }
                elseif ($startsAnchored) { $description = "starts with $description" }
                elseif ($endsAnchored) { $description = "ends with $description" }

                return [PSCustomObject]@{
                    Pattern        = $Pattern
                    Description    = $description
                    Components     = if ($Detailed) { $optionDescriptions } else { @() }
                    CatalogName    = $null
                    Source         = 'alternation'
                    Confidence     = 'medium'
                    StartsAnchored = $startsAnchored
                    EndsAnchored   = $endsAnchored
                    IsValid        = $isValid
                }
            }
        }

        $components = Resolve-RegexPatternExplanationComponents -Pattern $core
        $description = if ($components.Count -gt 0) {
            ($components -join ' followed by ')
        }
        else {
            'unrecognized pattern'
        }

        if ($startsAnchored -and $endsAnchored) { $description = "exactly matches $description" }
        elseif ($startsAnchored) { $description = "starts with $description" }
        elseif ($endsAnchored) { $description = "ends with $description" }

        $confidence = if ($components.Count -gt 0) { 'medium' } else { 'low' }

        [PSCustomObject]@{
            Pattern        = $Pattern
            Description    = $description
            Components     = if ($Detailed) { $components } else { @() }
            CatalogName    = $null
            Source         = 'decomposed'
            Confidence     = $confidence
            StartsAnchored = $startsAnchored
            EndsAnchored   = $endsAnchored
            IsValid        = $isValid
        }
    }
}

function Format-NaturalLanguageRegexResult {
    <#
    .SYNOPSIS
        Formats natural language regex conversion or explanation results.

    .DESCRIPTION
        Renders structured conversion or explanation objects as plain text or JSON
        for display, logging, or export.

    .PARAMETER Result
        Result object from ConvertTo-RegexFromNaturalLanguage or ConvertFrom-RegexToNaturalLanguage.

    .PARAMETER As
        Output format: Object (default), Text, or Json.

    .OUTPUTS
        PSCustomObject, System.String, or JSON text depending on -As.

    .EXAMPLE
        $result | Format-NaturalLanguageRegexResult -As Text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        $Result,

        [ValidateSet('Object', 'Text', 'Json')]
        [string]$As = 'Object'
    )

    process {
        if ($As -eq 'Object') {
            return $Result
        }

        if ($As -eq 'Json') {
            return ($Result | ConvertTo-Json -Depth 6)
        }

        $lines = [System.Collections.Generic.List[string]]::new()

        if ($Result.PSObject.Properties.Name -contains 'Pattern') {
            $lines.Add("Pattern: $($Result.Pattern)")
        }

        if ($Result.PSObject.Properties.Name -contains 'Description') {
            $lines.Add("Description: $($Result.Description)")
        }

        if ($Result.CatalogName) {
            $lines.Add("Catalog: $($Result.CatalogName)")
        }

        if ($Result.PSObject.Properties.Name -contains 'Source') {
            $lines.Add("Source: $($Result.Source)")
        }

        if ($Result.PSObject.Properties.Name -contains 'Confidence') {
            $lines.Add("Confidence: $($Result.Confidence)")
        }

        if ($Result.IgnoreCase) {
            $lines.Add('Flags: IgnoreCase')
        }

        if ($Result.PSObject.Properties.Name -contains 'IsValid') {
            $lines.Add("Valid: $($Result.IsValid)")
        }

        if ($Result.Notes -and $Result.Notes.Count -gt 0) {
            $lines.Add('Notes:')
            foreach ($note in $Result.Notes) {
                $lines.Add("  - $note")
            }
        }

        if ($Result.Components -and $Result.Components.Count -gt 0) {
            $lines.Add('Components:')
            foreach ($component in $Result.Components) {
                $lines.Add("  - $component")
            }
        }

        if ($Result.SampleResults -and $Result.SampleResults.Count -gt 0) {
            $lines.Add('Sample Results:')
            foreach ($sampleResult in $Result.SampleResults) {
                $status = if ($sampleResult.Success) { 'pass' } else { 'fail' }
                $lines.Add("  - [$status] $($sampleResult.Expected): $($sampleResult.Input)")
            }
        }

        if ($Result.PSObject.Properties.Name -contains 'Similarity') {
            $lines.Add("Similarity: $([Math]::Round($Result.Similarity, 4))")
        }

        if ($Result.PSObject.Properties.Name -contains 'IsConsistent') {
            $lines.Add("Consistent: $($Result.IsConsistent)")
        }

        if ($Result.PSObject.Properties.Name -contains 'PatternMatches') {
            $lines.Add("Pattern Round-Trip: $($Result.PatternMatches)")
        }

        if ($Result.ExplainedDescription) {
            $lines.Add("Explained: $($Result.ExplainedDescription)")
        }

        return ($lines -join [Environment]::NewLine)
    }
}

function Normalize-NaturalLanguageRegexDescription {
    <#
.SYNOPSIS
        Normalizes a natural language regex description for comparison.

    .PARAMETER Text
        Description text to normalize.

    .OUTPUTS
        System.String

    .EXAMPLE
.DESCRIPTION
    Normalizes a natural language regex description for comparison.
    .PARAMETER Text
    Description text to normalize.
    .OUTPUTS
    System.String
    .EXAMPLE
        Normalize-NaturalLanguageRegexDescription -Text 'One or More Digits!'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    $normalized = ($Text.ToLowerInvariant() -replace '[^\p{L}\p{N}\s-]', ' ' -replace '[-]+', '' -replace '\s+', ' ').Trim()
    return $normalized
}

function Measure-NaturalLanguageRegexSimilarity {
    <#
    .SYNOPSIS
        Measures similarity between two natural language regex descriptions.

    .DESCRIPTION
        Uses token-based Jaccard similarity after normalizing descriptions.

    .PARAMETER Left
        First description to compare.

    .PARAMETER Right
        Second description to compare.

    .OUTPUTS
        System.Double between 0 and 1.

    .EXAMPLE
        Measure-NaturalLanguageRegexSimilarity -Left 'digits' -Right 'one or more digits'
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Left,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Right
    )

    $normalizedLeft = Normalize-NaturalLanguageRegexDescription -Text $Left
    $normalizedRight = Normalize-NaturalLanguageRegexDescription -Text $Right

    if ($normalizedLeft -eq $normalizedRight) {
        return 1.0
    }

    if ([string]::IsNullOrWhiteSpace($normalizedLeft) -or [string]::IsNullOrWhiteSpace($normalizedRight)) {
        return 0.0
    }

    $leftTokens = @($normalizedLeft -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $rightTokens = @($normalizedRight -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $intersection = @($leftTokens | Where-Object { $_ -in $rightTokens })
    $union = @($leftTokens + $rightTokens | Select-Object -Unique)

    if ($union.Count -eq 0) {
        return 0.0
    }

    return [double]$intersection.Count / [double]$union.Count
}

function Build-NaturalLanguageRegexDescription {
    <#
.SYNOPSIS
        Builds a natural language regex description from structured segments.

    .PARAMETER Segments
        Ordered phrase segments such as "starts with 'user-'" and "digits".

    .PARAMETER Alternation
        When specified, wraps segments as an either/or description.

    .OUTPUTS
        System.String description.

    .EXAMPLE
.DESCRIPTION
    Builds a natural language regex description from structured segments.
    .PARAMETER Segments
    Ordered phrase segments such as "starts with 'user-'" and "digits".
    .PARAMETER Alternation
    When specified, wraps segments as an either/or description.
    .OUTPUTS
    System.String description.
    .EXAMPLE
        Build-NaturalLanguageRegexDescription -Segments @('starts with user-', 'digits')
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$Segments,

        [switch]$Alternation
    )

    $trimmedSegments = @($Segments | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($trimmedSegments.Count -eq 0) {
        throw 'At least one non-empty segment is required.'
    }

    if ($Alternation) {
        if ($trimmedSegments.Count -lt 2) {
            throw 'Alternation descriptions require at least two segments.'
        }

        return 'either {0}' -f ($trimmedSegments -join ' or ')
    }

    if ($trimmedSegments.Count -eq 1) {
        return $trimmedSegments[0]
    }

    return ($trimmedSegments -join ' followed by ')
}

function Test-NaturalLanguageRegexRoundTrip {
    <#
    .SYNOPSIS
        Validates description-to-pattern-to-description round-trip consistency.

    .DESCRIPTION
        Converts a description to a regex pattern, explains the pattern back to
        natural language, and scores similarity between the original and explained
        descriptions. Also checks whether re-converting the explained description
        reproduces the original pattern.

    .PARAMETER Description
        Original natural language description.

    .PARAMETER MinimumSimilarity
        Minimum Jaccard similarity required to mark the round-trip as consistent.

    .OUTPUTS
        PSCustomObject with Forward, Explained, Similarity, PatternMatches, and IsConsistent.

    .EXAMPLE
        Test-NaturalLanguageRegexRoundTrip -Description 'one or more digits' -Anchored
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [switch]$Anchored,

        [switch]$IgnoreCase,

        [double]$MinimumSimilarity = 0.35
    )

    $forward = ConvertTo-RegexFromNaturalLanguage `
        -Description $Description `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase

    $explained = ConvertFrom-RegexToNaturalLanguage -Pattern $forward.Pattern
    $similarity = Measure-NaturalLanguageRegexSimilarity -Left $Description -Right $explained.Description

    $reconverted = ConvertTo-RegexFromNaturalLanguage `
        -Description $explained.Description `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase

    $patternMatches = $reconverted.Pattern -eq $forward.Pattern
    $isConsistent = $patternMatches -or ($similarity -ge $MinimumSimilarity)

    [PSCustomObject]@{
        OriginalDescription  = $Description
        ExplainedDescription = $explained.Description
        Pattern              = $forward.Pattern
        ReconvertedPattern   = $reconverted.Pattern
        Forward              = $forward
        Explained            = $explained
        Similarity           = $similarity
        PatternMatches       = $patternMatches
        IsConsistent         = $isConsistent
        MinimumSimilarity    = $MinimumSimilarity
    }
}

function Export-NaturalLanguageRegexCatalogDocument {
    <#
.SYNOPSIS
        Exports the natural language regex catalog as JSON or Markdown.

    .PARAMETER Format
        Output format: Json or Markdown.

    .PARAMETER Path
        Optional file path to write the export.

    .OUTPUTS
        System.String document contents. Also writes to -Path when specified.

    .EXAMPLE
.DESCRIPTION
    Exports the natural language regex catalog as JSON or Markdown.
    .PARAMETER Format
    Output format: Json or Markdown.
    .PARAMETER Path
    Optional file path to write the export.
    .OUTPUTS
    System.String document contents. Also writes to -Path when specified.
    .EXAMPLE
        Export-NaturalLanguageRegexCatalogDocument -Format Markdown -Path './catalog.md'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [ValidateSet('Json', 'Markdown')]
        [string]$Format = 'Json',

        [string]$Path
    )

    $items = Get-NaturalLanguageRegexCatalogItems
    $content = $null

    if ($Format -eq 'Json') {
        $payload = foreach ($item in $items) {
            [PSCustomObject]@{
                name    = $item.Name
                pattern = $item.Pattern
                aliases = @($item.Aliases -split ',\s*')
                notes   = $item.Notes
            }
        }
        $content = $payload | ConvertTo-Json -Depth 5
    }
    else {
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add('# Natural Language Regex Catalog')
        $lines.Add('')
        $lines.Add('Built-in descriptions supported by the natural language regex converter.')
        $lines.Add('')

        foreach ($item in $items) {
            $lines.Add("## $($item.Name)")
            $lines.Add('')
            $lines.Add("- **Pattern:** ``$($item.Pattern)``")
            $lines.Add("- **Aliases:** $($item.Aliases)")
            $lines.Add("- **Notes:** $($item.Notes)")
            $lines.Add('')
        }

        $content = $lines -join [Environment]::NewLine
    }

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $parentDirectory = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($parentDirectory) -and -not (Test-Path -LiteralPath $parentDirectory)) {
            $null = New-Item -ItemType Directory -Path $parentDirectory -Force
        }

        Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
    }

    return $content
}

function Get-NaturalLanguageRegexTestSlug {
    <#
.SYNOPSIS
        Builds a filesystem-safe slug from a regex description.

    .PARAMETER Description
        Natural language description used to name generated tests.

    .OUTPUTS
        System.String

    .EXAMPLE
.DESCRIPTION
    Builds a filesystem-safe slug from a regex description.
    .PARAMETER Description
    Natural language description used to name generated tests.
    .OUTPUTS
    System.String
    .EXAMPLE
        Get-NaturalLanguageRegexTestSlug -Description 'One or More Digits'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Description
    )

    $slug = ($Description.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return 'regex-pattern'
    }

    return $slug
}

function New-NaturalLanguageRegexSession {
    <#
    .SYNOPSIS
        Creates a serializable natural language regex builder session object.

    .DESCRIPTION
        Captures description, pattern, sample inputs, and builder metadata for
        later export or resume workflows.

    .PARAMETER Description
        Natural language description for the pattern.

    .PARAMETER Pattern
        Generated or edited regex pattern.

    .PARAMETER Segments
        Optional ordered phrase segments used to build the description.

    .PARAMETER Alternation
        True when the description represents an either/or pattern.

    .PARAMETER Anchored
        True when the pattern should be fully anchored.

    .PARAMETER IgnoreCase
        True when case-insensitive matching is enabled.

    .PARAMETER SampleMatch
        Strings that should match the pattern.

    .PARAMETER SampleNoMatch
        Strings that should not match the pattern.

    .PARAMETER Notes
        Optional free-form notes for the session.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        New-NaturalLanguageRegexSession -Description 'digits' -Pattern '\d+'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [string[]]$Segments = @(),

        [bool]$Alternation = $false,

        [bool]$Anchored = $false,

        [bool]$IgnoreCase = $false,

        [string[]]$SampleMatch = @(),

        [string[]]$SampleNoMatch = @(),

        [string]$Notes = ''
    )

    [PSCustomObject]@{
        Version        = '1.0'
        SavedAt        = (Get-Date).ToString('o')
        Description    = $Description
        Pattern        = $Pattern
        Segments       = $Segments
        Alternation    = $Alternation
        Anchored       = $Anchored
        IgnoreCase     = $IgnoreCase
        SampleMatch    = $SampleMatch
        SampleNoMatch  = $SampleNoMatch
        Notes          = $Notes
    }
}

function Export-NaturalLanguageRegexSession {
    <#
.SYNOPSIS
        Saves a natural language regex session to a JSON file.

    .PARAMETER Session
        Session object from New-NaturalLanguageRegexSession or Import-NaturalLanguageRegexSession.

    .PARAMETER Path
        Destination JSON file path.

    .OUTPUTS
        PSCustomObject with Path and Session members.

    .EXAMPLE
.DESCRIPTION
    Saves a natural language regex session to a JSON file.
    .PARAMETER Session
    Session object from New-NaturalLanguageRegexSession or Import-NaturalLanguageRegexSession.
    .PARAMETER Path
    Destination JSON file path.
    .OUTPUTS
    PSCustomObject with Path and Session members.
    .EXAMPLE
        $session | Export-NaturalLanguageRegexSession -Path './my-regex.json'
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        $Session,

        [Parameter(Mandatory)]
        [string]$Path
    )

    process {
        $sessionObject = if ($Session -is [hashtable]) {
            [PSCustomObject]$Session
        }
        else {
            $Session
        }

        if (-not $sessionObject.PSObject.Properties.Name -contains 'SavedAt') {
            $sessionObject | Add-Member -NotePropertyName 'SavedAt' -NotePropertyValue (Get-Date).ToString('o') -Force
        }
        else {
            $sessionObject.SavedAt = (Get-Date).ToString('o')
        }

        if (-not $sessionObject.PSObject.Properties.Name -contains 'Version') {
            $sessionObject | Add-Member -NotePropertyName 'Version' -NotePropertyValue '1.0' -Force
        }

        $parentDirectory = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($parentDirectory) -and -not (Test-Path -LiteralPath $parentDirectory)) {
            $null = New-Item -ItemType Directory -Path $parentDirectory -Force
        }

        $json = $sessionObject | ConvertTo-Json -Depth 6
        Set-Content -LiteralPath $Path -Value $json -Encoding UTF8

        [PSCustomObject]@{
            Path    = (Resolve-Path -LiteralPath $Path).Path
            Session = $sessionObject
        }
    }
}

function Import-NaturalLanguageRegexSession {
    <#
.SYNOPSIS
        Loads a natural language regex session from a JSON file.

    .PARAMETER Path
        JSON session file to import.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
.DESCRIPTION
    Loads a natural language regex session from a JSON file.
    .PARAMETER Path
    JSON session file to import.
    .OUTPUTS
    PSCustomObject
    .EXAMPLE
        Import-NaturalLanguageRegexSession -Path './my-regex.json'
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Regex session file not found: $Path"
    }

    $session = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($session.Description) -or [string]::IsNullOrWhiteSpace($session.Pattern)) {
        throw 'Regex session file is missing required Description or Pattern fields.'
    }

    return [PSCustomObject]@{
        Version       = if ($session.Version) { $session.Version } else { '1.0' }
        SavedAt       = $session.SavedAt
        Description   = [string]$session.Description
        Pattern       = [string]$session.Pattern
        Segments      = @($session.Segments)
        Alternation   = [bool]$session.Alternation
        Anchored      = [bool]$session.Anchored
        IgnoreCase    = [bool]$session.IgnoreCase
        SampleMatch   = @($session.SampleMatch)
        SampleNoMatch = @($session.SampleNoMatch)
        Notes         = [string]$session.Notes
        Path          = (Resolve-Path -LiteralPath $Path).Path
    }
}

function Compare-NaturalLanguageRegexDescriptions {
    <#
    .SYNOPSIS
        Compares two natural language regex descriptions.

    .DESCRIPTION
        Computes token overlap, similarity, and optional generated pattern equivalence.

    .PARAMETER Left
        First description to compare.

    .PARAMETER Right
        Second description to compare.

    .PARAMETER IncludePatterns
        Also converts both descriptions to patterns and compares them.

    .PARAMETER Anchored
        Uses anchored conversion when -IncludePatterns is specified.

    .PARAMETER IgnoreCase
        Uses ignore-case conversion when -IncludePatterns is specified.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Compare-NaturalLanguageRegexDescriptions -Left 'digits' -Right 'numbers' -IncludePatterns
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Left,

        [Parameter(Mandatory)]
        [string]$Right,

        [switch]$IncludePatterns,

        [switch]$Anchored,

        [switch]$IgnoreCase
    )

    $leftNormalized = Normalize-NaturalLanguageRegexDescription -Text $Left
    $rightNormalized = Normalize-NaturalLanguageRegexDescription -Text $Right
    $leftTokens = @($leftNormalized -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $rightTokens = @($rightNormalized -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $sharedTokens = @($leftTokens | Where-Object { $_ -in $rightTokens })
    $leftOnlyTokens = @($leftTokens | Where-Object { $_ -notin $rightTokens })
    $rightOnlyTokens = @($rightTokens | Where-Object { $_ -notin $leftTokens })
    $similarity = Measure-NaturalLanguageRegexSimilarity -Left $Left -Right $Right

    $diffLines = [System.Collections.Generic.List[string]]::new()
    $diffLines.Add("Left:  $Left")
    $diffLines.Add("Right: $Right")
    $diffLines.Add("Similarity: $([Math]::Round($similarity, 4))")
    $diffLines.Add('Shared: ' + ($(if ($sharedTokens.Count -gt 0) { $sharedTokens -join ', ' } else { '(none)' })))
    $diffLines.Add('Only left: ' + ($(if ($leftOnlyTokens.Count -gt 0) { $leftOnlyTokens -join ', ' } else { '(none)' })))
    $diffLines.Add('Only right: ' + ($(if ($rightOnlyTokens.Count -gt 0) { $rightOnlyTokens -join ', ' } else { '(none)' })))

    $result = [PSCustomObject]@{
        Left            = $Left
        Right           = $Right
        Similarity      = $similarity
        SharedTokens    = $sharedTokens
        LeftOnlyTokens  = $leftOnlyTokens
        RightOnlyTokens = $rightOnlyTokens
        DiffText        = ($diffLines -join [Environment]::NewLine)
    }

    if ($IncludePatterns) {
        $leftConversion = ConvertTo-RegexFromNaturalLanguage -Description $Left -Anchored:$Anchored -IgnoreCase:$IgnoreCase
        $rightConversion = ConvertTo-RegexFromNaturalLanguage -Description $Right -Anchored:$Anchored -IgnoreCase:$IgnoreCase
        $result | Add-Member -NotePropertyName 'LeftPattern' -NotePropertyValue $leftConversion.Pattern -Force
        $result | Add-Member -NotePropertyName 'RightPattern' -NotePropertyValue $rightConversion.Pattern -Force
        $result | Add-Member -NotePropertyName 'PatternMatches' -NotePropertyValue ($leftConversion.Pattern -eq $rightConversion.Pattern) -Force
        $diffLines.Add("Left pattern:  $($leftConversion.Pattern)")
        $diffLines.Add("Right pattern: $($rightConversion.Pattern)")
        $diffLines.Add("Patterns match: $($leftConversion.Pattern -eq $rightConversion.Pattern)")
        $result.DiffText = ($diffLines -join [Environment]::NewLine)
    }

    return $result
}

function New-NaturalLanguageRegexPesterStub {
    <#
    .SYNOPSIS
        Generates a Pester test stub for a natural language regex description.

    .DESCRIPTION
        Converts the description to a pattern when -Pattern is omitted and emits a
        Describe/It block with optional sample match and no-match cases.

    .PARAMETER Description
        Natural language description under test.

    .PARAMETER Pattern
        Optional explicit regex pattern to test.

    .PARAMETER SampleMatch
        Strings expected to match.

    .PARAMETER SampleNoMatch
        Strings expected not to match.

    .PARAMETER Anchored
        Converts the description with anchors when generating the pattern.

    .PARAMETER IgnoreCase
        Uses case-insensitive matching in the generated test.

    .PARAMETER TestName
        Optional override for the generated Describe slug.

    .PARAMETER Path
        Optional file path to write the generated Pester script.

    .OUTPUTS
        System.String

    .EXAMPLE
        New-NaturalLanguageRegexPesterStub -Description 'one or more digits' -SampleMatch '42'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [string]$Pattern,

        [string[]]$SampleMatch = @(),

        [string[]]$SampleNoMatch = @(),

        [switch]$Anchored,

        [switch]$IgnoreCase,

        [string]$TestName,

        [string]$Path
    )

    $conversion = if ([string]::IsNullOrWhiteSpace($Pattern)) {
        ConvertTo-RegexFromNaturalLanguage -Description $Description -Anchored:$Anchored -IgnoreCase:$IgnoreCase
    }
    else {
        [PSCustomObject]@{
            Pattern    = $Pattern
            IgnoreCase = [bool]$IgnoreCase
        }
    }

    $resolvedPattern = $conversion.Pattern
    $slug = if ([string]::IsNullOrWhiteSpace($TestName)) {
        Get-NaturalLanguageRegexTestSlug -Description $Description
    }
    else {
        Get-NaturalLanguageRegexTestSlug -Description $TestName
    }

    $escapedPattern = $resolvedPattern.Replace("'", "''")
    $matchSamples = @(
        @($SampleMatch) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { "'$($_.Replace("'", "''"))'" }
    )
    $noMatchSamples = @(
        @($SampleNoMatch) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { "'$($_.Replace("'", "''"))'" }
    )
    $escapedDescription = $Description.Replace("'", "''")

    $regexOptions = if ($conversion.IgnoreCase) { '[System.Text.RegularExpressions.RegexOptions]::IgnoreCase' } else { '[System.Text.RegularExpressions.RegexOptions]::None' }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('<#')
    $lines.Add("Generated Pester stub for natural language regex description: $Description")
    $lines.Add('#>')
    $lines.Add('')
    $lines.Add("Describe 'NL regex: $slug' {")
    $lines.Add('    BeforeAll {')
    $lines.Add("        `$script:Pattern = '$escapedPattern'")
    $lines.Add("        `$script:RegexOptions = $regexOptions")
    $lines.Add("        `$script:Regex = [regex]::new(`$script:Pattern, `$script:RegexOptions)")
    $lines.Add('    }')
    $lines.Add('')
    $lines.Add("    It 'Uses the expected pattern for $escapedDescription' {")
    $lines.Add("        `$script:Pattern | Should -Not -BeNullOrEmpty")
    $lines.Add('    }')
    $lines.Add('')

    if ($matchSamples.Count -gt 0) {
        $lines.Add("    It 'Matches expected samples' {")
        $lines.Add("        `$samples = @($($matchSamples -join ', '))")
        $lines.Add('        foreach ($sample in $samples) {')
        $lines.Add('            $script:Regex.IsMatch($sample) | Should -Be $true')
        $lines.Add('        }')
        $lines.Add('    }')
        $lines.Add('')
    }

    if ($noMatchSamples.Count -gt 0) {
        $lines.Add("    It 'Rejects invalid samples' {")
        $lines.Add("        `$samples = @($($noMatchSamples -join ', '))")
        $lines.Add('        foreach ($sample in $samples) {')
        $lines.Add('            $script:Regex.IsMatch($sample) | Should -Be $false')
        $lines.Add('        }')
        $lines.Add('    }')
        $lines.Add('')
    }

    $lines.Add('}')
    $content = $lines -join [Environment]::NewLine

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $parentDirectory = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($parentDirectory) -and -not (Test-Path -LiteralPath $parentDirectory)) {
            $null = New-Item -ItemType Directory -Path $parentDirectory -Force
        }

        Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
    }

    return $content
}

Export-ModuleMember -Function @(
    'New-CompiledRegex',
    'Get-CommonRegexPatterns',
    'Get-NaturalLanguageRegexCatalog',
    'Get-NaturalLanguageRegexCatalogItems',
    'Search-NaturalLanguageRegexCatalog',
    'Resolve-NaturalLanguageRegexCatalogEntry',
    'Resolve-RegexPatternFromAiResponse',
    'Test-NaturalLanguageRegexNeedsAiFallback',
    'Test-NaturalLanguageRegexSamples',
    'ConvertTo-RegexFromNaturalLanguage',
    'ConvertFrom-RegexToNaturalLanguage',
    'Format-NaturalLanguageRegexResult',
    'Normalize-NaturalLanguageRegexDescription',
    'Measure-NaturalLanguageRegexSimilarity',
    'Build-NaturalLanguageRegexDescription',
    'Test-NaturalLanguageRegexRoundTrip',
    'Export-NaturalLanguageRegexCatalogDocument',
    'Get-NaturalLanguageRegexTestSlug',
    'New-NaturalLanguageRegexSession',
    'Export-NaturalLanguageRegexSession',
    'Import-NaturalLanguageRegexSession',
    'Compare-NaturalLanguageRegexDescriptions',
    'New-NaturalLanguageRegexPesterStub'
)

