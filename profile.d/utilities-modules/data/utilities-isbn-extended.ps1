# ===============================================
# Extended ISBN utility functions
# Search, editions, bibliography export, citations, and workflows
# ===============================================

function script:Ensure-IsbnExtendedLoaded {
    Ensure-IsbnUtilitiesLoaded
}

function script:Get-IsbnPublicationYear {
    param([string]$PublishDate)

    if (-not [string]::IsNullOrWhiteSpace($PublishDate) -and $PublishDate -match '(\d{4})') {
        return $Matches[1]
    }

    return $null
}

function script:Get-IsbnPrimaryAuthor {
    param($Book)

    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    if ($authors.Count -gt 0) {
        return $authors[0]
    }

    return $null
}

function script:Get-IsbnAuthorLastName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return ''
    }

    return ($Name.Trim() -split '\s+')[-1]
}

function script:Format-IsbnRis {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('TY  - BOOK')

    if (-not [string]::IsNullOrWhiteSpace($Book.Title)) {
        $lines.Add("TI  - $($Book.Title)")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.Subtitle)) {
        $lines.Add("T2  - $($Book.Subtitle)")
    }

    foreach ($author in (Get-IsbnTextList -Values $Book.Authors)) {
        $lines.Add("AU  - $author")
    }

    foreach ($publisher in (Get-IsbnTextList -Values $Book.Publishers)) {
        $lines.Add("PB  - $publisher")
    }

    $year = Get-IsbnPublicationYear -PublishDate $Book.PublishDate
    if ($year) {
        $lines.Add("PY  - $year")
    }

    if ($Book.NumberOfPages) {
        $lines.Add("SP  - $($Book.NumberOfPages)")
    }

    $isbn13 = @(Get-IsbnTextList -Values $Book.Isbn13)
    $isbn10 = @(Get-IsbnTextList -Values $Book.Isbn10)
    if ($isbn13.Count -gt 0) {
        $lines.Add("SN  - $($isbn13[0])")
    }
    elseif ($isbn10.Count -gt 0) {
        $lines.Add("SN  - $($isbn10[0])")
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Book.NormalizedIsbn)) {
        $lines.Add("SN  - $($Book.NormalizedIsbn)")
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.Url)) {
        $lines.Add("UR  - $($Book.Url)")
    }

    $lines.Add('ER  -')
    return ($lines -join [Environment]::NewLine)
}

function script:Format-IsbnCslJson {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book
    )

    $authors = @(Get-IsbnTextList -Values $Book.Authors | ForEach-Object {
            $parts = $_.Trim() -split '\s+', 2
            if ($parts.Count -eq 2) {
                [ordered]@{ family = $parts[1]; given = $parts[0] }
            }
            else {
                [ordered]@{ literal = $_ }
            }
        })

    $issuedYear = Get-IsbnPublicationYear -PublishDate $Book.PublishDate
    $isbn13 = @(Get-IsbnTextList -Values $Book.Isbn13)
    $isbn10 = @(Get-IsbnTextList -Values $Book.Isbn10)
    $isbn = if ($isbn13.Count -gt 0) { $isbn13[0] } elseif ($isbn10.Count -gt 0) { $isbn10[0] } else { $Book.NormalizedIsbn }

    $item = [ordered]@{
        type       = 'book'
        id         = Get-BibTeXCitationKey -Book $Book
        title      = $Book.Title
        author     = $authors
        issued     = if ($issuedYear) { [ordered]@{ 'date-parts' = @(@([int]$issuedYear)) } } else { $null }
        publisher  = (@(Get-IsbnTextList -Values $Book.Publishers) -join '; ')
        page       = if ($Book.NumberOfPages) { "$($Book.NumberOfPages)" } else { $null }
        ISBN       = $isbn
        URL        = $Book.Url
    }

    if (-not [string]::IsNullOrWhiteSpace($Book.Subtitle)) {
        $item.title = "$($Book.Title): $($Book.Subtitle)"
    }

    return ($item | ConvertTo-Json -Depth 6 -Compress:$false)
}

function script:Format-IsbnCitation {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Book,

        [ValidateSet('Apa', 'Mla', 'Chicago')]
        [string]$Style = 'Apa'
    )

    $authors = @(Get-IsbnTextList -Values $Book.Authors)
    $year = Get-IsbnPublicationYear -PublishDate $Book.PublishDate
    $yearText = if ($year) { $year } else { 'n.d.' }
    $publishers = @(Get-IsbnTextList -Values $Book.Publishers)
    $publisher = if ($publishers.Count -gt 0) { $publishers[0] } else { 'n.p.' }
    $title = if (-not [string]::IsNullOrWhiteSpace($Book.Subtitle)) { "$($Book.Title): $($Book.Subtitle)" } else { $Book.Title }
    $isbn13 = @(Get-IsbnTextList -Values $Book.Isbn13)
    $isbn10 = @(Get-IsbnTextList -Values $Book.Isbn10)
    $isbn = if ($isbn13.Count -gt 0) { $isbn13[0] } elseif ($isbn10.Count -gt 0) { $isbn10[0] } else { $Book.NormalizedIsbn }

    switch ($Style) {
        'Mla' {
            $authorText = if ($authors.Count -gt 0) { $authors -join ', ' } else { 'Unknown' }
            return "$authorText. $title. $publisher, $yearText. ISBN $isbn."
        }
        'Chicago' {
            $authorText = if ($authors.Count -gt 0) { $authors -join ', ' } else { 'Unknown' }
            return "$authorText. $title. $publisher, $yearText. ISBN: $isbn."
        }
        default {
            $apaAuthors = if ($authors.Count -eq 0) {
                'Unknown'
            }
            elseif ($authors.Count -eq 1) {
                $first = ($authors[0] -split '\s+')[0]
                $initial = if ($first.Length -gt 0) { $first.Substring(0, 1) } else { '?' }
                "$(Get-IsbnAuthorLastName -Name $authors[0]), $initial."
            }
            elseif ($authors.Count -eq 2) {
                $firstInitial = (($authors[0] -split '\s+')[0]).Substring(0, 1)
                $secondInitial = (($authors[1] -split '\s+')[0]).Substring(0, 1)
                "$(Get-IsbnAuthorLastName -Name $authors[0]), $firstInitial., & $(Get-IsbnAuthorLastName -Name $authors[1]), $secondInitial."
            }
            else {
                $firstInitial = (($authors[0] -split '\s+')[0]).Substring(0, 1)
                "$(Get-IsbnAuthorLastName -Name $authors[0]), $firstInitial., et al."
            }
            return "$apaAuthors ($yearText). $title. $publisher. ISBN $isbn"
        }
    }
}

function script:ConvertFrom-OpenLibrarySearchDoc {
    param($Doc)

    $authors = @()
    if ($Doc.PSObject.Properties['author_name'] -and $Doc.author_name) {
        $authors = @($Doc.author_name)
    }

    $isbn13 = @()
    $isbn10 = @()
    if ($Doc.PSObject.Properties['isbn'] -and $Doc.isbn) {
        foreach ($value in @($Doc.isbn)) {
            if ($value.Length -eq 13) { $isbn13 += $value }
            elseif ($value.Length -eq 10) { $isbn10 += $value }
        }
    }

    $coverUrl = $null
    if ($Doc.PSObject.Properties['cover_i'] -and $Doc.cover_i) {
        $coverUrl = "https://covers.openlibrary.org/b/id/$($Doc.cover_i)-L.jpg"
    }

    [pscustomobject]@{
        Source         = 'OpenLibrary'
        Title          = if ($Doc.PSObject.Properties['title']) { $Doc.title } else { $null }
        Subtitle       = $null
        Authors        = $authors
        Publishers     = if ($Doc.PSObject.Properties['publisher'] -and $Doc.publisher) { @($Doc.publisher) } else { @() }
        PublishDate    = if ($Doc.PSObject.Properties['first_publish_year']) { "$($Doc.first_publish_year)" } else { $null }
        NumberOfPages  = if ($Doc.PSObject.Properties['number_of_pages_median']) { $Doc.number_of_pages_median } else { $null }
        Subjects       = if ($Doc.PSObject.Properties['subject'] -and $Doc.subject) { @($Doc.subject) } else { @() }
        Isbn10         = $isbn10
        Isbn13         = $isbn13
        Url            = if ($Doc.PSObject.Properties['key']) { "https://openlibrary.org$($Doc.key)" } else { $null }
        CoverUrl       = $coverUrl
        OpenLibraryKey = if ($Doc.PSObject.Properties['key']) { $Doc.key } else { $null }
        WorkKey        = if ($Doc.PSObject.Properties['key'] -and "$($Doc.key)" -like '/works/*') { $Doc.key } else { $null }
        EditionCount   = if ($Doc.PSObject.Properties['edition_count']) { $Doc.edition_count } else { $null }
        Input          = $null
        NormalizedIsbn = if ($isbn13.Count -gt 0) { $isbn13[0] } elseif ($isbn10.Count -gt 0) { $isbn10[0] } else { $null }
    }
}

function script:ConvertFrom-GoogleBooksSearchVolume {
    param($Volume)

    $info = $Volume.volumeInfo
    $authors = if ($info.PSObject.Properties['authors'] -and $info.authors) { @($info.authors) } else { @() }
    $isbn10 = @()
    $isbn13 = @()
    if ($info.PSObject.Properties['industryIdentifiers'] -and $info.industryIdentifiers) {
        foreach ($identifier in $info.industryIdentifiers) {
            if ($identifier.type -eq 'ISBN_10') { $isbn10 += $identifier.identifier }
            if ($identifier.type -eq 'ISBN_13') { $isbn13 += $identifier.identifier }
        }
    }

  [pscustomobject]@{
        Source         = 'GoogleBooks'
        Title          = if ($info.PSObject.Properties['title']) { $info.title } else { $null }
        Subtitle       = if ($info.PSObject.Properties['subtitle']) { $info.subtitle } else { $null }
        Authors        = $authors
        Publishers     = if ($info.PSObject.Properties['publisher'] -and $info.publisher) { @($info.publisher) } else { @() }
        PublishDate    = if ($info.PSObject.Properties['publishedDate']) { $info.publishedDate } else { $null }
        NumberOfPages  = if ($info.PSObject.Properties['pageCount']) { $info.pageCount } else { $null }
        Subjects       = if ($info.PSObject.Properties['categories'] -and $info.categories) { @($info.categories) } else { @() }
        Isbn10         = $isbn10
        Isbn13         = $isbn13
        Url            = if ($info.PSObject.Properties['infoLink']) { $info.infoLink } else { $null }
        CoverUrl       = if ($info.PSObject.Properties['imageLinks'] -and $info.imageLinks.PSObject.Properties['thumbnail']) { $info.imageLinks.thumbnail } else { $null }
        OpenLibraryKey = $null
        WorkKey        = $null
        EditionCount   = $null
        Input          = $null
        NormalizedIsbn = if ($isbn13.Count -gt 0) { $isbn13[0] } elseif ($isbn10.Count -gt 0) { $isbn10[0] } else { $null }
    }
}

function script:ConvertTo-IsbnEditionRow {
    param($Edition)

    $isbn10 = @()
    $isbn13 = @()
    if ($Edition.PSObject.Properties['isbn_10'] -and $Edition.isbn_10) { $isbn10 = @($Edition.isbn_10) }
    if ($Edition.PSObject.Properties['isbn_13'] -and $Edition.isbn_13) { $isbn13 = @($Edition.isbn_13) }

    [pscustomobject]@{
        Title         = if ($Edition.PSObject.Properties['title']) { $Edition.title } else { $null }
        PublishDate   = if ($Edition.PSObject.Properties['publish_date']) { $Edition.publish_date } else { $null }
        Publishers    = if ($Edition.PSObject.Properties['publishers'] -and $Edition.publishers) { @($Edition.publishers) } else { @() }
        NumberOfPages = if ($Edition.PSObject.Properties['number_of_pages']) { $Edition.number_of_pages } else { $null }
        Isbn10        = $isbn10
        Isbn13        = $isbn13
        EditionKey    = if ($Edition.PSObject.Properties['key']) { $Edition.key } else { $null }
        Url           = if ($Edition.PSObject.Properties['key']) { "https://openlibrary.org$($Edition.key)" } else { $null }
    }
}

function script:Get-IsbnLibraryPath {
  if (-not [string]::IsNullOrWhiteSpace($env:PS_PROFILE_ISBN_LIBRARY_PATH)) {
        return $env:PS_PROFILE_ISBN_LIBRARY_PATH
    }

    if (-not [string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
        return Join-Path $env:XDG_DATA_HOME 'ps-profile' 'isbn-library.json'
    }

    return Join-Path $HOME '.local' 'share' 'ps-profile' 'isbn-library.json'
}

function script:Read-IsbnLibrary {
    $path = Get-IsbnLibraryPath
    if (-not (Test-Path -LiteralPath $path)) {
        return @()
    }

    try {
        return @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
    }
    catch {
        return @()
    }
}

<#
.SYNOPSIS
    Searches for books by title and/or author.
#>
function Find-Isbn {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$Title,

        [string]$Author,

        [ValidateRange(1, 50)]
        [int]$Limit = 10,

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks')]
        [string]$Provider = 'Auto',

        [switch]$Pick
    )

    Ensure-IsbnExtendedLoaded

    if ([string]::IsNullOrWhiteSpace($Title) -and [string]::IsNullOrWhiteSpace($Author)) {
        Write-Error 'At least one of -Title or -Author is required.' -ErrorAction Stop
    }

    $results = [System.Collections.Generic.List[pscustomobject]]::new()

    if ($Provider -in @('Auto', 'OpenLibrary')) {
        try {
            $titleParam = if ($Title) { "&title=$([uri]::EscapeDataString($Title))" } else { '' }
            $authorParam = if ($Author) { "&author=$([uri]::EscapeDataString($Author))" } else { '' }
            $uri = "https://openlibrary.org/search.json?limit=$Limit$titleParam$authorParam"
            $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            if ($response.PSObject.Properties['docs'] -and $response.docs) {
                foreach ($doc in @($response.docs)) {
                    $results.Add((ConvertFrom-OpenLibrarySearchDoc -Doc $doc))
                }
            }
        }
        catch {
            if ($Provider -eq 'OpenLibrary') {
                Write-Error "Open Library search failed: $($_.Exception.Message)" -ErrorAction Stop
            }
        }
    }

    if ($results.Count -eq 0 -and $Provider -in @('Auto', 'GoogleBooks')) {
        try {
            $terms = @()
            if ($Title) { $terms += "intitle:$Title" }
            if ($Author) { $terms += "inauthor:$Author" }
            $uri = "https://www.googleapis.com/books/v1/volumes?q=$([uri]::EscapeDataString(($terms -join ' ')))&maxResults=$Limit"
            $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            if ($response.PSObject.Properties['items'] -and $response.items) {
                foreach ($item in @($response.items)) {
                    $results.Add((ConvertFrom-GoogleBooksSearchVolume -Volume $item))
                }
            }
        }
        catch {
            Write-Error "Google Books search failed: $($_.Exception.Message)" -ErrorAction Stop
        }
    }

    if ($results.Count -eq 0) {
        Write-Error 'No books found for the specified search.' -ErrorAction Stop
    }

    $output = ,$results.ToArray()
    if ($Pick -and $Host.UI -and $Host.UI.RawUI) {
        $selected = $output | Select-Object Title, Authors, NormalizedIsbn, PublishDate, Source, Url | Out-GridView -Title 'Select a book' -PassThru
        if ($selected) {
            return ,@($selected)
        }
        return @()
    }

    return $output
}
Set-AgentModeAlias -Name 'isbn-find' -Target 'Find-Isbn'

<#
.SYNOPSIS
    Lists alternate editions for a book ISBN.
#>
function Get-IsbnEditions {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [ValidateRange(1, 100)]
        [int]$Limit = 25
    )

    Ensure-IsbnExtendedLoaded

    $book = Get-IsbnBookRecord -Isbn $Isbn
    $workKey = $null

    if ($book.PSObject.Properties['WorkKey'] -and $book.WorkKey) {
        $workKey = $book.WorkKey
    }
    elseif ($book.PSObject.Properties['OpenLibraryKey'] -and $book.OpenLibraryKey -and $book.OpenLibraryKey -like '/books/*') {
        $edition = Invoke-RestMethod -Uri "https://openlibrary.org$($book.OpenLibraryKey).json" -Method Get -ErrorAction Stop
        if ($edition.PSObject.Properties['works'] -and $edition.works -and $edition.works.Count -gt 0 -and $edition.works[0].key) {
            $workKey = $edition.works[0].key
        }
    }

    if ([string]::IsNullOrWhiteSpace($workKey)) {
        Write-Error "Unable to resolve an Open Library work for ISBN $($book.NormalizedIsbn)." -ErrorAction Stop
    }

    $response = Invoke-RestMethod -Uri "https://openlibrary.org$workKey/editions.json?limit=$Limit" -Method Get -ErrorAction Stop
    $entries = @()
    if ($response.PSObject.Properties['entries'] -and $response.entries) {
        $entries = @($response.entries)
    }

    return @($entries | ForEach-Object { ConvertTo-IsbnEditionRow -Edition $_ })
}
Set-AgentModeAlias -Name 'isbn-editions' -Target 'Get-IsbnEditions'

<#
.SYNOPSIS
    Completes a partial ISBN by calculating the missing check digit.
#>
function Complete-Isbn {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn
    )

    process {
        Ensure-IsbnExtendedLoaded

        $digits = Get-IsbnDigitsFromInput -Isbn $Isbn
        if ($digits -match '[^0-9X]') {
            Write-Error "ISBN contains invalid characters: $Isbn" -ErrorAction Stop
        }

        if ($digits.Length -eq 12) {
            $sum = 0
            for ($i = 0; $i -lt 12; $i++) {
                $value = [int][char]$digits[$i] - [int][char]'0'
                $weight = if ($i % 2 -eq 0) { 1 } else { 3 }
                $sum += $value * $weight
            }
            $check = (10 - ($sum % 10)) % 10
            $completed = "$digits$check"
            return ConvertTo-IsbnNormalized -Isbn $completed -Strict
        }

        if ($digits.Length -eq 9 -and $digits -match '^\d{9}$') {
            $body = $digits
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
            return ConvertTo-IsbnNormalized -Isbn "$body$checkChar" -Strict
        }

        Write-Error "Unsupported partial ISBN length ($($digits.Length)). Provide 9 ISBN-10 digits or 12 ISBN-13 digits." -ErrorAction Stop
    }
}
Set-AgentModeAlias -Name 'isbn-complete' -Target 'Complete-Isbn'

<#
.SYNOPSIS
    Returns linked-data style URIs for an ISBN.
#>
function Get-IsbnUri {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn,

        [ValidateSet('All', 'Urn', 'OpenLibrary', 'IsbnA')]
        [string]$Format = 'All'
    )

    process {
        Ensure-IsbnExtendedLoaded
        $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
        $lookup = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
        $hyphenated = Format-Isbn -Isbn $lookup

        $uris = [ordered]@{
            Urn         = "urn:isbn:$lookup"
            OpenLibrary = "https://openlibrary.org/isbn/$lookup"
            IsbnA       = "https://www.worldcat.org/isbn/$lookup"
        }

        switch ($Format) {
            'Urn' { return $uris.Urn }
            'OpenLibrary' { return $uris.OpenLibrary }
            'IsbnA' { return $uris.IsbnA }
            default { return [pscustomobject]$uris }
        }
    }
}
Set-AgentModeAlias -Name 'isbn-uri' -Target 'Get-IsbnUri'

<#
.SYNOPSIS
    Normalizes and deduplicates a list of ISBN values.
#>
function ConvertTo-IsbnNormalizedList {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn
    )

    begin {
        Ensure-IsbnExtendedLoaded
        $script:IsbnNormalizedListResults = [System.Collections.Generic.List[pscustomobject]]::new()
        $script:IsbnNormalizedListSeen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    process {
        $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn
        $key = if ($normalized.Isbn13) { $normalized.Isbn13 } elseif ($normalized.Isbn10) { $normalized.Isbn10 } else { $normalized.Digits }
        if ([string]::IsNullOrWhiteSpace($key)) {
            $script:IsbnNormalizedListResults.Add($normalized)
            return
        }

        if ($script:IsbnNormalizedListSeen.Add($key)) {
            $script:IsbnNormalizedListResults.Add($normalized)
        }
    }

    end {
        return ,$script:IsbnNormalizedListResults.ToArray()
    }
}
Set-AgentModeAlias -Name 'isbn-dedupe' -Target 'ConvertTo-IsbnNormalizedList'

<#
.SYNOPSIS
    Compares two ISBN values and reports whether they refer to the same book.
#>
function Compare-Isbn {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    Ensure-IsbnExtendedLoaded

    $left = ConvertTo-IsbnNormalized -Isbn $First
    $right = ConvertTo-IsbnNormalized -Isbn $Second

    $sameBook = $false
    if ($left.IsValid -and $right.IsValid) {
        if ($left.Isbn13 -and $right.Isbn13 -and $left.Isbn13 -eq $right.Isbn13) {
            $sameBook = $true
        }
        elseif ($left.Isbn10 -and $right.Isbn10 -and $left.Isbn10 -eq $right.Isbn10) {
            $sameBook = $true
        }
    }

    [pscustomobject]@{
        First       = $left
        Second      = $right
        SameBook    = $sameBook
        BothValid   = ($left.IsValid -and $right.IsValid)
    }
}
Set-AgentModeAlias -Name 'isbn-compare' -Target 'Compare-Isbn'

<#
.SYNOPSIS
    Exports bibliography records for one or more ISBN values.
#>
function Export-IsbnBibliography {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Isbn,

        [string]$OutputPath,

        [ValidateSet('BibTeX', 'Ris', 'CslJson')]
        [string]$Format = 'BibTeX'
    )

    begin {
        Ensure-IsbnExtendedLoaded
        $script:IsbnBibliographyParts = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $book = Get-IsbnBookRecord -Isbn $Isbn
        $part = switch ($Format) {
            'Ris' { Format-IsbnRis -Book $book }
            'CslJson' { Format-IsbnCslJson -Book $book }
            default { Format-IsbnBibTeX -Book $book }
        }
        $script:IsbnBibliographyParts.Add($part)
    }

    end {
        $content = ($script:IsbnBibliographyParts -join ("$([Environment]::NewLine)$([Environment]::NewLine)")).Trim()
        if ($OutputPath) {
            $parentDir = Split-Path -Parent $OutputPath
            if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
            Set-Content -LiteralPath $OutputPath -Value $content -Encoding UTF8
        }

        return $content
    }
}
Set-AgentModeAlias -Name 'isbn-export' -Target 'Export-IsbnBibliography'

<#
.SYNOPSIS
    Adds a book to the local ISBN reading-list library.
#>
function Add-IsbnLibraryEntry {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [string]$Notes,

        [int]$Rating,

        [string[]]$Tags
    )

    Ensure-IsbnExtendedLoaded

    $book = Get-IsbnBookRecord -Isbn $Isbn
    $entry = [pscustomobject]@{
        AddedAt   = (Get-Date).ToString('o')
        Isbn      = $book.NormalizedIsbn
        Title     = $book.Title
        Authors   = @(Get-IsbnTextList -Values $book.Authors)
        Notes     = $Notes
        Rating    = $Rating
        Tags      = @($Tags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Source    = $book.Source
        Url       = $book.Url
        CoverUrl  = $book.CoverUrl
    }

    $library = [System.Collections.Generic.List[object]]::new()
    $existing = @(Read-IsbnLibrary)
    if ($existing.Count -gt 0) {
        foreach ($item in $existing) {
            $library.Add($item)
        }
    }
    $library.Add($entry)

    $path = Get-IsbnLibraryPath
    $parentDir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $library | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
    return $entry
}
Set-AgentModeAlias -Name 'isbn-library-add' -Target 'Add-IsbnLibraryEntry'

<#
.SYNOPSIS
    Reads the local ISBN reading-list library.
#>
function Get-IsbnLibrary {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    Ensure-IsbnExtendedLoaded
    return ,(Read-IsbnLibrary)
}
Set-AgentModeAlias -Name 'isbn-library' -Target 'Get-IsbnLibrary'

<#
.SYNOPSIS
    Validates an ISSN checksum.
#>
function Test-IssnValid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Issn
    )

    process {
        $digits = ($Issn -replace '(?i)^ISSN[-\s:]*', '' -replace '[-\s]', '')
        if ($digits -notmatch '^\d{7}[\dX]$') {
            return $false
        }

        $sum = 0
        for ($i = 0; $i -lt 7; $i++) {
            $sum += ([int][char]$digits[$i] - [int][char]'0') * (8 - $i)
        }

        $checkChar = $digits[7]
        $checkValue = if ($checkChar -eq 'X') { 10 } else { [int][char]$checkChar - [int][char]'0' }
        return (($sum + $checkValue) % 11) -eq 0
    }
}
Set-AgentModeAlias -Name 'issn-validate' -Target 'Test-IssnValid'

<#
.SYNOPSIS
    Reads an ISBN from the clipboard and optionally looks it up.
#>
function Get-IsbnFromClipboard {
    [CmdletBinding()]
    param(
        [switch]$Lookup,

        [ValidateSet('Object', 'Text', 'Json', 'BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago', 'Table', 'Csv')]
        [string]$OutputFormat = 'Object'
    )

    Ensure-IsbnExtendedLoaded

    $clipboard = Get-Clipboard -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($clipboard)) {
        Write-Error 'Clipboard is empty.' -ErrorAction Stop
    }

    $candidate = ($clipboard -split '\s+')[0]
    if (-not (Test-IsbnValid -Isbn $candidate)) {
        Write-Error "Clipboard does not contain a valid ISBN: $clipboard" -ErrorAction Stop
    }

    if ($Lookup) {
        return (Get-IsbnInfo -Isbn $candidate -OutputFormat $OutputFormat -ErrorAction Stop)
    }

    return (ConvertTo-IsbnNormalized -Isbn $candidate -Strict)
}
Set-AgentModeAlias -Name 'isbn-from-clipboard' -Target 'Get-IsbnFromClipboard'

<#
.SYNOPSIS
    Opens a book cover image for an ISBN.
#>
function Show-IsbnCover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [switch]$Refresh
    )

    Ensure-IsbnExtendedLoaded

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) 'ps-profile-isbn-covers'
    if (-not (Test-Path -LiteralPath $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    $coverPath = Join-Path $tempDir "$(Get-IsbnDigitsFromInput -Isbn $Isbn).img"
    Save-IsbnCover -Isbn $Isbn -OutputPath $coverPath -Refresh:$Refresh -PassThru | Out-Null

    if ($IsWindows) {
        Start-Process $coverPath
    }
    elseif (Test-CachedCommand 'xdg-open') {
        & xdg-open $coverPath
    }
    elseif ($IsMacOS) {
        Start-Process 'open' -ArgumentList @($coverPath)
    }
    else {
        Write-Output $coverPath
    }
}
Set-AgentModeAlias -Name 'isbn-cover-show' -Target 'Show-IsbnCover'

<#
.SYNOPSIS
    Generates an EAN-13 barcode image for an ISBN.
#>
function Save-IsbnBarcode {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [string]$OutputPath,

        [switch]$PassThru
    )

    Ensure-IsbnExtendedLoaded

    if (-not (Test-CachedCommand 'node')) {
        Invoke-MissingToolWarning -ToolName 'nodejs' -Tool 'node'
        return
    }

    $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
    $ean = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
    if ($ean.Length -ne 13) {
        Write-Error 'ISBN barcode generation requires a valid ISBN-13 value.' -ErrorAction Stop
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path (Get-Location).Path "$ean-barcode.png"
    }

    $nodeScript = @'
const JsBarcode = require('jsbarcode');
const { createCanvas } = require('canvas');
const fs = require('fs');
const data = process.argv[1];
const outputPath = process.argv[2];
const canvas = createCanvas(300, 120);
JsBarcode(canvas, data, { format: 'EAN13', width: 2, height: 80, displayValue: true });
fs.writeFileSync(outputPath, canvas.toBuffer('image/png'));
'@

    $tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "isbn-barcode-$(Get-Random).js"
    if (Get-Command Expand-EmbeddedNodeInstallHints -ErrorAction SilentlyContinue) {
        $nodeScript = Expand-EmbeddedNodeInstallHints -Script $nodeScript -PackageNames 'canvas', 'jsbarcode' -Global
    }
    Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
    try {
        $null = & node $tempScript $ean $OutputPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Node.js barcode generation failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
    }

    if ($PassThru) { return $OutputPath }
    Write-Output $OutputPath
}
Set-AgentModeAlias -Name 'isbn-barcode' -Target 'Save-IsbnBarcode'

<#
.SYNOPSIS
    Generates a QR code containing ISBN metadata.
#>
function Save-IsbnQrCode {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn,

        [string]$OutputPath,

        [switch]$PassThru
    )

    Ensure-IsbnExtendedLoaded

    if (-not (Get-Command New-QrCode -ErrorAction SilentlyContinue)) {
        if (Get-Command Ensure-DevTools -ErrorAction SilentlyContinue) {
            Ensure-DevTools
        }
    }

    if (-not (Get-Command New-QrCode -ErrorAction SilentlyContinue)) {
        Write-Error 'QR code generation requires DevTools QR code utilities.' -ErrorAction Stop
    }

    $book = Get-IsbnBookRecord -Isbn $Isbn
    $authors = (@(Get-IsbnTextList -Values $book.Authors) -join ', ')
    $payload = "ISBN: $($book.NormalizedIsbn)`n$($book.Title)`n$authors`n$($book.Url)"

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path (Get-Location).Path "$($book.NormalizedIsbn)-qr.png"
    }

    New-QrCode -Data $payload -OutputPath $OutputPath -ErrorAction Stop
    if ($PassThru) { return $OutputPath }
    Write-Output $OutputPath
}
Set-AgentModeAlias -Name 'isbn-qrcode' -Target 'Save-IsbnQrCode'

<#
.SYNOPSIS
    Searches the local Calibre library for an ISBN.
#>
function Search-CalibreIsbn {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Isbn
    )

    Ensure-IsbnExtendedLoaded

    if (-not (Test-CachedCommand 'calibredb')) {
        Invoke-MissingToolWarning -ToolName 'calibre' -Tool 'calibredb'
        return
    }

    $normalized = ConvertTo-IsbnNormalized -Isbn $Isbn -Strict
    $lookup = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
    & calibredb list --search "isbn:$lookup"
}
Set-AgentModeAlias -Name 'isbn-calibre' -Target 'Search-CalibreIsbn'

<#
.SYNOPSIS
    Validates an ISMN checksum.
#>
function Test-IsmnValid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Ismn
    )

    process {
        $digits = Get-IsbnDigitsFromInput -Isbn $Ismn
        if ($digits -notmatch '^\d{13}$') {
            return $false
        }

        if ($digits -notmatch '^9790') {
            return $false
        }

        return (Test-Isbn13Checksum -Digits $digits)
    }
}
Set-AgentModeAlias -Name 'ismn-validate' -Target 'Test-IsmnValid'

<#
.SYNOPSIS
    Extracts valid ISBN values from arbitrary text.
#>
function Get-IsbnFromText {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Text
    )

    process {
        Ensure-IsbnExtendedLoaded

        if ([string]::IsNullOrWhiteSpace($Text)) {
            return @()
        }

        $results = [System.Collections.Generic.List[pscustomobject]]::new()
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $pattern = '(?i)(?:ISBN[-\s]*(?:10|13)?[-\s:]*)?(?:\d[\s\-.]?){8,17}[\dX]'
        $candidates = [System.Collections.Generic.List[string]]::new()

        foreach ($match in [regex]::Matches($Text, $pattern)) {
            $candidates.Add($match.Value.Trim().TrimEnd('.', ',', ';', ':'))
        }

        foreach ($line in ($Text -split '\r?\n')) {
            $trimmed = $line.Trim()
            if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                $candidates.Add($trimmed)
            }
        }

        foreach ($candidate in $candidates) {
            $normalized = ConvertTo-IsbnNormalized -Isbn $candidate
            if (-not $normalized.IsValid) {
                continue
            }

            $key = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
            if ([string]::IsNullOrWhiteSpace($key) -or -not $seen.Add($key)) {
                continue
            }

            $results.Add($normalized)
        }

        foreach ($item in $results) {
            Write-Output $item
        }
    }
}
Set-AgentModeAlias -Name 'isbn-extract' -Target 'Get-IsbnFromText'

<#
.SYNOPSIS
    Imports ISBN values from a text file and optionally looks them up.
#>
function Import-IsbnListFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Lookup,

        [ValidateSet('Object', 'Text', 'Json', 'BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago', 'Table', 'Csv')]
        [string]$OutputFormat = 'Object',

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto',

        [string]$OutputPath
    )

    Ensure-IsbnExtendedLoaded

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Error "ISBN list file not found: $Path" -ErrorAction Stop
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $normalized = @(Get-IsbnFromText -Text $text)
    if ($normalized.Count -eq 0) {
        Write-Error "No valid ISBN values found in file: $Path" -ErrorAction Stop
    }

    if (-not $Lookup) {
        foreach ($item in $normalized) {
            Write-Output $item
        }
        return
    }

    $isbns = $normalized | ForEach-Object {
        if ($_.Isbn13) { $_.Isbn13 } else { $_.Isbn10 }
    }

    if ($OutputPath) {
        $content = $isbns | Get-IsbnInfo -OutputFormat $OutputFormat -Provider $Provider -ErrorAction Stop
        Set-Content -LiteralPath $OutputPath -Value $content -Encoding UTF8
        return $content
    }

    return ,@($isbns | Get-IsbnInfo -OutputFormat $OutputFormat -Provider $Provider -ErrorAction Stop)
}
Set-AgentModeAlias -Name 'isbn-import' -Target 'Import-IsbnListFile'

<#
.SYNOPSIS
    Watches a folder for new files containing ISBN values and processes them.
#>
function Start-IsbnWatchFolder {
    [CmdletBinding()]
    [OutputType([System.IO.FileSystemWatcher])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Object', 'Text', 'Json', 'BibTeX', 'Ris', 'CslJson', 'Apa', 'Mla', 'Chicago', 'Table', 'Csv')]
        [string]$OutputFormat = 'Object',

        [ValidateSet('Auto', 'OpenLibrary', 'GoogleBooks', 'OpenBD', 'LibraryOfCongress')]
        [string]$Provider = 'Auto',

        [string]$OutputDirectory,

        [scriptblock]$OnIsbnFound
    )

    Ensure-IsbnExtendedLoaded

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Error "Watch folder not found: $Path" -ErrorAction Stop
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $watcher = [System.IO.FileSystemWatcher]::new($resolvedPath)
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    $watcher.Filter = '*.*'

    $messageData = [ordered]@{
        OutputFormat    = $OutputFormat
        Provider        = $Provider
        OutputDirectory = $OutputDirectory
        OnIsbnFound     = $OnIsbnFound
    }

    $action = {
        $fullPath = $Event.SourceEventArgs.FullPath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            return
        }

        $config = $Event.MessageData
        try {
            Start-Sleep -Milliseconds 200
            $text = Get-Content -LiteralPath $fullPath -Raw -ErrorAction Stop
            $isbns = @(Get-IsbnFromText -Text $text)
            foreach ($normalized in $isbns) {
                $lookup = if ($normalized.Isbn13) { $normalized.Isbn13 } else { $normalized.Isbn10 }
                $book = Get-IsbnInfo -Isbn $lookup -OutputFormat $config.OutputFormat -Provider $config.Provider -ErrorAction Stop
                if ($config.OutputDirectory) {
                    $outputName = "$lookup-$($config.OutputFormat).txt"
                    $outputPath = Join-Path $config.OutputDirectory $outputName
                    if (-not (Test-Path -LiteralPath $config.OutputDirectory)) {
                        New-Item -ItemType Directory -Path $config.OutputDirectory -Force | Out-Null
                    }
                    Set-Content -LiteralPath $outputPath -Value ([string]$book) -Encoding UTF8
                }
                if ($config.OnIsbnFound) {
                    & $config.OnIsbnFound $book $lookup $fullPath
                }
            }
        }
        catch {
            Write-Warning "ISBN watch processing failed for '$fullPath': $($_.Exception.Message)"
        }
    }

    Register-ObjectEvent -InputObject $watcher -EventName Created -MessageData $messageData -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Changed -MessageData $messageData -Action $action | Out-Null
    return $watcher
}
Set-AgentModeAlias -Name 'isbn-watch' -Target 'Start-IsbnWatchFolder'
