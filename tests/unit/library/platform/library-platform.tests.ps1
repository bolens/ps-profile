Describe 'Platform Module Functions' {
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
        # Import the Platform module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -ErrorAction Stop
    }

    Context 'Get-Platform' {
        It 'Returns platform information object' {
            $result = Get-Platform
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'IsWindows'
            $result.PSObject.Properties.Name | Should -Contain 'IsLinux'
            $result.PSObject.Properties.Name | Should -Contain 'IsMacOS'
        }

        It 'Platform flags are mutually exclusive' {
            $platform = Get-Platform
            $trueCount = @($platform.IsWindows, $platform.IsLinux, $platform.IsMacOS) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
            $trueCount | Should -BeLessOrEqual 1
        }
    }
}
