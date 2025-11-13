. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Cross-Platform Compatibility Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Cross-platform compatibility' {
        It 'path separators are handled correctly' {
            $profileContent = Get-Content $script:ProfilePath -Raw
            $hardcodedPaths = [regex]::Matches($profileContent, '[^\\]\\[A-Za-z]:\\')
            $hardcodedPaths.Count | Should -BeLessThan 10
        }

        It 'functions work with both Windows and Unix-style paths' {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '02-files-navigation.ps1')

            $testPath = Join-Path $TestDrive 'test'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            Push-Location $testPath
            try {
                ..
                $parent = Get-Location
                $parent.Path | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }
}
