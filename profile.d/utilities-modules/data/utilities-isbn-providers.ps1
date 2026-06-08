# ===============================================
# Additional ISBN metadata providers
# OpenBD (Japan) and Library of Congress
# ===============================================

function script:Ensure-IsbnProvidersLoaded {
    Ensure-IsbnUtilitiesLoaded
}

function script:ConvertFrom-OpenBdIsbnResponse {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        $Response,

        [Parameter(Mandatory)]
        [pscustomobject]$Normalized
    )

    $summary = $null
    if ($Response.PSObject.Properties['summary'] -and $Response.summary) {
        $summary = $Response.summary
    }

    if (-not $summary) {
        return $null
    }

    $authors = @()
    if ($summary.PSObject.Properties['author'] -and $summary.author) {
        $authors = @(Get-IsbnTextList -Values $summary.author)
    }

    $publishers = @()
    if ($summary.PSObject.Properties['publisher'] -and $summary.publisher) {
        $publishers = @(Get-IsbnTextList -Values $summary.publisher)
    }

    $isbn13 = @()
    if ($summary.PSObject.Properties['isbn'] -and $summary.isbn) {
        foreach ($value in (Get-IsbnTextList -Values $summary.isbn)) {
            $isbnValue = [string]$value
            if ([string]::IsNullOrWhiteSpace($isbnValue)) {
                continue
            }

            $digits = Get-IsbnDigitsFromInput -Isbn $isbnValue
            if ($digits.Length -eq 13) { $isbn13 += $digits }
        }
    }
    if ($isbn13.Count -eq 0 -and $Normalized.Isbn13) { $isbn13 = @($Normalized.Isbn13) }

    $coverUrl = $null
    if ($summary.PSObject.Properties['cover'] -and $summary.cover) {
        $coverUrl = $summary.cover
    }

    [pscustomobject]@{
        Source          = 'OpenBD'
        Title           = if ($summary.PSObject.Properties['title']) { $summary.title } else { $null }
        Subtitle        = if ($summary.PSObject.Properties['subtitle']) { $summary.subtitle } else { $null }
        Authors         = $authors
        Publishers      = $publishers
        PublishDate     = if ($summary.PSObject.Properties['pubdate']) { $summary.pubdate } else { $null }
        NumberOfPages   = if ($summary.PSObject.Properties['pages']) { $summary.pages } else { $null }
        Subjects        = @()
        Isbn10          = if ($Normalized.Isbn10) { @($Normalized.Isbn10) } else { @() }
        Isbn13          = $isbn13
        Doi             = $null
        Url             = if ($summary.PSObject.Properties['title']) { "https://openbd.jp/isbn/$($Normalized.Isbn13)" } else { $null }
        CoverUrl        = $coverUrl
        OpenLibraryKey  = $null
        WorkKey         = $null
        EditionCount    = $null
        Input           = $Normalized.Input
        NormalizedIsbn  = if ($Normalized.Isbn13) { $Normalized.Isbn13 } else { $Normalized.Isbn10 }
    }
}

function script:Invoke-OpenBdIsbnLookup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Normalized,

        [Parameter(Mandatory)]
        [string]$LookupIsbn
    )

    $uri = "https://api.openbd.jp/v1/bd?isbn=$LookupIsbn"
    $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
    if (-not $response) {
        return $null
    }

    $items = @($response)
    if ($items.Count -eq 0 -or -not $items[0]) {
        return $null
    }

    return ConvertFrom-OpenBdIsbnResponse -Response $items[0] -Normalized $Normalized
}

function script:ConvertFrom-LibraryOfCongressIsbnResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        $Result,

        [Parameter(Mandatory)]
        [pscustomobject]$Normalized
    )

    $title = $null
    if ($Result.PSObject.Properties['title'] -and $Result.title) {
        $title = $Result.title
    }
    elseif ($Result.PSObject.Properties['item'] -and $Result.item.PSObject.Properties['title']) {
        $title = $Result.item.title
    }

    $authors = @()
    if ($Result.PSObject.Properties['creator'] -and $Result.creator) {
        $authors = @(Get-IsbnTextList -Values $Result.creator)
    }
    elseif ($Result.PSObject.Properties['item'] -and $Result.item.PSObject.Properties['contributor_names']) {
        $authors = @(Get-IsbnTextList -Values $Result.item.contributor_names)
    }

    $publishDate = $null
    if ($Result.PSObject.Properties['date'] -and $Result.date) {
        $publishDate = $Result.date
    }
    elseif ($Result.PSObject.Properties['item'] -and $Result.item.PSObject.Properties['created_published_date']) {
        $publishDate = $Result.item.created_published_date
    }

    $url = $null
    if ($Result.PSObject.Properties['id'] -and $Result.id) {
        $url = $Result.id
    }
    elseif ($Result.PSObject.Properties['url'] -and $Result.url) {
        $url = $Result.url
    }

    [pscustomobject]@{
        Source          = 'LibraryOfCongress'
        Title           = $title
        Subtitle        = $null
        Authors         = $authors
        Publishers      = @()
        PublishDate     = $publishDate
        NumberOfPages   = $null
        Subjects        = @()
        Isbn10          = if ($Normalized.Isbn10) { @($Normalized.Isbn10) } else { @() }
        Isbn13          = if ($Normalized.Isbn13) { @($Normalized.Isbn13) } else { @() }
        Doi             = $null
        Url             = $url
        CoverUrl        = $null
        OpenLibraryKey  = $null
        WorkKey         = $null
        EditionCount    = $null
        Input           = $Normalized.Input
        NormalizedIsbn  = if ($Normalized.Isbn13) { $Normalized.Isbn13 } else { $Normalized.Isbn10 }
    }
}

function script:Invoke-LibraryOfCongressIsbnLookup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Normalized,

        [Parameter(Mandatory)]
        [string]$LookupIsbn
    )

    $uri = "https://www.loc.gov/search/?q=isbn:$LookupIsbn&fo=json"
    $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
    if (-not $response -or -not $response.PSObject.Properties['results'] -or -not $response.results) {
        return $null
    }

    $results = @($response.results)
    if ($results.Count -eq 0) {
        return $null
    }

    return ConvertFrom-LibraryOfCongressIsbnResult -Result $results[0] -Normalized $Normalized
}
