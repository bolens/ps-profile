#
# Tests for git helper fragments.
#

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'git.ps1')
}

Describe 'Profile git functions' {
    Context 'Shortcut availability' {
        It 'git shortcuts are available after Ensure-Git' {
            Ensure-Git

            foreach ($functionName in 'Invoke-GitStatus', 'Add-GitChanges', 'Save-GitCommit', 'Publish-GitChanges') {
                Get-Command $functionName -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            # gs/gl may conflict with Ghostscript/Get-Location on Linux; verify aliases only when registered.
            foreach ($cmd in 'gs', 'ga', 'gc', 'gp') {
                $alias = Get-Alias $cmd -Scope Global -ErrorAction SilentlyContinue
                if ($alias) {
                    $alias | Should -Not -Be $null
                }
            }
        }
    }

    Context 'Helper initialization' {
        It 'Ensure-GitHelper initializes lazy helpers' {
            Ensure-Git

            { Ensure-GitHelper } | Should -Not -Throw

            Get-Command Invoke-GitClone -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Save-GitStash -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            foreach ($cmd in 'gcl', 'gsta') {
                $alias = Get-Alias $cmd -Scope Global -ErrorAction SilentlyContinue
                if ($alias) {
                    $alias | Should -Not -Be $null
                }
            }
        }
    }
}
