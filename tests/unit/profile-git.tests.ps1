#
# Tests for git helper fragments.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    . (Join-Path $script:ProfileDir '11-git.ps1')
}

Describe 'Profile git functions' {
    Context 'Shortcut availability' {
        It 'git shortcuts are available' {
            foreach ($cmd in 'gs', 'ga', 'gc', 'gp') {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }

    Context 'Helper initialization' {
        It 'Ensure-GitHelper initializes lazy helpers' {
            { Ensure-GitHelper } | Should -Not -Throw
            foreach ($cmd in 'gcl', 'gsta') {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }
}
