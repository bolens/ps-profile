Describe 'Platform Module Functions' {
    BeforeEach {
        @(
            'PS_PROFILE_PLATFORM_FORCE_NAME'
            'PS_PROFILE_PLATFORM_FORCE_FALLBACK'
            'PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM'
            'PS_PROFILE_PLATFORM_FORCE_UNAME'
            'PS_PROFILE_PLATFORM_FORCE_NATURAL_WINDOWS'
            'PS_PROFILE_PLATFORM_FORCE_NATURAL_MACOS'
            'PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK'
            'PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE'
            'PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE'
        ) | ForEach-Object { Remove-Item "Env:$_" -ErrorAction SilentlyContinue }
    }

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

    AfterAll {
        Remove-Module Platform -ErrorAction SilentlyContinue -Force
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
