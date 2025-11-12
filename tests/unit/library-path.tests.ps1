. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Path Module Functions' {
    BeforeAll {
        Import-TestCommonModule | Out-Null
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    }

    Context 'Get-CommonModulePath' {
        It 'Returns valid path to Common.psm1' {
            $result = Get-CommonModulePath -ScriptPath $PSScriptRoot
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Common\.psm1$'
        }

        It 'Resolves path correctly for scripts/utils location' {
            $utilsScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test.ps1'
            $result = Get-CommonModulePath -ScriptPath $utilsScriptPath
            Test-Path $result | Should -Be $true
        }
    }
}
