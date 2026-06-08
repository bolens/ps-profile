<#
tests/unit/profile-files-latex-detection-extended.tests.ps1
#>
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files/LaTeXDetection.ps1'
}
Describe 'profile.d/files/LaTeXDetection.ps1 extended scenarios' {
    It 'Documents LaTeX engine detection for PDF conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'LaTeX engine detection utilities'
        $c | Should -Match 'pdf-engine'
    }
    It 'Defines Test-DocumentLatexEngineAvailable with pdflatex and Scoop MiKTeX paths' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-DocumentLatexEngineAvailable'
        $c | Should -Match "Test-CachedCommand 'pdflatex'"
        $c | Should -Match 'SCOOP_GLOBAL'
    }
    It 'Defines Ensure-DocumentLatexEngine with missing-tool warnings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-DocumentLatexEngine'
        $c | Should -Match 'Invoke-MissingToolWarning'
        $c | Should -Match 'miktex'
    }
}
