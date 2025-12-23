#
# Tests for git helper fragments.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git.ps1')
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
            # After calling Ensure-GitHelper, the functions and aliases should be available
            # Check for the functions first, then aliases
            Get-Command Invoke-GitClone -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Save-GitStash -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Aliases should also be available
            foreach ($cmd in 'gcl', 'gsta') {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }
}
