<#
tests/unit/profile-conversion-image-messages-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for image conversion missing-message fallbacks.
#>

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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Conversion image messages extended scenarios' {
    Context 'Get-ImageConversionToolMissingMessage' {
        It 'Returns the generic fallback when platform hints are unavailable' {
            try {
            $originalPlatformHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue

                        Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            $message = Get-ImageConversionToolMissingMessage
            $message | Should -Match 'ImageMagick or GraphicsMagick'
            $message | Should -Match 'package manager'
            }
            finally {
                if ($null -ne $originalPlatformHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalPlatformHint.ScriptBlock -Force
                }
            }
        }

        It 'Includes separate guidance for ImageMagick and GraphicsMagick when hints are available' {
            $message = Get-ImageConversionToolMissingMessage

            $message | Should -Match 'ImageMagick:'
            $message | Should -Match 'GraphicsMagick:'
        }
    }

    Context 'Get-ConversionToolMissingMessage fallback path' {
        It 'Uses Get-ToolInstallationCommand when platform hints are unavailable' {
            try {
            $originalPlatformHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue

                        Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            $message = Get-ConversionToolMissingMessage -ToolName 'ffmpeg'
            $message | Should -Match 'ffmpeg'
            $message | Should -Match 'Install with:'
            }
            finally {
                if ($null -ne $originalPlatformHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalPlatformHint.ScriptBlock -Force
                }
            }
        }
    }
}
