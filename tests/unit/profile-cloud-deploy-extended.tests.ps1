<#
tests/unit/profile-cloud-deploy-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/cloud-modules/cloud-deploy.ps1'
}
Describe 'profile.d/cloud-modules/cloud-deploy.ps1 extended scenarios' {
    It 'Declares standard tier for cloud deployment helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Doppler, Heroku, Vercel, and Netlify'
    }
    It 'Defines Get-DopplerSecrets, Deploy-Heroku, Deploy-Vercel, and Deploy-Netlify' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-DopplerSecrets'
        $c | Should -Match 'Deploy-Heroku'
        $c | Should -Match 'Deploy-Vercel'
        $c | Should -Match 'Deploy-Netlify'
    }
    It 'Marks cloud-deploy fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'cloud-deploy'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'cloud-deploy'"
    }
}
