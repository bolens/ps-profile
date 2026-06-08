# ===============================================
# isbn.tests.ps1
# Integration tests for ISBN utilities via Ensure-Utilities
# ===============================================

Describe 'ISBN utilities integration' {
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
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadFilesFragment
        . (Join-Path $script:ProfileDir 'utilities.ps1')
        Ensure-Utilities
        $script:IsbnCacheDir = New-TestTempDirectory -Prefix 'IsbnCacheIntegration'
        $env:PS_PROFILE_ISBN_CACHE_DIR = $script:IsbnCacheDir
    }

    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-IsbnCache
    }

    Context 'Lazy-loaded ISBN commands' {
        It 'Registers ISBN utility commands after Ensure-Utilities' {
            Get-Command Get-IsbnInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-IsbnNormalized -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Test-IsbnValid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Format-Isbn -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Normalizes and formats ISBN values through aliases' {
            isbn-validate '978-0-306-40615-7' | Should -Be $true
            isbn-format '0-306-40615-2' | Should -Be '978-0-306-40615-7'
            Format-Isbn -Isbn '0-306-40615-2' -Format ISBN-10 | Should -Be '0-306-40615-2'

            $normalized = isbn-normalize 'ISBN-10: 0-306-40615-2'
            $normalized.Isbn13 | Should -Be '9780306406157'
        }

        It 'Exports BibTeX and downloads covers through public aliases' {
            Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
                return [PSCustomObject]@{
                    'ISBN:9780306406157' = [PSCustomObject]@{
                        title           = 'Integration Bib Book'
                        authors         = @([PSCustomObject]@{ name = 'Integration Author' })
                        publishers      = @([PSCustomObject]@{ name = 'Integration Press' })
                        publish_date    = '2015'
                        number_of_pages = 250
                        identifiers     = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                        cover           = [PSCustomObject]@{ large = 'https://covers.openlibrary.org/b/id/999-L.jpg' }
                        url             = 'https://openlibrary.org/books/OLBIB'
                    }
                }
            }

            $bibtex = isbn '978-0-306-40615-7' -OutputFormat BibTeX -ErrorAction Stop
            $bibtex | Should -Match '@book\{'
            $bibtex | Should -Match 'Integration Bib Book'

            $coverPath = Join-Path (New-TestTempDirectory -Prefix 'IsbnCoverIntegration') 'cover.jpg'
            Setup-CapturingCommandMock -CommandName 'Invoke-WebRequest' -OnInvoke {
                param($OutFile)
                Set-Content -LiteralPath $OutFile -Value 'cover-bytes' -NoNewline
                return [PSCustomObject]@{ StatusCode = 200 }
            }

            isbn-cover '978-0-306-40615-7' -OutputPath $coverPath -PassThru -ErrorAction Stop | Should -Be $coverPath
            Test-Path -LiteralPath $coverPath | Should -Be $true
        }

        It 'Performs end-to-end lookup with mocked providers' {
            Setup-CapturingCommandMock -CommandName 'Invoke-RestMethod' -OnInvoke {
                param($Uri)

                if ($Uri -like 'https://openlibrary.org/api/books*') {
                    return [PSCustomObject]@{
                        'ISBN:9780306406157' = [PSCustomObject]@{
                            title       = 'Integration Book'
                            authors     = @([PSCustomObject]@{ name = 'Integration Author' })
                            publishers  = @([PSCustomObject]@{ name = 'Integration Press' })
                            identifiers = [PSCustomObject]@{ isbn_13 = @('9780306406157') }
                            url         = 'https://openlibrary.org/books/OLINT'
                        }
                    }
                }

                throw "Unexpected URI: $Uri"
            }

            $text = isbn '978-0-306-40615-7' -ErrorAction Stop

            $text | Should -Match 'Title: Integration Book'
            $text | Should -Match 'Authors: Integration Author'
            $text | Should -Match 'Source: OpenLibrary'
        }
    }
}
