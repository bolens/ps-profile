#
# Tests for clipboard helper functions.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
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
