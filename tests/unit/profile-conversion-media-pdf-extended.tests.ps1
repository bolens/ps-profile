<#
tests/unit/profile-conversion-media-pdf-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/pdf.ps1'
}
Describe 'profile.d/conversion-modules/media/pdf.ps1 extended scenarios' {
    It 'Documents PDF media format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PDF media format conversion utilities'
        $c | Should -Match 'PDF to text extraction and PDF merging'
    }
    It 'Defines Initialize-FileConversion-MediaPdf with pdftotext and pdftk' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaPdf'
        $c | Should -Match '_ConvertFrom-PdfToText'
        $c | Should -Match '_Merge-Pdf'
    }
    It 'Registers pdf-to-text and pdf-merge entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertFrom-PdfToText'
        $c | Should -Match 'pdf-to-text'
        $c | Should -Match 'pdf-merge'
    }
}

