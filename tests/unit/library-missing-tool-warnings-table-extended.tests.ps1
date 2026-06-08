<#
tests/unit/library-missing-tool-warnings-table-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for batch missing-tool warning display.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Platform.psm1') -DisableNameChecking -Force

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
}

Describe 'Show-MissingToolWarningsTable extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_SUPPRESS_TOOL_WARNINGS -ErrorAction SilentlyContinue
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Show-MissingToolWarningsTable' {
        It 'Returns without output when no warnings were collected' {
            { Show-MissingToolWarningsTable } | Should -Not -Throw
            $global:CollectedMissingToolWarnings.Count | Should -Be 0
        }

        It 'Suppresses display when PS_PROFILE_SUPPRESS_TOOL_WARNINGS is enabled' {
            Write-MissingToolWarning -Tool 'suppressed-table-tool' -InstallHint 'Install manually'
            $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS = '1'

            Show-MissingToolWarningsTable

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
        }

        It 'Renders collected warnings and clears the collection afterward' {
            Write-MissingToolWarning -Tool 'alpha-tool' -InstallHint 'Install with: scoop install alpha-tool'
            Write-MissingToolWarning -Tool 'beta-tool' -InstallHint 'Install with: brew install beta-tool'

            $output = @(Show-MissingToolWarningsTable 6>&1 | ForEach-Object { "$_" })

            $global:CollectedMissingToolWarnings.Count | Should -Be 0
            ($output -join ' ') | Should -Match 'alpha-tool'
            ($output -join ' ') | Should -Match 'beta-tool'
            ($output -join ' ') | Should -Match 'Missing Tools'
        }

        It 'Strips Install with prefixes from displayed hints' {
            Write-MissingToolWarning -Tool 'strip-tool' -InstallHint 'Install with: scoop install strip-tool'

            $output = @(Show-MissingToolWarningsTable 6>&1 | ForEach-Object { "$_" }) -join ' '

            $output | Should -Match 'strip-tool'
            $output | Should -Match 'scoop install strip-tool'
            $output | Should -Not -Match 'Install with:'
        }

        It 'Sorts warnings alphabetically by tool name' {
            Write-MissingToolWarning -Tool 'zebra-tool' -InstallHint 'z'
            Write-MissingToolWarning -Tool 'alpha-tool' -InstallHint 'a'

            $output = @(Show-MissingToolWarningsTable 6>&1 | ForEach-Object { "$_" })
            $joined = $output -join "`n"
            $joined.IndexOf('alpha-tool') | Should -BeLessThan $joined.IndexOf('zebra-tool')
        }
    }
}
