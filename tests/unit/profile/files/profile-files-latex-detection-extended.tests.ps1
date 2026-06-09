# ===============================================
# profile-files-latex-detection-extended.tests.ps1
# Execution tests for files/LaTeXDetection.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files/LaTeXDetection.ps1')
}

Describe 'profile.d/files/LaTeXDetection.ps1 extended scenarios' {
    It 'Registers LaTeX engine detection helpers' {
        Get-Command Test-DocumentLatexEngineAvailable -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-DocumentLatexEngine -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-DocumentLatexEngineAvailable returns pdflatex when stubbed available' {
        Mark-TestCommandsUnavailable -CommandNames @('pdflatex', 'xelatex', 'luatex')
        Set-TestCommandAvailabilityState -CommandName 'pdflatex' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Test-DocumentLatexEngineAvailable | Should -Be 'pdflatex'
    }

    It 'Ensure-DocumentLatexEngine throws when no LaTeX engine is available' {
        Mark-TestCommandsUnavailable -CommandNames @('pdflatex', 'xelatex', 'luatex')
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Ensure-DocumentLatexEngine } | Should -Throw '*LaTeX engine*'
    }
}
