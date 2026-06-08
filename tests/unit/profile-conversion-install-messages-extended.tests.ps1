<#
tests/unit/profile-conversion-install-messages-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for conversion tool missing-message helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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

Describe 'Conversion install messages extended scenarios' {
    Context 'Get-ConversionToolMissingMessage' {
        It 'Uses Context as the message subject when provided' {
            $message = Get-ConversionToolMissingMessage `
                -ToolName 'ffmpeg' `
                -Context 'Video conversion'

            $message | Should -Match '^Video conversion is not available'
            $message | Should -Match 'Install with:'
        }

        It 'Appends AdditionalHint text to the final message' {
            $message = Get-ConversionToolMissingMessage `
                -ToolName 'pandoc' `
                -AdditionalHint '(needed for markdown export)'

            $message | Should -Match 'needed for markdown export'
            $message | Should -Match 'Install with:'
        }

        It 'Uses InstallPackageName when resolving platform hints' {
            $message = Get-ConversionToolMissingMessage `
                -ToolName 'rg' `
                -InstallPackageName 'ripgrep'

            $message | Should -Match 'ripgrep'
            $message | Should -Match 'Install with:'
        }
    }

    Context 'Get-ImageConversionToolMissingMessage' {
        It 'Includes install guidance for both ImageMagick and GraphicsMagick' {
            $message = Get-ImageConversionToolMissingMessage

            $message | Should -Match 'ImageMagick'
            $message | Should -Match 'GraphicsMagick'
            $message | Should -Match 'not found'
        }
    }

    Context 'Get-ToolInstallationCommand' {
        It 'Returns install commands without the Install with prefix' {
            $command = Get-ToolInstallationCommand -ToolName 'jq'
            $command | Should -Not -Match '^Install with:'
            $command | Should -Match 'jq'
        }
    }
}
