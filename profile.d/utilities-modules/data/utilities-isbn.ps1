# ===============================================
# ISBN utility functions
# Parsing, validation, conversion, and lookup
# ===============================================

function script:Ensure-IsbnUtilitiesLoaded {
    if (-not $global:UtilitiesInitialized) {
        if (Get-Command Ensure-Utilities -ErrorAction SilentlyContinue) {
            Ensure-Utilities
        }
    }
}

<#
.SYNOPSIS
    Extracts normalized ISBN digits from any supported input format.
.DESCRIPTION
    Strips common prefixes (ISBN, ISBN-10, ISBN-13), separators (hyphens, spaces,
    en/em dashes, dots), and returns uppercase alphanumeric digits only.
.PARAMETER Isbn
    Raw ISBN text from any supported format.
.OUTPUTS
    System.String
.EXAMPLE
    Get-IsbnDigitsFromInput -Isbn 'ISBN-13: 978-0-306-40615-7'
#>
function script:Get-IsbnDigitsFromInput {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Isbn
    )

    $text = $Isbn.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return ''
    }

    $text = $text -replace '(?i)^ISBN[-\s]*(10|13)?[-\s:]*', ''
    $text = $text -replace '[-\s\u2013\u2014.]', ''
    return $text.ToUpperInvariant()
}

<#
.SYNOPSIS
    Validates an ISBN-10 checksum.

.DESCRIPTION
    Expects nine data digits plus a check character (0-9 or X) and verifies the
    modulo-11 ISBN-10 checksum.

.PARAMETER Digits
    Normalized ISBN-10 body without separators.

.OUTPUTS
    System.Boolean

.EXAMPLE
    Test-Isbn10Checksum -Digits '0306406152'
#>
function script:Test-Isbn10Checksum {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9]{9}[0-9X]$')]
        [string]$Digits
    )

    $sum = 0
    for ($i = 0; $i -lt 9; $i++) {
        $sum += ([int][char]$Digits[$i] - [int][char]'0') * (10 - $i)
    }

    $checkChar = $Digits[9]
    $checkValue = if ($checkChar -eq 'X') { 10 } else { [int][char]$checkChar - [int][char]'0' }
    return (($sum + $checkValue) % 11) -eq 0
}

<#
.SYNOPSIS
    Validates an ISBN-13 checksum.

.DESCRIPTION
    Verifies the EAN-13 style weighted checksum used by ISBN-13 identifiers.

.PARAMETER Digits
    Thirteen-digit ISBN-13 string without separators.

.OUTPUTS
    System.Boolean

.EXAMPLE
    Test-Isbn13Checksum -Digits '9780306406157'
#>
function script:Test-Isbn13Checksum {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{13}$')]
        [string]$Digits
    )

    $sum = 0
    for ($i = 0; $i -lt 12; $i++) {
        $digit = [int][char]$Digits[$i] - [int][char]'0'
        $weight = if ($i % 2 -eq 0) { 1 } else { 3 }
        $sum += $digit * $weight
    }

    $expectedCheck = (10 - ($sum % 10)) % 10
    $actualCheck = [int][char]$Digits[12] - [int][char]'0'
    return $expectedCheck -eq $actualCheck
}

<#
    .SYNOPSIS
        Converts a validated ISBN-10 to ISBN-13.

    .DESCRIPTION
        Prefixes the ISBN-10 body with 978 and calculates the ISBN-13 check digit.

.PARAMETER Isbn10
    Normalized ISBN-10 digits including the check character.

.OUTPUTS
    System.String

.EXAMPLE
    ConvertTo-Isbn13FromIsbn10Digits -Isbn10 '0306406152'
#>
function script:ConvertTo-Isbn13FromIsbn10Digits {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9]{9}[0-9X]$')]
        [string]$Isbn10
    )

    $body = "978$($Isbn10.Substring(0, 9))"
    $sum = 0
    for ($i = 0; $i -lt 12; $i++) {
        $digit = [int][char]$body[$i] - [int][char]'0'
        $weight = if ($i % 2 -eq 0) { 1 } else { 3 }
        $sum += $digit * $weight
    }

    $check = (10 - ($sum % 10)) % 10
    return "$body$check"
}

<#
    .SYNOPSIS
        Converts a validated 978-prefixed ISBN-13 to ISBN-10.

    .DESCRIPTION
        Strips the 978 prefix from a valid ISBN-13 and recalculates the ISBN-10 check digit.

.PARAMETER Isbn13
    Thirteen-digit ISBN-13 beginning with 978.

.OUTPUTS
    System.String

.EXAMPLE
    ConvertTo-Isbn10FromIsbn13Digits -Isbn13 '9780306406157'
#>
function script:ConvertTo-Isbn10FromIsbn13Digits {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^978\d{10}$')]
        [string]$Isbn13
    )

    $body = $Isbn13.Substring(3, 9)
    $sum = 0
    for ($i = 0; $i -lt 9; $i++) {
        $sum += ([int][char]$body[$i] - [int][char]'0') * (10 - $i)
    }

    $remainder = $sum % 11
    $checkValue = 11 - $remainder
    $checkChar = switch ($checkValue) {
        10 { 'X' }
        11 { '0' }
        default { $checkValue.ToString() }
    }

    return "$body$checkChar"
}

<#
.SYNOPSIS
    Normalizes and validates an ISBN from any supported format.

.DESCRIPTION
    Accepts ISBN-10, ISBN-13, SBN (9-digit), and common prefixed or separated forms
    such as "ISBN-13: 978-0-306-40615-7" or "0 306 40615 2".

.PARAMETER Isbn
    The ISBN value to normalize.

.PARAMETER Strict
    When set, invalid checksums cause an error instead of returning IsValid = $false.

.OUTPUTS
    PSCustomObject with Input, Digits, Format, Isbn10, Isbn13, IsValid, and IsValidChecksum.

.EXAMPLE
    ConvertTo-IsbnNormalized -Isbn "978-0-306-40615-7"

.EXAMPLE
    ConvertTo-IsbnNormalized -Isbn "ISBN-10: 0-306-40615-2"
#>
function ConvertTo-IsbnNormalized {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn,

        [switch]$Strict
    )

    process {
        Ensure-IsbnUtilitiesLoaded

        $digits = Get-IsbnDigitsFromInput -Isbn $Isbn
        $result = [ordered]@{
            Input           = $Isbn
            Digits          = $digits
            Format          = $null
            Isbn10          = $null
            Isbn13          = $null
            IsValid         = $false
            IsValidChecksum = $false
        }

        if ([string]::IsNullOrWhiteSpace($digits)) {
            if ($Strict) {
                Write-Error 'ISBN value is empty.' -ErrorAction Stop
            }
            return [pscustomobject]$result
        }

        if ($digits -match '[^0-9X]') {
            if ($Strict) {
                Write-Error "ISBN contains invalid characters: $Isbn" -ErrorAction Stop
            }
            return [pscustomobject]$result
        }

        $format = $null
        $isbn10 = $null
        $isbn13 = $null
        $isValidChecksum = $false

        if ($digits.Length -eq 13 -and $digits -match '^\d{13}$') {
            $format = 'ISBN-13'
            $isbn13 = $digits
            $isValidChecksum = Test-Isbn13Checksum -Digits $digits
            if ($isValidChecksum -and $digits.StartsWith('978')) {
                $isbn10 = ConvertTo-Isbn10FromIsbn13Digits -Isbn13 $digits
            }
        }
        elseif ($digits.Length -eq 10 -and $digits -match '^[0-9]{9}[0-9X]$') {
            $format = 'ISBN-10'
            $isbn10 = $digits
            $isValidChecksum = Test-Isbn10Checksum -Digits $digits
            if ($isValidChecksum) {
                $isbn13 = ConvertTo-Isbn13FromIsbn10Digits -Isbn10 $digits
            }
        }
        elseif ($digits.Length -eq 9 -and $digits -match '^\d{9}$') {
            $format = 'SBN'
            $candidate = "0$digits"
            if ($candidate[-1] -match '[0-9]') {
                $isbn10 = $candidate
                $isValidChecksum = Test-Isbn10Checksum -Digits $candidate
                if ($isValidChecksum) {
                    $isbn13 = ConvertTo-Isbn13FromIsbn10Digits -Isbn10 $candidate
                    $format = 'ISBN-10'
                }
            }
        }
        else {
            if ($Strict) {
                Write-Error "Unsupported ISBN length or format: $Isbn" -ErrorAction Stop
            }
            return [pscustomobject]$result
        }

        $result.Format = $format
        $result.Isbn10 = $isbn10
        $result.Isbn13 = $isbn13
        $result.IsValidChecksum = $isValidChecksum
        $result.IsValid = $isValidChecksum -and ($null -ne $isbn10 -or $null -ne $isbn13)

        if ($Strict -and -not $result.IsValid) {
            Write-Error "Invalid ISBN checksum: $Isbn" -ErrorAction Stop
        }

        [pscustomobject]$result
    }
}
Set-AgentModeAlias -Name 'isbn-normalize' -Target 'ConvertTo-IsbnNormalized'

<#
.SYNOPSIS
    Tests whether an ISBN is valid.

.DESCRIPTION
    Returns $true when the input can be parsed and passes ISBN-10 or ISBN-13 checksum validation.

.PARAMETER Isbn
    The ISBN value to validate.

.OUTPUTS
    System.Boolean

.EXAMPLE
    Test-IsbnValid -Isbn "978-0-306-40615-7"
#>
function Test-IsbnValid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn
    )

    process {
        Ensure-IsbnUtilitiesLoaded
        $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn
        return [bool]$normalized.IsValid
    }
}
Set-AgentModeAlias -Name 'isbn-validate' -Target 'Test-IsbnValid'

<#
.SYNOPSIS
    Formats a normalized ISBN with standard hyphen groups.

.DESCRIPTION
    Formats ISBN-10 as 1-3-5-1 groups and ISBN-13 as 3-1-3-5-1 groups when possible.

.PARAMETER Isbn
    The ISBN value to format.

.PARAMETER Format
    Target format: Auto, ISBN-10, or ISBN-13.

.PARAMETER Hyphenation
    Hyphenation style: Standard uses fixed groups; Registrant uses ISBN agency registrant rules.

.OUTPUTS
    System.String

.EXAMPLE
    Format-Isbn -Isbn "9780306406157"

.EXAMPLE
    Format-Isbn -Isbn "9780201367860" -Hyphenation Registrant
#>
function Format-Isbn {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn,

        [ValidateSet('Auto', 'ISBN-10', 'ISBN-13')]
        [string]$Format = 'Auto',

        [ValidateSet('Standard', 'Registrant')]
        [string]$Hyphenation = 'Standard'
    )

    process {
        Ensure-IsbnUtilitiesLoaded

        $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
        $target = switch ($Format) {
            'ISBN-10' { $normalized.Isbn10 }
            'ISBN-13' { $normalized.Isbn13 }
            default {
                if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
            }
        }

        if ($Hyphenation -eq 'Registrant') {
            $registrantFormatted = Format-IsbnRegistrantHyphenated -Digits $target
            if ($registrantFormatted) {
                return $registrantFormatted
            }
        }

        if ($target.Length -eq 13) {
            return "$($target.Substring(0, 3))-$($target.Substring(3, 1))-$($target.Substring(4, 3))-$($target.Substring(7, 5))-$($target.Substring(12, 1))"
        }

        if ($target.Length -eq 10) {
            return "$($target.Substring(0, 1))-$($target.Substring(1, 3))-$($target.Substring(4, 5))-$($target.Substring(9, 1))"
        }

        return $target
    }
}
Set-AgentModeAlias -Name 'isbn-format' -Target 'Format-Isbn'

function script:ConvertFrom-OpenLibraryIsbnResponse {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        $Response,

        [Parameter(Mandatory)]
        [pscustomobject]$Normalized
    )

    $authors = @()
    if ($Response.PSObject.Properties['authors'] -and $Response.authors) {
        $authors = @($Response.authors | ForEach-Object {
                if ($_ -is [string]) { $_ }
                elseif ($_.PSObject.Properties['name'] -and $_.name) { $_.name }
                elseif ($_.PSObject.Properties['key']) { $_.key }
                else { [string]$_ }
            })
    }

    $publishers = @()
    if ($Response.PSObject.Properties['publishers'] -and $Response.publishers) {
        $publishers = @($Response.publishers | ForEach-Object {
                if ($_ -is [string]) { $_ }
                elseif ($_.PSObject.Properties['name'] -and $_.name) { $_.name }
                else { [string]$_ }
            })
    }

    $subjects = @()
    if ($Response.PSObject.Properties['subjects'] -and $Response.subjects) {
        $subjects = @($Response.subjects | ForEach-Object {
                if ($_ -is [string]) { $_ }
                elseif ($_.PSObject.Properties['name'] -and $_.name) { $_.name }
                else { [string]$_ }
            })
    }

    $isbn10 = @()
    $isbn13 = @()
    if ($Response.PSObject.Properties['identifiers'] -and $Response.identifiers) {
        if ($Response.identifiers.PSObject.Properties['isbn_10'] -and $Response.identifiers.isbn_10) {
            $isbn10 = @($Response.identifiers.isbn_10)
        }
        if ($Response.identifiers.PSObject.Properties['isbn_13'] -and $Response.identifiers.isbn_13) {
            $isbn13 = @($Response.identifiers.isbn_13)
        }
    }
    if ($isbn10.Count -eq 0 -and $Response.PSObject.Properties['isbn_10'] -and $Response.isbn_10) {
        $isbn10 = @($Response.isbn_10)
    }
    if ($isbn13.Count -eq 0 -and $Response.PSObject.Properties['isbn_13'] -and $Response.isbn_13) {
        $isbn13 = @($Response.isbn_13)
    }
    if ($isbn10.Count -eq 0 -and $Normalized.Isbn10) { $isbn10 = @($Normalized.Isbn10) }
    if ($isbn13.Count -eq 0 -and $Normalized.Isbn13) { $isbn13 = @($Normalized.Isbn13) }

    $coverUrl = $null
    if ($Response.PSObject.Properties['cover'] -and $Response.cover) {
        if ($Response.cover.PSObject.Properties['large'] -and $Response.cover.large) {
            $coverUrl = $Response.cover.large
        }
        elseif ($Response.cover.PSObject.Properties['medium'] -and $Response.cover.medium) {
            $coverUrl = $Response.cover.medium
        }
    }
    elseif ($Response.PSObject.Properties['covers'] -and $Response.covers -and @($Response.covers).Count -gt 0) {
        $coverUrl = "https://covers.openlibrary.org/b/id/$($Response.covers[0])-L.jpg"
    }

    $url = $null
    $openLibraryKey = $null
    if ($Response.PSObject.Properties['url'] -and $Response.url) {
        $url = $Response.url
        if ($Response.url -match 'openlibrary\.org(/books/[^/?#]+)') {
            $openLibraryKey = $Matches[1]
        }
    }
    if (-not $openLibraryKey -and $Response.PSObject.Properties['key'] -and $Response.key) {
        $openLibraryKey = $Response.key
        if (-not $url) {
            $url = "https://openlibrary.org$($Response.key)"
        }
    }

    $doi = $null
    if ($Response.PSObject.Properties['identifiers'] -and $Response.identifiers) {
        $doi = Get-IsbnDoiFromIdentifiers -Identifiers $Response.identifiers
    }

    [pscustomobject]@{
        Source          = 'OpenLibrary'
        Title           = if ($Response.PSObject.Properties['title']) { $Response.title } else { $null }
        Subtitle        = if ($Response.PSObject.Properties['subtitle']) { $Response.subtitle } else { $null }
        Authors         = $authors
        Publishers      = $publishers
        PublishDate     = if ($Response.PSObject.Properties['publish_date']) { $Response.publish_date } else { $null }
        NumberOfPages   = if ($Response.PSObject.Properties['number_of_pages']) { $Response.number_of_pages } else { $null }
        Subjects        = $subjects
        Isbn10          = $isbn10
        Isbn13          = $isbn13
        Doi             = $doi
        Url             = $url
        CoverUrl        = $coverUrl
        OpenLibraryKey  = $openLibraryKey
        WorkKey         = $null
        EditionCount    = $null
        Input           = $Normalized.Input
        NormalizedIsbn  = if ($Normalized.Isbn13) { $Normalized.Isbn13 } else { $Normalized.Isbn10 }
    }
}

function script:ConvertFrom-GoogleBooksIsbnResponse {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        $Volume,

        [Parameter(Mandatory)]
        [pscustomobject]$Normalized
    )

    $info = $Volume.volumeInfo
    $authors = if ($info.PSObject.Properties['authors'] -and $info.authors) { @($info.authors) } else { @() }
    $publishers = if ($info.PSObject.Properties['publisher'] -and $info.publisher) { @($info.publisher) } else { @() }
    $subjects = if ($info.PSObject.Properties['categories'] -and $info.categories) { @($info.categories) } else { @() }
    $coverUrl = $null
    if ($info.PSObject.Properties['imageLinks'] -and $info.imageLinks -and $info.imageLinks.PSObject.Properties['thumbnail']) {
        $coverUrl = $info.imageLinks.thumbnail
    }

    $isbn10 = @()
    $isbn13 = @()
    if ($info.PSObject.Properties['industryIdentifiers'] -and $info.industryIdentifiers) {
        foreach ($identifier in $info.industryIdentifiers) {
            if ($identifier.type -eq 'ISBN_10') { $isbn10 += $identifier.identifier }
            if ($identifier.type -eq 'ISBN_13') { $isbn13 += $identifier.identifier }
        }
    }

    if ($isbn10.Count -eq 0 -and $Normalized.Isbn10) { $isbn10 = @($Normalized.Isbn10) }
    if ($isbn13.Count -eq 0 -and $Normalized.Isbn13) { $isbn13 = @($Normalized.Isbn13) }

    $doi = $null
    if ($info.PSObject.Properties['industryIdentifiers'] -and $info.industryIdentifiers) {
        $doi = Get-IsbnDoiFromIdentifiers -Identifiers $info.industryIdentifiers
    }

    [pscustomobject]@{
        Source          = 'GoogleBooks'
        Title           = if ($info.PSObject.Properties['title']) { $info.title } else { $null }
        Subtitle        = if ($info.PSObject.Properties['subtitle']) { $info.subtitle } else { $null }
        Authors         = $authors
        Publishers      = $publishers
        PublishDate     = if ($info.PSObject.Properties['publishedDate']) { $info.publishedDate } else { $null }
        NumberOfPages   = if ($info.PSObject.Properties['pageCount']) { $info.pageCount } else { $null }
        Subjects        = $subjects
        Isbn10          = $isbn10
        Isbn13          = $isbn13
        Doi             = $doi
        Url             = if ($info.PSObject.Properties['infoLink']) { $info.infoLink } else { $null }
        CoverUrl        = $coverUrl
        OpenLibraryKey  = $null
        WorkKey         = $null
        EditionCount    = $null
        Input           = $Normalized.Input
        NormalizedIsbn  = if ($Normalized.Isbn13) { $Normalized.Isbn13 } else { $Normalized.Isbn10 }
    }
}

function script:Get-IsbnDoiFromIdentifiers {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        $Identifiers
    )

    if ($null -eq $Identifiers) {
        return $null
    }

    if ($Identifiers -is [string] -and $Identifiers -match '(?i)^10\.\d{4,9}/\S+$') {
        return $Identifiers
    }

    if ($Identifiers.PSObject.Properties['doi'] -and $Identifiers.doi) {
        $doi = [string]$Identifiers.doi
        if ($doi -match '(?i)^10\.') { return $doi }
    }

    if ($Identifiers -is [System.Collections.IEnumerable] -and $Identifiers -isnot [string]) {
        foreach ($identifier in $Identifiers) {
            if ($identifier.PSObject.Properties['identifier'] -and $identifier.identifier) {
                $value = [string]$identifier.identifier
                if ($value -match '(?i)^10\.\d{4,9}/\S+$') {
                    return $value
                }
            }
            if ($identifier.PSObject.Properties['type'] -and $identifier.type -match 'DOI') {
                if ($identifier.PSObject.Properties['identifier'] -and $identifier.identifier) {
                    return [string]$identifier.identifier
                }
            }
            if ($identifier -is [string] -and $identifier -match '(?i)^10\.\d{4,9}/\S+$') {
                return $identifier
            }
        }
    }

    return $null
}

function script:Get-IsbnTextList {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter()]
        $Values
    )

    if ($null -eq $Values) {
        return @()
    }

    $normalizedValues = if ($Values -is [string]) {
        ,[string]$Values
    }
    else {
        @($Values)
    }

    foreach ($value in $normalizedValues) {
        if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
            Write-Output ([string]$value)
        }
    }
}

function script:Get-IsbnCacheDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$EnsureExists
    )

    $cacheDir = if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ISBN_CACHE_DIR)) {
        $env:PS_PROFILE_ISBN_CACHE_DIR
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:XDG_CACHE_HOME)) {
        Join-Path $env:XDG_CACHE_HOME 'ps-profile' 'isbn'
    }
    else {
        Join-Path $HOME '.cache' 'ps-profile' 'isbn'
    }

    if ($EnsureExists -and -not (Test-Path -LiteralPath $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }

    return $cacheDir
}

function script:Get-IsbnCacheFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$LookupIsbn,

        [Parameter(Mandatory)]
        [string]$Provider
    )

    $providerKey = ($Provider.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    $fileName = "$LookupIsbn-$providerKey.json"
    return Join-Path (Get-IsbnCacheDirectory -EnsureExists) $fileName
}

function script:Get-IsbnCacheMaxAgeDays {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $defaultDays = 30
    if ([string]::IsNullOrWhiteSpace($env:PS_PROFILE_ISBN_CACHE_DAYS)) {
        return $defaultDays
    }

    if ([int]::TryParse($env:PS_PROFILE_ISBN_CACHE_DAYS, [ref]$null)) {
        $parsed = [int]$env:PS_PROFILE_ISBN_CACHE_DAYS
        if ($parsed -ge 0) {
            return $parsed
        }
    }

    return $defaultDays
}

function script:Get-IsbnCachedBook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LookupIsbn,

        [Parameter(Mandatory)]
        [string]$Provider,

        [switch]$Refresh
    )

    if ($Refresh) {
        return $null
    }

    $cachePath = Get-IsbnCacheFilePath -LookupIsbn $LookupIsbn -Provider $Provider
    if (-not (Test-Path -LiteralPath $cachePath)) {
        return $null
    }

    try {
        $entry = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
        if (-not $entry -or -not $entry.Book) {
            return $null
        }

        $maxAgeDays = Get-IsbnCacheMaxAgeDays
        if ($maxAgeDays -gt 0 -and $entry.CachedAt) {
            $cachedAt = [datetime]$entry.CachedAt
            if ((Get-Date) - $cachedAt -gt [TimeSpan]::FromDays($maxAgeDays)) {
                return $null
            }
        }

        return [pscustomobject]$entry.Book
    }
    catch {
        return $null
    }
}

function script:Set-IsbnCachedBook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LookupIsbn,

        [Parameter(Mandatory)]
        [string]$Provider,

        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $cachePath = Get-IsbnCacheFilePath -LookupIsbn $LookupIsbn -Provider $Provider
    $entry = [ordered]@{
        CachedAt = (Get-Date).ToString('o')
        Provider = $Provider
        Book     = $Book
    }

    $json = $entry | ConvertTo-Json -Depth 8 -Compress:$false
    Set-Content -LiteralPath $cachePath -Value $json -Encoding UTF8
}

<#
.SYNOPSIS
    Clears cached ISBN lookup results.

.DESCRIPTION
    Removes cached provider responses under the profile ISBN cache directory.

.PARAMETER LookupIsbn
    Optional ISBN to clear. When omitted, clears the entire ISBN cache directory.

.PARAMETER Provider
    Provider scope for a single ISBN cache entry. Defaults to Auto.

.EXAMPLE
    Clear-IsbnCache -Isbn 'value' -Provider 'value'
.EXAMPLE
    Clear-IsbnCache -LookupIsbn '9780306406157'
#>
function Clear-IsbnCache {
    [CmdletBinding()]
    param(
        [string]$Isbn,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks')]
        [string]$Provider = 'Auto'
    )

    Ensure-IsbnUtilitiesLoaded

    if ($Isbn) {
        $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
        $lookupKey = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
        $cachePath = Get-IsbnCacheFilePath -LookupIsbn $lookupKey -Provider $Provider
        if (Test-Path -LiteralPath $cachePath) {
            Remove-Item -LiteralPath $cachePath -Force
        }
        return
    }

    $cacheDir = Get-IsbnCacheDirectory
    if (Test-Path -LiteralPath $cacheDir) {
        Get-ChildItem -LiteralPath $cacheDir -Filter '*.json' -File -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'isbn-cache-clear' -Target 'Clear-IsbnCache'

function script:Get-IsbnMetadataScore {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $score = 0
    if (-not [string]::IsNullOrWhiteSpace($Book.Title)) { $score += 2 }
    if (@(Get-IsbnTextList -Values $Book.Authors).Count -gt 0) { $score += 2 }
    if (@(Get-IsbnTextList -Values $Book.Publishers).Count -gt 0) { $score += 1 }
    if (-not [string]::IsNullOrWhiteSpace($Book.PublishDate)) { $score += 1 }
    if ($Book.NumberOfPages) { $score += 1 }
    if (-not [string]::IsNullOrWhiteSpace($Book.CoverUrl)) { $score += 1 }
    if (@(Get-IsbnTextList -Values $Book.Subjects).Count -gt 0) { $score += 1 }
    if (-not [string]::IsNullOrWhiteSpace($Book.Doi)) { $score += 1 }
    return $score
}

function script:Select-BestIsbnBookCandidate {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [AllowNull()]
        [pscustomobject[]]$Candidates
    )

    $candidateList = @($Candidates)
    if ($candidateList.Count -eq 0) {
        return $null
    }

    return ($candidateList | Sort-Object { Get-IsbnMetadataScore -Book $_ } -Descending | Select-Object -First 1)
}

function script:Invoke-OpenLibraryIsbnLookup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Normalized,

        [Parameter(Mandatory)]
        [string]$LookupIsbn
    )

    $dataUri = "https://openlibrary.org/api/books?bibkeys=ISBN:$LookupIsbn&format=json&jscmd=data"
    $dataResponse = Invoke-RestMethod -Uri $dataUri -Method Get -ErrorAction Stop
    $dataKey = "ISBN:$LookupIsbn"
    if ($dataResponse.PSObject.Properties[$dataKey] -and $dataResponse.$dataKey) {
        return ConvertFrom-OpenLibraryIsbnResponse -Response $dataResponse.$dataKey -Normalized $Normalized
    }

    $editionUri = "https://openlibrary.org/isbn/$LookupIsbn.json"
    $editionResponse = Invoke-RestMethod -Uri $editionUri -Method Get -ErrorAction Stop
    if ($editionResponse) {
        return ConvertFrom-OpenLibraryIsbnResponse -Response $editionResponse -Normalized $Normalized
    }

    return $null
}

function script:Invoke-GoogleBooksIsbnLookup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Normalized,

        [Parameter(Mandatory)]
        [string]$LookupIsbn
    )

    $uri = "https://www.googleapis.com/books/v1/volumes?q=isbn:$LookupIsbn"
    $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
    $totalItems = if ($response.PSObject.Properties['totalItems']) { [int]$response.totalItems } else { 0 }
    if ($totalItems -gt 0 -and $response.PSObject.Properties['items'] -and $response.items -and $response.items.Count -gt 0) {
        return ConvertFrom-GoogleBooksIsbnResponse -Volume $response.items[0] -Normalized $Normalized
    }

    return $null
}

function script:Invoke-IsbnProviderLookup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Normalized,

        [Parameter(Mandatory)]
        [string]$LookupIsbn,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto'
    )

    Ensure-IsbnProvidersLoaded

    $candidates = [System.Collections.Generic.List[pscustomobject]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $tryOpenLibrary = $Provider -in @('Auto', 'OpenLibrary')
    $tryGoogleBooks = $Provider -in @('Auto', 'GoogleBooks')
    $tryOpenBD = $Provider -in @('Auto', 'OpenBD')
    $tryLibraryOfCongress = $Provider -in @('Auto', 'LibraryOfCongress')

    if ($tryOpenLibrary) {
        try {
            $book = Invoke-OpenLibraryIsbnLookup -Normalized $Normalized -LookupIsbn $LookupIsbn
            if ($book) { $candidates.Add($book) }
        }
        catch {
            $errors.Add("Open Library lookup failed: $($_.Exception.Message)")
            if ($Provider -eq 'OpenLibrary') {
                Write-Error $errors[-1] -ErrorAction Stop
            }
        }
    }

    if ($tryGoogleBooks) {
        try {
            $book = Invoke-GoogleBooksIsbnLookup -Normalized $Normalized -LookupIsbn $LookupIsbn
            if ($book) { $candidates.Add($book) }
        }
        catch {
            $errors.Add("Google Books lookup failed: $($_.Exception.Message)")
            if ($Provider -eq 'GoogleBooks') {
                Write-Error $errors[-1] -ErrorAction Stop
            }
        }
    }

    if ($tryOpenBD -and ($Provider -eq 'OpenBD' -or $LookupIsbn -match '^9784')) {
        try {
            $book = Invoke-OpenBdIsbnLookup -Normalized $Normalized -LookupIsbn $LookupIsbn
            if ($book) { $candidates.Add($book) }
        }
        catch {
            $errors.Add("OpenBD lookup failed: $($_.Exception.Message)")
            if ($Provider -eq 'OpenBD') {
                Write-Error $errors[-1] -ErrorAction Stop
            }
        }
    }

    $best = Select-BestIsbnBookCandidate -Candidates $candidates.ToArray()
    $needsFallback = $Provider -eq 'Auto' -and (-not $best -or (Get-IsbnMetadataScore -Book $best) -lt 4)

    if ($needsFallback -and $tryLibraryOfCongress) {
        try {
            $book = Invoke-LibraryOfCongressIsbnLookup -Normalized $Normalized -LookupIsbn $LookupIsbn
            if ($book) { $candidates.Add($book) }
        }
        catch {
            $errors.Add("Library of Congress lookup failed: $($_.Exception.Message)")
        }
    }

    $book = Select-BestIsbnBookCandidate -Candidates $candidates.ToArray()
    if (-not $book) {
        $message = "No book found for ISBN $LookupIsbn."
        if ($errors.Count -gt 0) {
            $message = "$message $($errors -join ' ')"
        }
        Write-Error $message -ErrorAction Stop
    }

    return $book
}

function script:Wait-IsbnBatchThrottle {
    [CmdletBinding()]
    param()

    $delayMs = 0
    if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ISBN_BATCH_DELAY_MS) -and [int]::TryParse($env:PS_PROFILE_ISBN_BATCH_DELAY_MS, [ref]$delayMs)) {
        if ($delayMs -gt 0) {
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

function script:Get-IsbnBookRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto',

        [switch]$Refresh,

        [switch]$Offline
    )

    $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
    $lookupIsbn = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }

    $cached = Get-IsbnCachedBook -LookupIsbn $lookupIsbn -Provider $Provider -Refresh:$Refresh
    if ($cached) {
        return $cached
    }

    if ($Offline) {
        Write-Error "No cached metadata found for ISBN $lookupIsbn. Run without -Offline or use -Refresh after a successful lookup." -ErrorAction Stop
    }

    $book = Invoke-IsbnProviderLookup -Normalized $normalized -LookupIsbn $lookupIsbn -Provider $Provider
    Set-IsbnCachedBook -LookupIsbn $lookupIsbn -Provider $Provider -Book $book
    return $book
}

function script:ConvertTo-BibTeXEscaped {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    return ($Value -replace '\\', '\\' -replace '{', '\{' -replace '}', '\}')
}

function script:ConvertTo-BibTeXAuthor {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $trimmed = $Name.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return ''
    }

    $parts = $trimmed -split '\s+', 2
    if ($parts.Count -eq 2) {
        return "$($parts[1]), $($parts[0])"
    }

    return $trimmed
}

function script:Get-BibTeXCitationKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $authorPart = 'unknown'
    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    if ($authors.Count -gt 0) {
        $nameParts = $authors[0] -split '\s+'
        $authorPart = ($nameParts[-1] -replace '[^a-zA-Z]', '').ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($authorPart)) {
            $authorPart = 'unknown'
        }
    }

    $year = 'nodate'
    if (-not [string]::IsNullOrWhiteSpace($Book.PublishDate) -and $Book.PublishDate -match '(\d{4})') {
        $year = $Matches[1]
    }

    $titleWord = 'book'
    if (-not [string]::IsNullOrWhiteSpace($Book.Title)) {
        $titleWord = (($Book.Title -split '\s+')[0] -replace '[^a-zA-Z]', '').ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($titleWord)) {
            $titleWord = 'book'
        }
    }

    return "$authorPart$year$titleWord"
}

function script:Format-IsbnBibTeX {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $key = Get-BibTeXCitationKey -Book $Book
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("@book{$key,")

    if (-not [string]::IsNullOrWhiteSpace($Book.Title)) {
        $title = ConvertTo-BibTeXEscaped -Value $Book.Title
        if (-not [string]::IsNullOrWhiteSpace($Book.Subtitle)) {
            $title = "${title}: $(ConvertTo-BibTeXEscaped -Value $Book.Subtitle)"
        }
        $lines.Add("  title = {$title},")
    }

    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    if ($authors.Count -gt 0) {
        $bibAuthors = ($authors | ForEach-Object { ConvertTo-BibTeXAuthor -Name $_ }) -join ' and '
        $lines.Add("  author = {$(ConvertTo-BibTeXEscaped -Value $bibAuthors)},")
    }

    $publishers = @(Get-IsbnTextList -Values $Book.Publishers)
    if ($publishers.Count -gt 0) {
        $lines.Add("  publisher = {$(ConvertTo-BibTeXEscaped -Value ($publishers -join '; '))},")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.PublishDate) -and $Book.PublishDate -match '(\d{4})') {
        $lines.Add("  year = {$($Matches[1])},")
    }

    $isbn13 = @(Get-IsbnTextList -Values $Book.Isbn13)
    $isbn10 = @(Get-IsbnTextList -Values $Book.Isbn10)
    if ($isbn13.Count -gt 0) {
        $lines.Add("  isbn = {$($isbn13[0])},")
    }
    elseif ($isbn10.Count -gt 0) {
        $lines.Add("  isbn = {$($isbn10[0])},")
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Book.NormalizedIsbn)) {
        $lines.Add("  isbn = {$($Book.NormalizedIsbn)},")
    }

    if ($Book.NumberOfPages) {
        $lines.Add("  pages = {$($Book.NumberOfPages)},")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.Url)) {
        $lines.Add("  url = {$(ConvertTo-BibTeXEscaped -Value $Book.Url)},")
    }

    if ($Book.PSObject.Properties['Doi'] -and -not [string]::IsNullOrWhiteSpace($Book.Doi)) {
        $lines.Add("  doi = {$(ConvertTo-BibTeXEscaped -Value $Book.Doi)},")
    }

    if ($lines.Count -gt 1 -and $lines[$lines.Count - 1].EndsWith(',')) {
        $lines[$lines.Count - 1] = $lines[$lines.Count - 1].TrimEnd(',')
    }

    $lines.Add('}')
    return ($lines -join [Environment]::NewLine)
}

function script:ConvertTo-IsbnTableRow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    $publishers = @(Get-IsbnTextList -Values $Book.Publishers)

    [pscustomobject]@{
        Isbn        = $Book.NormalizedIsbn
        Title       = $Book.Title
        Authors     = ($authors -join ', ')
        Publisher   = ($publishers -join ', ')
        Published   = $Book.PublishDate
        Pages       = $Book.NumberOfPages
        Source      = $Book.Source
        Url         = $Book.Url
        CoverUrl    = $Book.CoverUrl
    }
}

function script:Format-IsbnBookOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book,

        [ValidateSet('Object', 'Text', 'Json', 'BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago', 'Table', 'Csv')]
        [string]$OutputFormat
    )

    switch ($OutputFormat) {
        'Json' { return ($Book | ConvertTo-Json -Depth 6 -Compress:$false) }
        'Text' { return (Format-IsbnLookupText -Book $Book) }
        'BibTeX' { return (Format-IsbnBibTeX -Book $Book) }
        'Ris' { return (Format-IsbnRis -Book $Book) }
        'CslJson' { return (Format-IsbnCslJson -Book $Book) }
        'Apa' { return (Format-IsbnCitation -Book $Book -Style Apa) }
        'Mla' { return (Format-IsbnCitation -Book $Book -Style Mla) }
        'Chicago' { return (Format-IsbnCitation -Book $Book -Style Chicago) }
        'Table' { return (ConvertTo-IsbnTableRow -Book $Book) }
        'Csv' { return (ConvertTo-IsbnTableRow -Book $Book) }
        default { return $Book }
    }
}

function script:Format-IsbnLookupText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Title: $($Book.Title)")

    if (-not [string]::IsNullOrWhiteSpace($Book.Subtitle)) {
        $lines.Add("Subtitle: $($Book.Subtitle)")
    }

    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    if ($authors.Count -gt 0) {
        $lines.Add("Authors: $($authors -join ', ')")
    }

    $publishers = @(Get-IsbnTextList -Values $Book.Publishers)
    if ($publishers.Count -gt 0) {
        $lines.Add("Publisher: $($publishers -join ', ')")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.PublishDate)) {
        $lines.Add("Published: $($Book.PublishDate)")
    }

    if ($Book.NumberOfPages) {
        $lines.Add("Pages: $($Book.NumberOfPages)")
    }

    $isbn13 = @(Get-IsbnTextList -Values $Book.Isbn13)
    if ($isbn13.Count -gt 0) {
        $lines.Add("ISBN-13: $($isbn13 -join ', ')")
    }

    $isbn10 = @(Get-IsbnTextList -Values $Book.Isbn10)
    if ($isbn10.Count -gt 0) {
        $lines.Add("ISBN-10: $($isbn10 -join ', ')")
    }

    $subjects = @(Get-IsbnTextList -Values $Book.Subjects)
    if ($subjects.Count -gt 0) {
        $lines.Add("Subjects: $($subjects -join ', ')")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.Url)) {
        $lines.Add("URL: $($Book.Url)")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.CoverUrl)) {
        $lines.Add("Cover: $($Book.CoverUrl)")
    }

    if ($Book.PSObject.Properties['Doi'] -and -not [string]::IsNullOrWhiteSpace($Book.Doi)) {
        $lines.Add("DOI: $($Book.Doi)")
    }

    $lines.Add("Source: $($Book.Source)")
    return ($lines -join [Environment]::NewLine)
}

<#
.SYNOPSIS
    Looks up book metadata by ISBN.

.DESCRIPTION
    Accepts ISBN-10, ISBN-13, SBN, and common prefixed or separated forms.
    Queries Open Library first, then Google Books as a fallback.
    Results are cached locally unless -Refresh is specified.

.PARAMETER Isbn
    The ISBN to look up. Supports pipeline input for batch lookups.

.PARAMETER Provider
    Data provider: Auto, OpenLibrary, GoogleBooks, OpenBD, or LibraryOfCongress.

.PARAMETER OutputFormat
    Output format: Object, Text, Json, BibTeX, Ris, CslJson, Apa, Mla, Chicago, Table, or Csv.

.PARAMETER Refresh
    Bypass cached lookup results and fetch fresh metadata.

.PARAMETER Offline
    Return cached metadata only and do not query remote providers.

.OUTPUTS
    PSCustomObject, System.String

.EXAMPLE
    Get-IsbnInfo -Isbn "978-0-306-40615-7"

.EXAMPLE
    Get-IsbnInfo -Isbn "ISBN-10: 0-306-40615-2" -OutputFormat BibTeX

.EXAMPLE
    Get-Content isbns.txt | Get-IsbnInfo -OutputFormat Table
#>
function Get-IsbnInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Isbn,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto',

        [ValidateSet('Object', 'Text', 'Json', 'BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago', 'Table', 'Csv')]
        [string]$OutputFormat = 'Text',

        [switch]$Refresh,

        [switch]$Offline
    )

    begin {
        Ensure-IsbnUtilitiesLoaded
        $script:IsbnBatchResults = [System.Collections.Generic.List[object]]::new()
        $script:IsbnBatchTextResults = [System.Collections.Generic.List[string]]::new()
        $script:IsbnBatchOutput = $OutputFormat -in @('Table', 'Csv')
        $script:IsbnBatchTextOutput = $OutputFormat -in @('BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago')
    }

    process {
        if ($script:IsbnBatchOutput -or $script:IsbnBatchTextOutput) {
            Wait-IsbnBatchThrottle
        }

        $book = Get-IsbnBookRecord -Isbn $Isbn -Provider $Provider -Refresh:$Refresh -Offline:$Offline
        $output = Format-IsbnBookOutput -Book $book -OutputFormat $OutputFormat

        if ($script:IsbnBatchOutput) {
            $script:IsbnBatchResults.Add($output)
            return
        }

        if ($script:IsbnBatchTextOutput) {
            $script:IsbnBatchTextResults.Add([string]$output)
            return
        }

        return $output
    }

    end {
        if ($script:IsbnBatchTextOutput -and $script:IsbnBatchTextResults.Count -gt 0) {
            return ($script:IsbnBatchTextResults -join ("$([Environment]::NewLine)$([Environment]::NewLine)")).TrimEnd()
        }

        if (-not $script:IsbnBatchOutput -or $script:IsbnBatchResults.Count -eq 0) {
            return
        }

        if ($OutputFormat -eq 'Csv') {
            return ($script:IsbnBatchResults | ConvertTo-Csv -NoTypeInformation | Out-String).TrimEnd()
        }

        return ,$script:IsbnBatchResults.ToArray()
    }
}
Set-AgentModeAlias -Name 'isbn' -Target 'Get-IsbnInfo'
Set-AgentModeAlias -Name 'isbn-lookup' -Target 'Get-IsbnInfo'

<#
.SYNOPSIS
    Downloads a book cover image for an ISBN.

.DESCRIPTION
    Looks up the ISBN, resolves the cover URL, and saves the image to disk.

.PARAMETER Isbn
    The ISBN to look up.

.PARAMETER OutputPath
    Destination file path. Defaults to ./<isbn>.jpg in the current directory.

.PARAMETER Provider
    Data provider: Auto, OpenLibrary, GoogleBooks, OpenBD, or LibraryOfCongress.

.PARAMETER Refresh
    Bypass cached lookup results when resolving metadata.

.PARAMETER PassThru
    Returns the saved file path.

.OUTPUTS
    System.String. Path to the saved cover image when -PassThru is used.

.EXAMPLE
    Save-IsbnCover -Isbn "978-0-306-40615-7" -OutputPath "./cover.jpg"
#>
function Save-IsbnCover {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Isbn,

        [string]$OutputPath,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto',

        [switch]$Refresh,

        [switch]$PassThru
    )

    process {
        Ensure-IsbnUtilitiesLoaded

        $book = Get-IsbnBookRecord -Isbn $Isbn -Provider $Provider -Refresh:$Refresh
        if ([string]::IsNullOrWhiteSpace($book.CoverUrl)) {
            Write-Error "No cover image available for ISBN $($book.NormalizedIsbn)." -ErrorAction Stop
        }

        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            $extension = '.jpg'
            if ($book.CoverUrl -match '\.(png|gif|webp)(?:\?|$)') {
                $extension = ".$($Matches[1].ToLowerInvariant())"
            }
            $OutputPath = Join-Path (Get-Location).Path "$($book.NormalizedIsbn)$extension"
        }

        $parentDir = Split-Path -Parent $OutputPath
        if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        $null = Invoke-WebRequest -Uri $book.CoverUrl -OutFile $OutputPath -ErrorAction Stop

        if ($PassThru) {
            return $OutputPath
        }

        Write-Output $OutputPath
    }
}
Set-AgentModeAlias -Name 'isbn-cover' -Target 'Save-IsbnCover'
