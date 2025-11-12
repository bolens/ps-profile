. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Profile Fragment Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Profile fragment dependencies' {
        It 'all profile fragments exist and are readable' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                Test-Path $file.FullName | Should -Be $true
                { Get-Content $file.FullName -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'profile fragments have valid PowerShell syntax' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                $errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
                if ($errors) {
                    $errors.Count | Should -Be 0
                }
            }
        }
    }

    Context 'Fragment disable/enable functionality' {
        It 'Get-ProfileFragment lists fragments' {
            . $script:ProfilePath

            if (Get-Command Get-ProfileFragment -ErrorAction SilentlyContinue) {
                $fragments = Get-ProfileFragment
                $fragments | Should -Not -BeNullOrEmpty
                $fragments[0] | Should -HaveMember 'Name'
                $fragments[0] | Should -HaveMember 'Enabled'
            }
        }
    }
}
