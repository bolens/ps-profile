<#
tests/unit/validation-check-doc-coverage.tests.ps1

.SYNOPSIS
    Behavioral smoke tests for check-doc-coverage.ps1.
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
    $script:CheckDocCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-coverage.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-doc-coverage.ps1 execution' {
    It 'emits JSON for an isolated empty profile in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageJsonInProcess'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:CheckDocCoverageScript -ProfilePath $profilePath -DocsPath $docsPath -Json 2>&1 |
                Out-String

            $output | Should -Match 'DocumentedFunctionCount'
            $output | Should -Match 'documentation coverage report emitted as JSON'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'summarizes isolated documentation gaps in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageSummaryInProcess'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $profilePath 'fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture documented function.
.DESCRIPTION
    Used to exercise documentation coverage summaries.
#>
function Get-DocCoverageSummaryFixture {
    'ok'
}

Set-AgentModeFunction -Name 'Get-UndocumentedDynamicFixture' -Body { 'dynamic' }
'@ -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:CheckDocCoverageScript -ProfilePath $profilePath -DocsPath $docsPath 2>&1 |
                Out-String

            $output | Should -Match 'Documentation coverage summary'
            $output | Should -Match 'Dynamic registrations without resolvable help'
            $output | Should -Match 'Missing markdown files'
            $output | Should -Match 'Documentation coverage check completed'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'fails strict isolated documentation gaps in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageStrictInProcess'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $profilePath 'fixture.ps1') -Value @'
<#
.SYNOPSIS
    Strict fixture function.
.DESCRIPTION
    Used to exercise strict documentation coverage.
#>
function Get-DocCoverageStrictInProcessFixture {
    'ok'
}
'@ -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            { & $script:CheckDocCoverageScript -ProfilePath $profilePath -DocsPath $docsPath -Strict 2>&1 } |
                Should -Throw -ExpectedMessage '*Documentation coverage check failed with 1 blocking issue*'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'resolves relative fixture paths from the repository root in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageRelativeInProcess'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null
        $relativeProfilePath = [System.IO.Path]::GetRelativePath($script:TestRepoRoot, $profilePath)
        $relativeDocsPath = [System.IO.Path]::GetRelativePath($script:TestRepoRoot, $docsPath)

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:CheckDocCoverageScript -ProfilePath $relativeProfilePath -DocsPath $relativeDocsPath 2>&1 |
                Out-String

            $output | Should -Match 'Documentation coverage check completed'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'summarizes more than twenty unresolved dynamic registrations in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageManyDynamic'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null
        $registrations = 1..21 | ForEach-Object {
            "Set-AgentModeFunction -Name 'Get-UndocumentedDynamic$_' -Body { 'dynamic' }"
        }
        Set-Content -LiteralPath (Join-Path $profilePath 'dynamic.ps1') -Value $registrations -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:CheckDocCoverageScript -ProfilePath $profilePath -DocsPath $docsPath 2>&1 |
                Out-String

            $output | Should -Match 'and 1 more'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'summarizes multiple truncated documentation gap lists in-process' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageManyGaps'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null

        $fixtureContent = [System.Collections.Generic.List[string]]::new()
        foreach ($index in 1..21) {
            $fixtureContent.Add(@"
<#
.SYNOPSIS
    Documented fixture function $index.
.DESCRIPTION
    Exercises missing markdown list truncation.
#>
function Get-MissingMarkdownFixture$index {
    'ok'
}

Set-AgentModeFunction -Name 'Get-ParserGapFixture$index' -Body {
    <#
    .SYNOPSIS
        Dynamic fixture function $index.
    .DESCRIPTION
        Exercises parser gap list truncation.
    #>
    'dynamic'
}
"@)
        }
        Set-Content -LiteralPath (Join-Path $profilePath 'many-gaps.ps1') -Value $fixtureContent -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:CheckDocCoverageScript -ProfilePath $profilePath -DocsPath $docsPath 2>&1 |
                Out-String -Width 4096

            $output | Should -Match 'Dynamic registrations without resolvable help'
            $output | Should -Match 'Missing markdown files:'
            ([regex]::Matches($output, '\.\.\. and 1 more')).Count | Should -Be 2
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'Emits a JSON coverage report without strict validation failures' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageJsonChild'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @(
            '-ProfilePath', $profilePath,
            '-DocsPath', $docsPath,
            '-Json'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DocumentedFunctionCount|documentation coverage report emitted as JSON'
    }

    It 'Completes in summary mode without requiring -Strict' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageSummaryChild'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath, $docsPath -Force | Out-Null

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @(
            '-ProfilePath', $profilePath,
            '-DocsPath', $docsPath
        )

        $result.Output | Should -Match 'Documentation coverage summary|Documented functions'
        $result.ExitCode | Should -BeIn @(0, 1)
    }

    It 'Fails in strict mode when documented functions lack generated markdown files' {
        $fixtureRoot = New-TestTempDirectory -Prefix 'DocCoverageStrict'
        $profilePath = Join-Path $fixtureRoot 'profile.d'
        $docsPath = Join-Path $fixtureRoot 'docs' 'api'
        New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
        New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $profilePath '00-fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function for strict documentation coverage tests.
.DESCRIPTION
    Detailed description for fixture.
#>
function Get-DocCoverageStrictFixture {
    'ok'
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @(
                '-ProfilePath', $profilePath,
                '-DocsPath', $docsPath,
                '-Strict'
            )

            $result.ExitCode | Should -Be 1
            # Invoke-TestScriptFile merges streams into Output; Exit-WithCode text may vary by host capture.
            [string]$result.Output | Should -Match 'Missing markdown|blocking issue|Documentation coverage check failed|Exit-WithCode|blocking issue\(s\)'
    }
}
