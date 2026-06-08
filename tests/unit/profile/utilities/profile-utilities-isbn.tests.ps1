# ===============================================
# profile-utilities-isbn.tests.ps1
# Unit tests for ISBN utility functions
# ===============================================

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
    $script:IsbnCacheDir = New-TestTempDirectory -Prefix 'IsbnCache'
    $env:PS_PROFILE_ISBN_CACHE_DIR = $script:IsbnCacheDir
}

function script:Get-TestOpenLibraryIsbnMock {
    param(
        [string]$Title = 'Example Book',
        [string]$Isbn13 = '9780306406157',
        [string]$Author = 'Jane Author',
        [string]$CoverUrl = 'https://covers.openlibrary.org/b/id/12345-L.jpg'
    )

    return {
        param($Uri)

        if ($Uri -like 'https://openlibrary.org/api/books*') {
            return [PSCustomObject]@{
                "ISBN:$Isbn13" = [PSCustomObject]@{
                    title           = $Title
                    authors         = @([PSCustomObject]@{ name = $Author })
                    publishers      = @([PSCustomObject]@{ name = 'Example Press' })
                    publish_date    = '2001'
                    number_of_pages = 123
                    identifiers     = [PSCustomObject]@{
                        isbn_13 = @($Isbn13)
                        isbn_10 = @('0306406152')
                    }
                    cover           = [PSCustomObject]@{ large = $CoverUrl }
                    url             = 'https://openlibrary.org/books/OL123M'
                }
            }
        }

        throw "Unexpected URI: $Uri"
    }.GetNewClosure()
}

Describe 'utilities-isbn.ps1 - normalization and validation' {
    It 'Normalizes hyphenated ISBN-13 values' {
        $result = ConvertTo-IsbnNormalized -Isbn '978-0-306-40615-7'

        $result.IsValid | Should -Be $true
        $result.Format | Should -Be 'ISBN-13'
        $result.Isbn13 | Should -Be '9780306406157'
        $result.Isbn10 | Should -Be '0306406152'
    }

    It 'Normalizes prefixed ISBN-10 values' {
        $result = ConvertTo-IsbnNormalized -Isbn 'ISBN-10: 0-306-40615-2'

        $result.IsValid | Should -Be $true
        $result.Format | Should -Be 'ISBN-10'
        $result.Isbn10 | Should -Be '0306406152'
        $result.Isbn13 | Should -Be '9780306406157'
    }

    It 'Normalizes compact ISBN-13 values' {
        $result = ConvertTo-IsbnNormalized -Isbn '9780306406157'

        $result.IsValid | Should -Be $true
        $result.Isbn13 | Should -Be '9780306406157'
    }

    It 'Normalizes spaced ISBN-10 values' {
        $result = ConvertTo-IsbnNormalized -Isbn '0 306 40615 2'

        $result.IsValid | Should -Be $true
        $result.Isbn10 | Should -Be '0306406152'
    }

    It 'Normalizes 9-digit SBN values by padding to ISBN-10' {
        $result = ConvertTo-IsbnNormalized -Isbn '306406152'

        $result.IsValid | Should -Be $true
        $result.Format | Should -Be 'ISBN-10'
        $result.Isbn10 | Should -Be '0306406152'
    }

    It 'Accepts ISBN-10 check digit X' {
        $result = ConvertTo-IsbnNormalized -Isbn '0-8044-2957-X'

        $result.IsValid | Should -Be $true
        $result.Isbn10 | Should -Be '080442957X'
    }

    It 'Rejects invalid checksums' {
        $result = ConvertTo-IsbnNormalized -Isbn '978-0-306-40615-8'

        $result.IsValid | Should -Be $false
        $result.IsValidChecksum | Should -Be $false
    }

    It 'Test-IsbnValid returns true for valid ISBN values' {
        Test-IsbnValid -Isbn '978-0-306-40615-7' | Should -Be $true
        Test-IsbnValid -Isbn '0-306-40615-2' | Should -Be $true
    }

    It 'Test-IsbnValid returns false for invalid ISBN values' {
        Test-IsbnValid -Isbn '978-0-306-40615-8' | Should -Be $false
        Test-IsbnValid -Isbn 'not-an-isbn' | Should -Be $false
    }

    It 'Format-Isbn returns standard hyphen groups' {
        Format-Isbn -Isbn '9780306406157' | Should -Be '978-0-306-40615-7'
        Format-Isbn -Isbn '0306406152' -Format 'ISBN-10' | Should -Be '0-306-40615-2'
    }

    It 'Format-Isbn supports registrant-aware hyphenation' {
        Format-Isbn -Isbn '9780131103627' -Hyphenation Registrant | Should -Be '978-0-13-110362-7'
        Format-Isbn -Isbn '9780131103627' -Hyphenation Standard | Should -Be '978-0-131-10362-7'
    }

    It 'Converts ISBN-10 and ISBN-13 forms to each other' {
        $from10 = ConvertTo-IsbnNormalized -Isbn '0-306-40615-2'
        $from13 = ConvertTo-IsbnNormalized -Isbn '978-0-306-40615-7'

        $from10.Isbn13 | Should -Be $from13.Isbn13
        $from13.Isbn10 | Should -Be $from10.Isbn10
    }

    It 'Normalizes ISBN-13 prefixed values and dot separators' {
        $result = ConvertTo-IsbnNormalized -Isbn 'ISBN-13: 978.0.306.40615.7'

        $result.IsValid | Should -Be $true
        $result.Format | Should -Be 'ISBN-13'
        $result.Isbn13 | Should -Be '9780306406157'
    }

    It 'Normalizes en-dash and em-dash separators' {
        $enDash = [char]0x2013
        $emDash = [char]0x2014
        $enResult = ConvertTo-IsbnNormalized -Isbn ("978$enDash" + '0-306-40615-7')
        $emResult = ConvertTo-IsbnNormalized -Isbn ("978$emDash" + '0-306-40615-7')

        $enResult.IsValid | Should -Be $true
        $emResult.IsValid | Should -Be $true
        $enResult.Isbn13 | Should -Be '9780306406157'
        $emResult.Isbn13 | Should -Be '9780306406157'
    }

    It 'Validates 979-prefixed ISBN-13 without producing ISBN-10' {
        $result = ConvertTo-IsbnNormalized -Isbn '979-10-41280858'

        $result.IsValid | Should -Be $true
        $result.Format | Should -Be 'ISBN-13'
        $result.Isbn13 | Should -Be '9791041280858'
        $result.Isbn10 | Should -BeNullOrEmpty
    }

    It 'Rejects unsupported lengths and invalid characters' {
        $tooShort = ConvertTo-IsbnNormalized -Isbn '12345'
        $tooLong = ConvertTo-IsbnNormalized -Isbn '97803064061571234'
        $letters = ConvertTo-IsbnNormalized -Isbn '978-abc-def'

        $tooShort.IsValid | Should -Be $false
        $tooLong.IsValid | Should -Be $false
        $letters.IsValid | Should -Be $false
    }

    It 'Throws in strict mode for invalid checksums and malformed values' {
        { ConvertTo-IsbnNormalized -Isbn '978-0-306-40615-8' -Strict -ErrorAction Stop } | Should -Throw '*checksum*'
        { ConvertTo-IsbnNormalized -Isbn 'not-an-isbn' -Strict -ErrorAction Stop } | Should -Throw
        { ConvertTo-IsbnNormalized -Isbn '' -Strict -ErrorAction Stop } | Should -Throw '*empty*'
    }

    It 'Supports pipeline input for normalization and validation' {
        @('978-0-306-40615-7', '0-306-40615-2') | ConvertTo-IsbnNormalized | ForEach-Object {
            $_.IsValid | Should -Be $true
        }

        @('978-0-306-40615-7', '978-0-306-40615-8') | Test-IsbnValid | Should -Be @($true, $false)
    }

    It 'Exposes aliases that resolve to ISBN utility functions' {
        (Get-Command isbn-validate -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Test-IsbnValid'
        (Get-Command isbn-normalize -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-IsbnNormalized'
        (Get-Command isbn-format -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Format-Isbn'
        (Get-Command isbn -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-IsbnInfo'
    }
}

Describe 'utilities-isbn.ps1 - lookup' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    It 'Looks up metadata from Open Library' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title           = 'Example Book'
                        subtitle        = 'A Subtitle'
                        authors         = @(
                            [PSCustomObject]@{ name = 'Jane Author'; url = 'https://openlibrary.org/authors/OL1A' }
                        )
                        publishers      = @(
                            [PSCustomObject]@{ name = 'Example Press' }
                        )
                        publish_date    = '2001'
                        number_of_pages = 123
                        subjects        = @(
                            [PSCustomObject]@{ name = 'Fiction'; url = 'https://openlibrary.org/subjects/fiction' }
                        )
                        identifiers     = [PSCustomObject]@{
                            isbn_13 = @('9780306406157')
                            isbn_10 = @('0306406152')
                        }
                        cover           = [PSCustomObject]@{
                            large = 'https://covers.openlibrary.org/b/id/12345-L.jpg'
                        }
                        url             = 'https://openlibrary.org/books/OL123M'
                    }
                }
            }

            if ($Uri -like 'https://openlibrary.org/isbn/*') {
                return [PSCustomObject]@{
                    title           = 'Example Book'
                    subtitle        = 'A Subtitle'
                    authors         = @([PSCustomObject]@{ name = 'Jane Author' })
                    publishers      = @('Example Press')
                    publish_date    = '2001'
                    number_of_pages = 123
                    subjects        = @([PSCustomObject]@{ name = 'Fiction' })
                    isbn_13         = @('9780306406157')
                    isbn_10         = @('0306406152')
                    covers          = @(12345)
                    key             = '/books/OL123M'
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '978-0-306-40615-7' -Provider OpenLibrary -OutputFormat Object -ErrorAction Stop

        $result.Title | Should -Be 'Example Book'
        $result.Authors | Should -Contain 'Jane Author'
        $result.Source | Should -Be 'OpenLibrary'
        $result.NormalizedIsbn | Should -Be '9780306406157'
        Assert-TestCommandInvokedExactlyOnce
    }

    It 'Falls back to Google Books when Open Library has no result' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*' -or $Uri -like 'https://openlibrary.org/isbn/*') {
                throw 'Not found'
            }

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{
                    totalItems = 1
                    items      = @(
                        [PSCustomObject]@{
                            volumeInfo = [PSCustomObject]@{
                                title               = 'Fallback Book'
                                authors             = @('Fallback Author')
                                publisher           = 'Fallback Publisher'
                                publishedDate       = '1999'
                                pageCount           = 200
                                categories          = @('History')
                                industryIdentifiers = @(
                                    [PSCustomObject]@{ type = 'ISBN_13'; identifier = '9780306406157' }
                                    [PSCustomObject]@{ type = 'ISBN_10'; identifier = '0306406152' }
                                )
                                infoLink            = 'https://books.google.com/books?id=abc'
                            }
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '0-306-40615-2' -OutputFormat Object -ErrorAction Stop

        $result.Title | Should -Be 'Fallback Book'
        $result.Source | Should -Be 'GoogleBooks'
        $result.Authors | Should -Contain 'Fallback Author'
    }

    It 'Returns formatted text output by default' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title           = 'Text Book'
                        authors         = @([PSCustomObject]@{ name = 'Text Author' })
                        publishers      = @([PSCustomObject]@{ name = 'Text Press' })
                        publish_date    = '2010'
                        number_of_pages = 50
                        identifiers     = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url             = 'https://openlibrary.org/books/OL999M'
                    }
                }
            }

            return [PSCustomObject]@{
                title           = 'Text Book'
                authors         = @([PSCustomObject]@{ name = 'Text Author' })
                publishers      = @('Text Press')
                publish_date    = '2010'
                number_of_pages = 50
                isbn_13         = @('9780306406157')
                key             = '/books/OL999M'
            }
        }

        $result = Get-IsbnInfo -Isbn '9780306406157' -ErrorAction Stop

        $result | Should -Match 'Title: Text Book'
        $result | Should -Match 'Authors: Text Author'
        $result | Should -Match 'ISBN-13: 9780306406157'
        $result | Should -Match 'Source: OpenLibrary'
    }

    It 'Throws when lookup providers return no results' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            throw 'Lookup failed'
        }

        { Get-IsbnInfo -Isbn '978-0-306-40615-7' -ErrorAction Stop } | Should -Throw
    }

    It 'Rejects invalid ISBN before calling lookup providers' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            throw 'Invoke-RestMethod should not be called for invalid ISBN input'
        }

        { Get-IsbnInfo -Isbn '978-0-306-40615-8' -ErrorAction Stop } | Should -Throw '*checksum*'
        Get-TestCommandInvocationArgsFlat | Should -BeNullOrEmpty
    }

    It 'Returns JSON output with expected book fields' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                'ISBN:9780306406157' = [PSCustomObject]@{
                    title       = 'Json Book'
                    authors     = @([PSCustomObject]@{ name = 'Json Author' })
                    publishers  = @([PSCustomObject]@{ name = 'Json Press' })
                    identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                    url         = 'https://openlibrary.org/books/OLJSON'
                }
            }
        }

        $json = Get-IsbnInfo -Isbn '9780306406157' -OutputFormat Json -ErrorAction Stop
        $parsed = $json | ConvertFrom-Json

        $parsed.Title | Should -Be 'Json Book'
        $parsed.Source | Should -Be 'OpenLibrary'
        $parsed.NormalizedIsbn | Should -Be '9780306406157'
    }

    It 'Uses Open Library edition API when data API returns no edition' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{}
            }

            if ($Uri -like 'https://openlibrary.org/isbn/*') {
                return [PSCustomObject]@{
                    title           = 'Edition API Book'
                    authors         = @([PSCustomObject]@{ name = 'Edition Author' })
                    publishers      = @('Edition Press')
                    publish_date    = '1990'
                    number_of_pages = 99
                    isbn_13         = @('9780306406157')
                    covers          = @(54321)
                    key             = '/books/OLEDIT'
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '9780306406157' -Provider OpenLibrary -OutputFormat Object -ErrorAction Stop

        $result.Title | Should -Be 'Edition API Book'
        $result.Source | Should -Be 'OpenLibrary'
        $result.CoverUrl | Should -Be 'https://covers.openlibrary.org/b/id/54321-L.jpg'
        @((Get-TestCommandInvocationArgsFlat | Where-Object { $_ -like 'https://openlibrary.org/isbn/*' })).Count | Should -Be 1
    }

    It 'Uses only Open Library when Provider is OpenLibrary' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title = 'Open Library Only'
                        url   = 'https://openlibrary.org/books/OLOL'
                    }
                }
            }

            if ($Uri -like 'https://www.googleapis.com/*') {
                throw 'Google Books should not be called when Provider is OpenLibrary'
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '9780306406157' -Provider OpenLibrary -OutputFormat Object -ErrorAction Stop
        $result.Title | Should -Be 'Open Library Only'
        @((Get-TestCommandInvocationArgsFlat | Where-Object { $_ -like 'https://www.googleapis.com/*' })).Count | Should -Be 0
    }

    It 'Uses only Google Books when Provider is GoogleBooks' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/*') {
                throw 'Open Library should not be called when Provider is GoogleBooks'
            }

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{
                    totalItems = 1
                    items      = @(
                        [PSCustomObject]@{
                            volumeInfo = [PSCustomObject]@{
                                title   = 'Google Only'
                                authors = @('Google Author')
                            }
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '0-306-40615-2' -Provider GoogleBooks -OutputFormat Object -ErrorAction Stop
        $result.Title | Should -Be 'Google Only'
        $result.Source | Should -Be 'GoogleBooks'
        @((Get-TestCommandInvocationArgsFlat | Where-Object { $_ -like 'https://openlibrary.org/*' })).Count | Should -Be 0
    }

    It 'Looks up valid 979-prefixed ISBN-13 values' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                $Uri | Should -Match 'ISBN:9791041280858'
                return [PSCustomObject]@{
                    'ISBN:9791041280858' = [PSCustomObject]@{
                        title = '979 Book'
                        url   = 'https://openlibrary.org/books/OL979'
                    }
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '979-10-41280858' -OutputFormat Object -ErrorAction Stop
        $result.Title | Should -Be '979 Book'
        $result.NormalizedIsbn | Should -Be '9791041280858'
    }

    It 'Ranks providers in Auto mode and prefers richer metadata' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title = 'Sparse Title'
                        url   = 'https://openlibrary.org/books/OLSPARSE'
                    }
                }
            }

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{
                    totalItems = 1
                    items      = @(
                        [PSCustomObject]@{
                            volumeInfo = [PSCustomObject]@{
                                title         = 'Rich Google Title'
                                authors       = @('Rich Author')
                                publisher     = 'Rich Press'
                                publishedDate = '2001'
                                pageCount     = 300
                                industryIdentifiers = @(
                                    [PSCustomObject]@{ type = 'ISBN_13'; identifier = '9780306406157' },
                                    [PSCustomObject]@{ type = 'OTHER'; identifier = '10.1000/rich.doi' }
                                )
                                imageLinks    = [PSCustomObject]@{ thumbnail = 'https://example.test/cover.jpg' }
                                infoLink      = 'https://books.google.com/books?id=rich'
                            }
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '978-0-306-40615-7' -Provider Auto -OutputFormat Object -ErrorAction Stop
        $result.Source | Should -Be 'GoogleBooks'
        $result.Title | Should -Be 'Rich Google Title'
        $result.Doi | Should -Be '10.1000/rich.doi'
    }

    It 'Looks up Japanese ISBN values through OpenBD when requested' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://api.openbd.jp/v1/bd*') {
                return ,@(
                    [PSCustomObject]@{
                        summary = [PSCustomObject]@{
                            title     = 'OpenBD Book'
                            author    = 'Japanese Author'
                            publisher = 'OpenBD Press'
                            pubdate   = '2020'
                            isbn      = @('9784062751230')
                        }
                    }
                )
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '9784062751230' -Provider OpenBD -OutputFormat Object -ErrorAction Stop
        $result.Source | Should -Be 'OpenBD'
        $result.Title | Should -Be 'OpenBD Book'
    }

    It 'Falls back to Library of Congress when Auto providers return sparse metadata' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{}
            }

            if ($Uri -like 'https://openlibrary.org/isbn/*') {
                throw 'No Open Library edition metadata'
            }

            if ($Uri -like 'https://www.googleapis.com/books/v1/volumes*') {
                return [PSCustomObject]@{ totalItems = 0; items = @() }
            }

            if ($Uri -like 'https://www.loc.gov/search*') {
                return [PSCustomObject]@{
                    results = @(
                        [PSCustomObject]@{
                            title   = 'LoC Book'
                            creator = @('LoC Author')
                            date    = '1999'
                            id      = 'https://www.loc.gov/item/locbook'
                        }
                    )
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $result = Get-IsbnInfo -Isbn '978-0-306-40615-7' -Provider Auto -OutputFormat Object -ErrorAction Stop
        $result.Source | Should -Be 'LibraryOfCongress'
        $result.Title | Should -Be 'LoC Book'
    }

    It 'Includes DOI values in text and BibTeX output' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            return [PSCustomObject]@{
                totalItems = 1
                items      = @(
                    [PSCustomObject]@{
                        volumeInfo = [PSCustomObject]@{
                            title               = 'Doi Book'
                            authors             = @('Doi Author')
                            industryIdentifiers = @(
                                [PSCustomObject]@{ type = 'ISBN_13'; identifier = '9780306406157' },
                                [PSCustomObject]@{ type = 'OTHER'; identifier = '10.5555/doi.book' }
                            )
                            infoLink            = 'https://books.google.com/books?id=doi'
                        }
                    }
                )
            }
        }

        $text = Get-IsbnInfo -Isbn '978-0-306-40615-7' -Provider GoogleBooks -OutputFormat Text -ErrorAction Stop
        $bibtex = Get-IsbnInfo -Isbn '978-0-306-40615-7' -Provider GoogleBooks -OutputFormat BibTeX -Refresh -ErrorAction Stop

        $text | Should -Match 'DOI: 10\.5555/doi\.book'
        $bibtex | Should -Match 'doi = \{10\.5555/doi\.book\}'
    }
}

Describe 'utilities-isbn.ps1 - cache, export, batch, and cover' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    It 'Caches lookup results and avoids repeat provider calls' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock)

        $first = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop
        $first.Title | Should -Be 'Example Book'

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            throw 'Provider should not be called when cache is warm'
        }

        $second = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop
        $second.Title | Should -Be 'Example Book'
        $second.Source | Should -Be 'OpenLibrary'
    }

    It 'Refreshes cached lookup results when -Refresh is specified' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -Title 'Cached Book')

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-TestCommandInvocationCapture

        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -Title 'Fresh Book')

        $refreshed = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -Refresh -ErrorAction Stop
        $refreshed.Title | Should -Be 'Fresh Book'
        $global:TestCommandInvocationCaptures.Count | Should -BeGreaterThan 0
    }

    It 'Clears cache entries for one ISBN or the entire cache directory' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock)

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Get-ChildItem -LiteralPath $script:IsbnCacheDir -Filter '*.json' | Should -Not -BeNullOrEmpty

        Clear-IsbnCache -Isbn '978-0-306-40615-7'
        Get-ChildItem -LiteralPath $script:IsbnCacheDir -Filter '*.json' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-IsbnCache
        Get-ChildItem -LiteralPath $script:IsbnCacheDir -Filter '*.json' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Returns BibTeX output with citation key and bibliographic fields' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -Author 'Jane Author')

        $bibtex = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat BibTeX -ErrorAction Stop

        $bibtex | Should -Match '@book\{'
        $bibtex | Should -Match 'title = \{Example Book\}'
        $bibtex | Should -Match 'author = \{Author, Jane\}'
        $bibtex | Should -Match 'year = \{2001\}'
        $bibtex | Should -Match 'isbn = \{9780306406157\}'
        $bibtex | Should -Match 'pages = \{123\}'
    }

    It 'Supports batch table output from pipeline input' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*bibkeys=ISBN:9780306406157*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title      = 'Book One'
                        publishers = @([PSCustomObject]@{ name = 'Press One' })
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url        = 'https://openlibrary.org/books/OL1'
                    }
                }
            }

            if ($Uri -like 'https://openlibrary.org/api/books*bibkeys=ISBN:9780141439518*') {
                return [PSCustomObject]@{
                    'ISBN:9780141439518' = [PSCustomObject]@{
                        title      = 'Book Two'
                        publishers = @([PSCustomObject]@{ name = 'Press Two' })
                        identifiers = [PSCustomObject]@{ isbn_13 = @('9780141439518') }
                        url        = 'https://openlibrary.org/books/OL2'
                    }
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $rows = @('978-0-306-40615-7', '978-0-14-143951-8') | Get-IsbnInfo -OutputFormat Table -ErrorAction Stop

        $rows.Count | Should -Be 2
        $rows[0].Title | Should -Be 'Book One'
        $rows[1].Title | Should -Be 'Book Two'
        $rows[0].Isbn | Should -Be '9780306406157'
        $rows[1].Isbn | Should -Be '9780141439518'
    }

    It 'Supports batch CSV output from pipeline input' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -Title 'Csv Book')

        $csv = @('978-0-306-40615-7') | Get-IsbnInfo -OutputFormat Csv -ErrorAction Stop

        $csv | Should -Match 'Isbn'
        $csv | Should -Match 'Title'
        $csv | Should -Match '9780306406157'
        $csv | Should -Match 'Csv Book'
    }

    It 'Downloads cover images to the requested output path' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock)
        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null
        Clear-TestCommandInvocationCapture

        $coverPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnCover') 'cover.jpg'
        $coverBytes = [byte[]](1, 2, 3, 4)

        Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -OnInvoke {
            param($OutFile)
            [System.IO.File]::WriteAllBytes($OutFile, $coverBytes)
            return [PSCustomObject]@{ StatusCode = 200 }
        }

        $savedPath = Save-IsbnCover -Isbn '978-0-306-40615-7' -OutputPath $coverPath -PassThru -ErrorAction Stop

        $savedPath | Should -Be $coverPath
        Test-Path -LiteralPath $coverPath | Should -Be $true
        [System.IO.File]::ReadAllBytes($coverPath) | Should -Be $coverBytes
    }

    It 'Throws when cover art is not available for an ISBN' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -CoverUrl '')

        { Save-IsbnCover -Isbn '978-0-306-40615-7' -ErrorAction Stop } | Should -Throw '*cover*'
    }

    It 'Propagates cover download failures from Invoke-WebRequest' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock)
        Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null

        Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -OnInvoke {
            throw 'Cover download failed'
        }

        { Save-IsbnCover -Isbn '978-0-306-40615-7' -ErrorAction Stop } | Should -Throw '*Cover download failed*'
    }

    It 'Uses XDG_CACHE_HOME when PS_PROFILE_ISBN_CACHE_DIR is unset' {
        $xdgCache = New-TestTempDirectory -Prefix 'XdgIsbnCache'
        $previousCacheDir = $env:PS_PROFILE_ISBN_CACHE_DIR
        $previousXdg = $env:XDG_CACHE_HOME
        Remove-Item Env:\PS_PROFILE_ISBN_CACHE_DIR -ErrorAction SilentlyContinue
        $env:XDG_CACHE_HOME = $xdgCache

        try {
            Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke (Get-TestOpenLibraryIsbnMock -Title 'XDG Cache Book')

            Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat Object -ErrorAction Stop | Out-Null

            $expectedDir = Join-Path $xdgCache 'ps-profile' 'isbn'
            Test-Path -LiteralPath $expectedDir | Should -Be $true
            Get-ChildItem -LiteralPath $expectedDir -Filter '*.json' | Should -Not -BeNullOrEmpty
        }
        finally {
            if ($null -eq $previousCacheDir) {
                Remove-Item Env:\PS_PROFILE_ISBN_CACHE_DIR -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_ISBN_CACHE_DIR = $previousCacheDir
            }
            if ($null -eq $previousXdg) {
                Remove-Item Env:\XDG_CACHE_HOME -ErrorAction SilentlyContinue
            }
            else {
                $env:XDG_CACHE_HOME = $previousXdg
            }
        }
    }

    It 'Escapes BibTeX special characters in titles and authors' {
        Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
            param($Uri)

            if ($Uri -like 'https://openlibrary.org/api/books*') {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title           = 'Fish & Chips {Special}'
                        authors         = @([PSCustomObject]@{ name = 'O''Connor, Pat' })
                        publishers      = @([PSCustomObject]@{ name = 'Example Press' })
                        publish_date    = '2001'
                        identifiers     = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        url             = 'https://openlibrary.org/books/OLBIB'
                    }
                }
            }

            throw "Unexpected URI: $Uri"
        }

        $bibtex = Get-IsbnInfo -Isbn '978-0-306-40615-7' -OutputFormat BibTeX -ErrorAction Stop

        $bibtex | Should -Match 'title = \{Fish \& Chips \\\{Special\\\}\}'
        $bibtex | Should -Match 'author = \{Pat, O''Connor,\}'
    }
}
