. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Platform Module Functions' {
    BeforeAll {
        Import-TestCommonModule | Out-Null
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
