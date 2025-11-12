. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Profile Structure Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Fragment ordering' {
        It 'fragments load in correct order' {
            $fragDir = $script:ProfileDir
            $files = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name
            $fileNames = $files | Select-Object -ExpandProperty Name

            $fileNames[0] | Should -Match '^00-'

            $sorted = $fileNames | Sort-Object
            $fileNames | Should -Be $sorted
        }
    }
}
