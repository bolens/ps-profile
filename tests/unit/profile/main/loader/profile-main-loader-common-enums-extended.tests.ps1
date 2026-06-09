# ===============================================
# profile-main-loader-common-enums-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 CommonEnums bootstrap
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

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
    $script:CommonEnumsModule = Join-Path $script:TestRepoRoot 'scripts/lib/core/CommonEnums.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 CommonEnums bootstrap extended scenarios' {
    It 'CommonEnums module exists at the expected repository path' {
        Test-Path -LiteralPath $script:CommonEnumsModule | Should -Be $true
    }

    It 'Loads FileSystemPathType globally before fragment modules run' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
try {
    `$null = [enum]::GetNames([FileSystemPathType])
    'COMMON_ENUMS_TYPE_OK'
}
catch { }
"@

        $result | Should -Match 'COMMON_ENUMS_TYPE_OK'
    }

    It 'Profile load proceeds to fragment loading after CommonEnums import' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Before fragment loading section' -Quiet) { 'COMMON_ENUMS_LOAD_OK' }
"@

        $result | Should -Match 'COMMON_ENUMS_LOAD_OK'
    }
}
