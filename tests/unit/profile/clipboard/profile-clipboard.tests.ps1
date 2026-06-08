#
# Tests for clipboard helper functions.
#

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
    . (Join-Path $script:ProfileDir 'clipboard.ps1')
}

Describe 'Profile clipboard functions' {
    Context 'Availability checks' {
        It 'cb function is available' {
            Get-Command cb -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'pb function is available' {
            Get-Command pb -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }

    Context 'Clipboard operations' {
        It 'cb copies text to clipboard' {
            { 'test text' | cb } | Should -Not -Throw
        }

        It 'pb retrieves from clipboard' {
            { $null = pb; $true } | Should -Not -Throw
        }
    }
}
