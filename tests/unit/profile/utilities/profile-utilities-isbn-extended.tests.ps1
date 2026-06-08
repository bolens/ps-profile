# ===============================================
# profile-utilities-isbn-extended.tests.ps1
# Unit tests for extended ISBN utilities
# ===============================================

Describe 'profile.d/utilities-modules/data/utilities-isbn-extended.ps1 structure' {
    BeforeAll {
        $current = Get-Item $PSScriptRoot
        while ($null -ne $current) {
            $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
            if (Test-Path -LiteralPath $testSupportPath) {
                . $testSupportPath
                break
            }
            if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
            $current = $current.Parent
        }
        $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/data/utilities-isbn-extended.ps1'
    }

    It 'Defines search, export, citation, and workflow commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-Isbn'
        $c | Should -Match 'Get-IsbnEditions'
        $c | Should -Match 'Export-IsbnBibliography'
        $c | Should -Match 'Complete-Isbn'
        $c | Should -Match 'Get-IsbnUri'
        $c | Should -Match 'Save-IsbnBarcode'
        $c | Should -Match 'Save-IsbnQrCode'
        $c | Should -Match 'Search-CalibreIsbn'
        $c | Should -Match 'Test-IsmnValid'
        $c | Should -Match 'Get-IsbnFromText'
        $c | Should -Match 'Import-IsbnListFile'
        $c | Should -Match 'Start-IsbnWatchFolder'
    }
}

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
    $script:IsbnCacheDir = New-TestTempDirectory -Prefix 'IsbnCacheExtended'
    $env:PS_PROFILE_ISBN_CACHE_DIR = $script:IsbnCacheDir
    $script:IsbnLibraryPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnLibrary') 'library.json'
    $env:PS_PROFILE_ISBN_LIBRARY_PATH = $script:IsbnLibraryPath
}

Describe 'utilities-isbn-extended.ps1 - search and editions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    It 'Requires at least one of -Title or -Author' {
        { Find-Isbn -ErrorAction Stop } | Should -Throw '*Title or -Author*'
    }

    It 'Find-Isbn searches Open Library by title and author' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/search.json*') {
                return [PSCustomObject]@{
                    docs = @(
                        [PSCustomObject]@{
                            title               = 'Pride and Prejudice'
                            author_name         = @('Austen, Jane')
                            isbn                = @('9780141439518')
                            first_publish_year  = 1813
                            key                 = '/works/OL66554W'
                            cover_i             = 123456
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $results = Find-Isbn -Title 'Pride and Prejudice' -Author 'Austen' -ErrorAction Stop

        $results.Count | Should -Be 1
        $results[0].Title | Should -Be 'Pride and Prejudice'
        $results[0].NormalizedIsbn | Should -Be '9780141439518'
        $results[0].WorkKey | Should -Be '/works/OL66554W'
    }

    It 'Find-Isbn falls back to Google Books when Open Library has no matches' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/search.json*') {
                return [PSCustomObject]@{ docs = @() }
            }

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{
                    items = @(
                        [PSCustomObject]@{
                            volumeInfo = [PSCustomObject]@{
                                title               = 'Google Found Book'
                                authors             = @('Fallback Author')
                                publishedDate       = '2020'
                                publisher           = 'Fallback Press'
                                industryIdentifiers = @(
                                    [PSCustomObject]@{ type = 'ISBN_13'; identifier = '9780141439518' }
                                )
                                infoLink            = 'https://books.google.com/books?id=fallback'
                            }
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $results = Find-Isbn -Title 'Missing Title' -Author 'Fallback Author' -ErrorAction Stop

        $results.Count | Should -Be 1
        $results[0].Source | Should -Be 'GoogleBooks'
        $results[0].Title | Should -Be 'Google Found Book'
        $results[0].NormalizedIsbn | Should -Be '9780141439518'
    }

    It 'Get-IsbnEditions returns alternate editions for a work' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title       = 'Example Book'
                        key         = '/books/OL123M'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url         = 'https://openlibrary.org/books/OL123M'
                    }
                }
            }

            if ($Uri -like 'https://openlibrary.org/books/OL123M.json') {
                return [PSCustomObject]@{
                    key   = '/books/OL123M'
                    works = @([PSCustomObject]@{ key = '/works/OLWORK' })
                }
            }

            if ($Uri -like 'https://openlibrary.org/works/OLWORK/editions.json*') {
                return [PSCustomObject]@{
                    entries = @(
                        [PSCustomObject]@{
                            title        = 'Edition One'
                            publish_date = '2001'
                            isbn_13      = @('9780306406157')
                            key          = '/books/OL123M'
                        },
                        [PSCustomObject]@{
                            title        = 'Edition Two'
                            publish_date = '2005'
                            isbn_13      = @('9780141439518')
                            key          = '/books/OL456M'
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $editions = Get-IsbnEditions -Isbn '978-0-306-40615-7' -ErrorAction Stop

        $editions.Count | Should -Be 2
        $editions[0].Title | Should -Be 'Edition One'
        $editions[1].Isbn13 | Should -Contain '9780141439518'
    }

    It 'Get-IsbnEditions resolves work key from Open Library edition metadata' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title       = 'Edition Lookup Book'
                        key         = '/books/OL123M'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url         = 'https://openlibrary.org/books/OL123M'
                    }
                }
            }

            if ($Uri -like 'https://openlibrary.org/books/OL123M.json') {
                return [PSCustomObject]@{
                    key   = '/books/OL123M'
                    works = @([PSCustomObject]@{ key = '/works/OLWORK' })
                }
            }

            if ($Uri -like 'https://openlibrary.org/works/OLWORK/editions.json*') {
                return [PSCustomObject]@{
                    entries = @(
                        [PSCustomObject]@{
                            title        = 'Resolved Edition'
                            publish_date = '2010'
                            isbn_13      = @('9780306406157')
                            key          = '/books/OL123M'
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $editions = Get-IsbnEditions -Isbn '978-0-306-40615-7' -ErrorAction Stop

        $editions.Count | Should -Be 1
        $editions[0].Title | Should -Be 'Resolved Edition'
    }
}

Describe 'utilities-isbn-extended.ps1 - bibliography and citations' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    It 'Returns RIS and CSL-JSON output formats' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title           = 'Citation Book'
                    authors         = @([PSCustomObject]@{ name = 'Jane Author' })
                    publishers      = @([PSCustomObject]@{ name = 'Citation Press' })
                    publish_date    = '2012'
                    number_of_pages = 222
                    identifiers     = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url             = 'https://openlibrary.org/books/OLCIT'
                }
            }
        }

        $ris = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Ris -ErrorAction Stop
        $csl = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat CslJson -Refresh -ErrorAction Stop

        $ris | Should -Match 'TY  - BOOK'
        $ris | Should -Match 'TI  - Citation Book'
        $ris | Should -Match 'ER  -'

        $parsed = $csl | ConvertFrom-Json
        $parsed.type | Should -Be 'book'
        $parsed.title | Should -Be 'Citation Book'
        $parsed.ISBN | Should -Be '9780306406157'
    }

    It 'Returns APA, MLA, and Chicago citation strings' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title        = 'Style Book'
                    authors      = @([PSCustomObject]@{ name = 'Jane Author' })
                    publishers   = @([PSCustomObject]@{ name = 'Style Press' })
                    publish_date = '1999'
                    identifiers  = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url          = 'https://openlibrary.org/books/OLSTYLE'
                }
            }
        }

        $apa = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Apa -ErrorAction Stop
        $mla = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Mla -Refresh -ErrorAction Stop
        $chicago = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Chicago -Refresh -ErrorAction Stop

        $apa | Should -Match 'Author, J\.'
        $apa | Should -Match 'ISBN 9780306406157'
        $mla | Should -Match 'Jane Author\. Style Book\.'
        $chicago | Should -Match 'ISBN: 9780306406157'
    }

    It 'Formats APA citations for two authors' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title        = 'Two Author Book'
                    authors      = @(
                        [PSCustomObject]@{ name = 'Alice Alpha' },
                        [PSCustomObject]@{ name = 'Bob Beta' }
                    )
                    publishers   = @([PSCustomObject]@{ name = 'Multi Press' })
                    publish_date = '2015'
                    identifiers  = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url          = 'https://openlibrary.org/books/OLMULTI'
                }
            }
        }

        $twoAuthors = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Apa -ErrorAction Stop
        $twoAuthors | Should -Match 'Alpha, A\., & Beta, B\.'
    }

    It 'Formats APA citations for three or more authors' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title        = 'Many Author Book'
                    authors      = @(
                        [PSCustomObject]@{ name = 'Alice Alpha' },
                        [PSCustomObject]@{ name = 'Bob Beta' },
                        [PSCustomObject]@{ name = 'Carol Gamma' }
                    )
                    publishers   = @([PSCustomObject]@{ name = 'Multi Press' })
                    publish_date = '2015'
                    identifiers  = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url          = 'https://openlibrary.org/books/OLMULTI'
                }
            }
        }

        $manyAuthors = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Apa -ErrorAction Stop
        $manyAuthors | Should -Match 'Alpha, A\., et al\.'
    }

    It 'Exports multi-record bibliographies to a file' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like '*9780306406157*' -or $Uri -like '*ISBN:9780306406157*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title       = 'Book One'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url         = 'https://openlibrary.org/books/OL1'
                    }
                }
            }

            if ($Uri -like '*9780141439518*' -or $Uri -like '*ISBN:9780141439518*') {
                return [PSCustomObject]@{
                    'ISBN:9780141439518' = [PSCustomObject]@{
                        title       = 'Book Two'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780141439518') }
                        url         = 'https://openlibrary.org/books/OL2'
                    }
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnBibExport') 'library.bib'
        $content = @('978-0-306-40615-7', '978-0-14-143951-8') | Export-IsbnBibliography -Format BibTeX -OutputPath $outputPath -ErrorAction Stop

        Test-Path -LiteralPath $outputPath | Should -Be $true
        $content | Should -Match '@book\{'
        $content | Should -Match 'Book One'
        $content | Should -Match 'Book Two'
    }

    It 'Exports RIS and CSL-JSON bibliographies without writing a file' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title        = 'Export Book'
                    authors      = @([PSCustomObject]@{ name = 'Export Author' })
                    publishers   = @([PSCustomObject]@{ name = 'Export Press' })
                    publish_date = '2018'
                    identifiers  = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url          = 'https://openlibrary.org/books/OLEXPORT'
                }
            }
        }

        $ris = Export-IsbnBibliography -Isbn '978-0-306-40615-7' -Format Ris -ErrorAction Stop
        $csl = Export-IsbnBibliography -Isbn '978-0-306-40615-7' -Format CslJson -ErrorAction Stop

        $ris | Should -Match 'TY  - BOOK'
        ($csl | ConvertFrom-Json).title | Should -Be 'Export Book'
    }
}

Describe 'utilities-isbn-extended.ps1 - utilities and workflows' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
        if (Test-Path -LiteralPath $script:IsbnLibraryPath) {
            Remove-Item -LiteralPath $script:IsbnLibraryPath -Force
        }
    }

    It 'Completes partial ISBN-13 and ISBN-10 values' {
        $completed13 = Complete-Isbn '978030640615'
        $completed13.Isbn13 | Should -Be '9780306406157'

        $completed10 = Complete-Isbn '030640615'
        $completed10.Isbn10 | Should -Be '0306406152'
    }

    It 'Returns linked-data URIs for an ISBN' {
        $uris = Get-IsbnUri '978-0-306-40615-7'
        $uris.Urn | Should -Be 'urn:isbn:9780306406157'
        $uris.OpenLibrary | Should -Be 'https://openlibrary.org/isbn/9780306406157'
        $uris.IsbnA | Should -Be 'https://www.worldcat.org/isbn/9780306406157'
        Get-IsbnUri '978-0-306-40615-7' -Format Urn | Should -Be 'urn:isbn:9780306406157'
        Get-IsbnUri '978-0-306-40615-7' -Format OpenLibrary | Should -Be 'https://openlibrary.org/isbn/9780306406157'
        Get-IsbnUri '978-0-306-40615-7' -Format IsbnA | Should -Be 'https://www.worldcat.org/isbn/9780306406157'
    }

    It 'Deduplicates normalized ISBN lists' {
        $results = @('978-0-306-40615-7', '0-306-40615-2', '9780306406157') | ConvertTo-IsbnNormalizedList
        $results.Count | Should -Be 1
        $results[0].Isbn13 | Should -Be '9780306406157'
    }

    It 'Compares two ISBN values for equivalence' {
        $comparison = Compare-Isbn -First '978-0-306-40615-7' -Second '0-306-40615-2'
        $comparison.SameBook | Should -Be $true
        $comparison.BothValid | Should -Be $true

        $different = Compare-Isbn -First '978-0-306-40615-7' -Second '978-0-14-143951-8'
        $different.SameBook | Should -Be $false
        $different.BothValid | Should -Be $true
    }

    It 'Rejects unsupported partial ISBN lengths' {
        { Complete-Isbn '12345' -ErrorAction Stop } | Should -Throw '*Unsupported partial ISBN length*'
    }

    It 'Supports offline lookup from cache only' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Offline Book'
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLOFF'
                }
            }
        }

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-TestCommandInvocationCapture

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            throw 'Network should not be used in offline mode'
        }

        $offline = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -Offline -ErrorAction Stop
        $offline.Title | Should -Be 'Offline Book'
        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Adds and reads local library entries' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Library Book'
                    authors     = @([PSCustomObject]@{ name = 'Library Author' })
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLL'
                }
            }
        }

        $entry = Add-IsbnLibraryEntry -Isbn '978-0-306-40615-7' -Notes 'To read' -Rating 5 -Tags 'tech'
        $entry.Title | Should -Be 'Library Book'
        $entry.Notes | Should -Be 'To read'

        $library = Get-IsbnLibrary
        $library.Count | Should -Be 1
        $library[0].Isbn | Should -Be '9780306406157'
    }

    It 'Validates ISSN checksums' {
        Test-IssnValid '0378-5955' | Should -Be $true
        Test-IssnValid '0378-5956' | Should -Be $false
    }

    It 'Reads a valid ISBN from the clipboard' {
        Set-Clipboard -Value '978-0-306-40615-7'
        $normalized = Get-IsbnFromClipboard
        $normalized.Isbn13 | Should -Be '9780306406157'
    }

    It 'Looks up clipboard ISBN values when -Lookup is specified' {
        Set-Clipboard -Value '978-0-306-40615-7'

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Clipboard Book'
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLCLIP'
                }
            }
        }

        $book = Get-IsbnFromClipboard -Lookup -ErrorAction Stop
        $book.Title | Should -Be 'Clipboard Book'
    }

    It 'Rejects empty or invalid clipboard ISBN values' {
        Set-Clipboard -Value ''
        { Get-IsbnFromClipboard -ErrorAction Stop } | Should -Throw '*Clipboard is empty*'

        Set-Clipboard -Value 'not-an-isbn'
        { Get-IsbnFromClipboard -ErrorAction Stop } | Should -Throw '*does not contain a valid ISBN*'
    }

    It 'Returns an empty library when the library file is corrupt' {
        Set-Content -LiteralPath $script:IsbnLibraryPath -Value '{not-json' -Encoding UTF8
        @(Get-IsbnLibrary).Count | Should -Be 0
    }

    It 'Show-IsbnCover returns the saved cover path when no viewer is available' {
        Set-TestCommandAvailabilityState -CommandName 'xdg-open' -Available $false

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Cover Book'
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    cover       = [PSCustomObject]@{ large = 'https://covers.openlibrary.org/b/id/999-L.jpg' }
                    url         = 'https://openlibrary.org/books/OLCOVER'
                }
            }
        }

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-TestCommandInvocationCapture

        Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -OnInvoke {
            param($OutFile)
            [System.IO.File]::WriteAllBytes($OutFile, [byte[]](9, 8, 7))
            return [PSCustomObject]@{ StatusCode = 200 }
        }

        $coverPath = Show-IsbnCover -Isbn '978-0-306-40615-7' -ErrorAction Stop | Select-Object -Last 1
        $coverPath | Should -Match '9780306406157\.img$'
        Test-Path -LiteralPath $coverPath | Should -Be $true
    }

    It 'Save-IsbnBarcode writes a barcode image via Node.js' {
        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnBarcode') 'barcode.png'

        Setup-CapturingCommandMock -CommandName 'node' -OnInvoke {
            param($ScriptPath, $Ean, $Path)
            [System.IO.File]::WriteAllBytes($Path, [byte[]](1, 2, 3, 4))
            return ''
        }

        $saved = Save-IsbnBarcode -Isbn '978-0-306-40615-7' -OutputPath $outputPath -PassThru -ErrorAction Stop
        $saved | Should -Be $outputPath
        Test-Path -LiteralPath $outputPath | Should -Be $true
    }

    It 'Save-IsbnQrCode writes a QR code image with book metadata' {
        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnQr') 'qr.png'

        Set-Item -Path 'Function:\global:New-QrCode' -Value {
            param(
                [string]$Data,
                [string]$OutputPath
            )

            Set-Content -LiteralPath $OutputPath -Value $Data -Encoding UTF8
        }.GetNewClosure() -Force

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Qr Book'
                    authors     = @([PSCustomObject]@{ name = 'Qr Author' })
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLQR'
                }
            }
        }

        $saved = Save-IsbnQrCode -Isbn '978-0-306-40615-7' -OutputPath $outputPath -PassThru -ErrorAction Stop
        $saved | Should -Be $outputPath
        (Get-Content -LiteralPath $outputPath -Raw) | Should -Match 'ISBN: 9780306406157'
        (Get-Content -LiteralPath $outputPath -Raw) | Should -Match 'Qr Book'
    }

    It 'Search-CalibreIsbn queries the local Calibre library' {
        Setup-CapturingCommandMock -CommandName 'calibredb' -OnInvoke {
            param([string]$SearchArg)
            return "id title authors`n1 Calibre Book Author"
        }

        $output = Search-CalibreIsbn -Isbn '978-0-306-40615-7' -ErrorAction Stop
        $output | Should -Match 'Calibre Book'
        $global:TestCommandInvocationCaptures.Count | Should -BeGreaterThan 0
    }

    It 'Validates ISMN checksums' {
        Test-IsmnValid '9790123456785' | Should -Be $true
        Test-IsmnValid '979-0-1201-234567-85' | Should -Be $false
        Test-IsmnValid '9790123456786' | Should -Be $false
        Test-IsmnValid '9780306406157' | Should -Be $false
    }

    It 'Extracts multiple ISBN values from arbitrary text' {
        $text = "Scanned inventory:`nPrimary: ISBN 978-0-306-40615-7`nAlternate 0-306-40615-2`nNoise: 978-0-306-40615-8"

        $results = Get-IsbnFromText -Text $text
        $results.Count | Should -Be 1
        $results[0].Isbn13 | Should -Be '9780306406157'
    }

    It 'Imports ISBN values from a list file without lookup' {
        $listPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnImportList') 'books.txt'
        Set-Content -LiteralPath $listPath -Value @(
            '9780306406157',
            '9780141439518'
        ) -Encoding UTF8

        $results = Import-IsbnListFile -Path $listPath
        $results.Count | Should -Be 2
        $results[0].Isbn13 | Should -Be '9780306406157'
        $results[1].Isbn13 | Should -Be '9780141439518'
    }

    It 'Imports and looks up ISBN values from a list file' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like '*9780306406157*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title       = 'Imported Book'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url         = 'https://openlibrary.org/books/OLIMPORT'
                    }
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $listPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnImportLookup') 'books.txt'
        Set-Content -LiteralPath $listPath -Value '978-0-306-40615-7' -Encoding UTF8

        $book = Import-IsbnListFile -Path $listPath -Lookup -OutputFormat Object -ErrorAction Stop
        $book.Title | Should -Be 'Imported Book'
    }

    It 'Start-IsbnWatchFolder returns a configured FileSystemWatcher' {
        $watchDir = New-TestTempDirectory -Prefix 'IsbnWatch'
        $watcher = Start-IsbnWatchFolder -Path $watchDir -OutputFormat Object
        $watcher | Should -Not -BeNullOrEmpty
        $watcher.Path | Should -Be (Resolve-Path -LiteralPath $watchDir).Path
        $watcher.EnableRaisingEvents | Should -Be $true
        $watcher.Dispose()
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | ForEach-Object { Unregister-Event -SubscriptionId $_.SubscriptionId }
    }
}

Describe 'utilities-isbn-extended.ps1 - ISBN watch folder processing' {
    BeforeEach {
        $script:WatchHandle = $null
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
        $script:IsbnCacheDir = New-TestTempDirectory -Prefix 'IsbnWatchCache'
        $env:PS_PROFILE_ISBN_CACHE_DIR = $script:IsbnCacheDir

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Watched Book'
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLWATCH'
                }
            }
        }

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-TestCommandInvocationCapture

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            throw 'Network should not be used during watch processing'
        }
    }

    AfterEach {
        Get-EventSubscriber | ForEach-Object {
            Unregister-Event -SubscriptionId $_.SubscriptionId -ErrorAction SilentlyContinue
        }
        if ($null -ne $script:WatchHandle) {
            $script:WatchHandle.Dispose()
            $script:WatchHandle = $null
        }
    }

    It 'Throws when the watch directory does not exist' {
        $missingDir = Join-Path (New-TestTempDirectory -Prefix 'IsbnWatchMissingParent') 'missing-watch'

        { Start-IsbnWatchFolder -Path $missingDir -ErrorAction Stop } | Should -Throw '*Watch folder not found*'
    }

    It 'Processes new files and writes lookup output using cached metadata' {
        $watchDir = New-TestTempDirectory -Prefix 'IsbnWatchProcess'
        $outputDir = New-TestTempDirectory -Prefix 'IsbnWatchOutput'
        $script:WatchHandle = Start-IsbnWatchFolder -Path $watchDir -OutputFormat Text -OutputDirectory $outputDir

        $scanFile = Join-Path $watchDir 'incoming.txt'
        Set-Content -LiteralPath $scanFile -Value 'Inventory ISBN 978-0-306-40615-7' -Encoding UTF8

        $outputFile = Join-Path $outputDir '9780306406157-Text.txt'
        $deadline = [datetime]::UtcNow.AddSeconds(5)
        while (-not (Test-Path -LiteralPath $outputFile) -and [datetime]::UtcNow -lt $deadline) {
            Start-Sleep -Milliseconds 100
        }

        Test-Path -LiteralPath $outputFile | Should -Be $true
        (Get-Content -LiteralPath $outputFile -Raw) | Should -Match 'Watched Book'
        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Invokes OnIsbnFound when a matching ISBN is discovered in a new file' {
        $watchDir = New-TestTempDirectory -Prefix 'IsbnWatchCallback'
        $markerPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnWatchMarker') 'callback.txt'
        $script:WatchHandle = Start-IsbnWatchFolder -Path $watchDir -OutputFormat Object -OnIsbnFound {
            param($Book, $Lookup, $SourcePath)

            [PSCustomObject]@{
                Title  = $Book.Title
                Lookup = $Lookup
                Source = $SourcePath
            } | ConvertTo-Json -Compress | Set-Content -LiteralPath $markerPath -Encoding UTF8
        }

        $scanFile = Join-Path $watchDir 'callback-source.txt'
        Set-Content -LiteralPath $scanFile -Value 'Scanning 978-0-306-40615-7' -Encoding UTF8

        $deadline = [datetime]::UtcNow.AddSeconds(5)
        while (-not (Test-Path -LiteralPath $markerPath) -and [datetime]::UtcNow -lt $deadline) {
            Start-Sleep -Milliseconds 100
        }

        Test-Path -LiteralPath $markerPath | Should -Be $true
        $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
        $marker.Title | Should -Be 'Watched Book'
        $marker.Lookup | Should -Be '9780306406157'
        $marker.Source | Should -Be $scanFile
    }
}

Describe 'utilities-isbn-extended.ps1 - formatter edge cases' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    It 'Includes subtitle and bibliographic fields in RIS output' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title           = 'Ten Digit Book'
                    subtitle        = 'A Companion Volume'
                    authors         = @([PSCustomObject]@{ name = 'Ten Author' })
                    publishers      = @([PSCustomObject]@{ name = 'Ten Press' })
                    publish_date    = '1988'
                    identifiers     = [PSCustomObject]@{
                        isbn_13 = @('9780306406157')
                        isbn_10 = @('0306406152')
                    }
                    url             = 'https://openlibrary.org/books/OLTEN'
                }
            }
        }

        $ris = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Ris -ErrorAction Stop

        $ris | Should -Match 'TI  - Ten Digit Book'
        $ris | Should -Match 'T2  - A Companion Volume'
        $ris | Should -Match 'AU  - Ten Author'
        $ris | Should -Match 'PB  - Ten Press'
        $ris | Should -Match 'PY  - 1988'
        $ris | Should -Match 'SN  - 9780306406157'
    }

    It 'Uses literal author names in CSL-JSON when only a single name token is present' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title        = 'Mononym Book'
                    authors      = @([PSCustomObject]@{ name = 'Plato' })
                    publish_date = '380 BCE'
                    identifiers  = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url          = 'https://openlibrary.org/books/OLMONO'
                }
            }
        }

        $csl = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat CslJson -ErrorAction Stop
        $parsed = $csl | ConvertFrom-Json

        $parsed.author.Count | Should -Be 1
        $parsed.author[0].literal | Should -Be 'Plato'
        $parsed.title | Should -Be 'Mononym Book'
    }

    It 'Uses n.p. and n.d. placeholders when publisher and year are missing' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Sparse Book'
                    authors     = @([PSCustomObject]@{ name = 'Sparse Author' })
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLSPARSE'
                }
            }
        }

        $mla = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Mla -ErrorAction Stop
        $chicago = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Chicago -Refresh -ErrorAction Stop

        $mla | Should -Match 'n\.p\., n\.d\.'
        $chicago | Should -Match 'n\.p\., n\.d\.'
    }

    It 'Honors -Limit when searching Open Library by title' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/search.json*') {
                $Uri | Should -Match 'limit=2'
                return [PSCustomObject]@{
                    docs = @(
                        [PSCustomObject]@{
                            title              = 'Limited One'
                            author_name        = @('Author A')
                            isbn               = @('9780306406157')
                            first_publish_year = 2001
                            key                = '/works/OL1W'
                        },
                        [PSCustomObject]@{
                            title              = 'Limited Two'
                            author_name        = @('Author B')
                            isbn               = @('9780141439518')
                            first_publish_year = 2002
                            key                = '/works/OL2W'
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $results = Find-Isbn -Title 'Limited' -Limit 2 -Provider OpenLibrary -ErrorAction Stop

        $results.Count | Should -Be 2
        $results[0].Title | Should -Be 'Limited One'
        $results[1].Title | Should -Be 'Limited Two'
    }

    It 'Maps sparse Google Books search volumes with partial metadata' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{
                    items = @(
                        [PSCustomObject]@{
                            volumeInfo = [PSCustomObject]@{
                                title = 'Sparse Google Volume'
                            }
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $results = Find-Isbn -Title 'Sparse Google Volume' -Provider GoogleBooks -ErrorAction Stop

        $results.Count | Should -Be 1
        $results[0].Source | Should -Be 'GoogleBooks'
        $results[0].Title | Should -Be 'Sparse Google Volume'
        @($results[0].Authors).Count | Should -Be 0
        $results[0].NormalizedIsbn | Should -BeNullOrEmpty
    }

    It 'Save-IsbnBarcode exits early when node is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'node' -Available $false
        $outputPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnBarcodeMissingNode') 'barcode.png'

        Save-IsbnBarcode -Isbn '978-0-306-40615-7' -OutputPath $outputPath -ErrorAction SilentlyContinue | Out-Null

        Test-Path -LiteralPath $outputPath | Should -Be $false
        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Persists library entries to PS_PROFILE_ISBN_LIBRARY_PATH' {
        $customLibrary = Join-Path (New-TestTempDirectory -Prefix 'IsbnLibraryCustom') 'custom-library.json'
        $previousLibraryPath = $env:PS_PROFILE_ISBN_LIBRARY_PATH
        $env:PS_PROFILE_ISBN_LIBRARY_PATH = $customLibrary

        try {
            Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title       = 'Custom Path Book'
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url         = 'https://openlibrary.org/books/OLCUSTOM'
                    }
                }
            }

            Add-IsbnLibraryEntry -Isbn '978-0-306-40615-7' -Notes 'saved here' -ErrorAction Stop | Out-Null

            Test-Path -LiteralPath $customLibrary | Should -Be $true
            $saved = Get-Content -LiteralPath $customLibrary -Raw | ConvertFrom-Json
            $saved.Count | Should -Be 1
            $saved[0].Notes | Should -Be 'saved here'
        }
        finally {
            if ($null -eq $previousLibraryPath) {
                Remove-Item Env:\PS_PROFILE_ISBN_LIBRARY_PATH -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_ISBN_LIBRARY_PATH = $previousLibraryPath
            }
        }
    }
}
