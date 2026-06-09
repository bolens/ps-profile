<#
tests/unit/utility-update-embedded-install-hints.tests.ps1

.SYNOPSIS
    Behavioral unit tests for update-embedded-install-hints.ps1 in an isolated layout.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:UpdateHintsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'update-embedded-install-hints.ps1'
    $ConfirmPreference = 'None'
}

Describe 'update-embedded-install-hints.ps1 execution' {
    It 'Rewrites hardcoded Python install strings in a fixture conversion module' {
        $tempRoot = New-TestTempDirectory -Prefix 'embedded-hints'
            $scriptDir = Join-Path $tempRoot 'scripts' 'utils' 'fragment'
            $conversionDir = Join-Path $tempRoot 'profile.d' 'conversion-modules' 'fixture'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            $null = New-Item -ItemType Directory -Path $conversionDir -Force

            Copy-Item -LiteralPath $script:UpdateHintsScript -Destination (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $fixturePath = Join-Path $conversionDir 'sample.ps1'
            $fixtureContent = @(
                '$pythonScript = @'''
                'Write-Host "uv pip install pyarrow"'
                '''@'
                'Set-Content -LiteralPath $tempScript -Value $pythonScript'
            ) -join "`n"
            Set-Content -LiteralPath $fixturePath -Value $fixtureContent -Encoding UTF8 -NoNewline

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Updated .*conversion module file'

            $updated = Get-Content -LiteralPath $fixturePath -Raw
            $updated | Should -Match 'Expand-EmbeddedPythonInstallHints'
            $updated | Should -Not -Match 'uv pip install pyarrow'
    }

    It 'Rewrites hardcoded Node install strings in a fixture conversion module' {
        $tempRoot = New-TestTempDirectory -Prefix 'embedded-hints-node'
            $scriptDir = Join-Path $tempRoot 'scripts' 'utils' 'fragment'
            $conversionDir = Join-Path $tempRoot 'profile.d' 'conversion-modules' 'fixture'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            $null = New-Item -ItemType Directory -Path $conversionDir -Force

            Copy-Item -LiteralPath $script:UpdateHintsScript -Destination (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $fixturePath = Join-Path $conversionDir 'node-sample.ps1'
            $fixtureContent = @(
                '$nodeScript = @'''
                'Write-Host "pnpm add -g parquetjs"'
                '''@'
                'Set-Content -LiteralPath $tempScript -Value $nodeScript'
            ) -join "`n"
            Set-Content -LiteralPath $fixturePath -Value $fixtureContent -Encoding UTF8 -NoNewline

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Updated .*conversion module file'

            $updated = Get-Content -LiteralPath $fixturePath -Raw
            $updated | Should -Match 'Expand-EmbeddedNodeInstallHints'
            $updated | Should -Not -Match 'pnpm add -g parquetjs'
    }

    It 'Leaves already-migrated conversion modules unchanged' {
        $tempRoot = New-TestTempDirectory -Prefix 'embedded-hints-noop'
            $scriptDir = Join-Path $tempRoot 'scripts' 'utils' 'fragment'
            $conversionDir = Join-Path $tempRoot 'profile.d' 'conversion-modules' 'fixture'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            $null = New-Item -ItemType Directory -Path $conversionDir -Force

            Copy-Item -LiteralPath $script:UpdateHintsScript -Destination (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $fixturePath = Join-Path $conversionDir 'already-migrated.ps1'
            $fixtureContent = @(
                '$pythonScript = Expand-EmbeddedPythonInstallHints -Script $pythonScript -PackageNames ''pyarrow'' -Global'
                'Set-Content -LiteralPath $tempScript -Value $pythonScript'
            ) -join "`n"
            Set-Content -LiteralPath $fixturePath -Value $fixtureContent -Encoding UTF8 -NoNewline
            $before = Get-Content -LiteralPath $fixturePath -Raw

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'update-embedded-install-hints.ps1')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Updated 0 conversion module file'
            (Get-Content -LiteralPath $fixturePath -Raw) | Should -Be $before
    }
}
