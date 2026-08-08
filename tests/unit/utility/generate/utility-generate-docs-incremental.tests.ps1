<#
tests/unit/utility-generate-docs-incremental.tests.ps1
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
    $script:DocsModulesPath = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'modules'
    $script:GenerateDocsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-docs.ps1'
}

Describe 'Incremental documentation generation' {
    It 'covers dry-run diagnostics without writing documentation or removing legacy files' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsDryRunProfile'
        $outputRoot = New-TestTempDirectory -Prefix 'GenerateDocsDryRunOutput'
        $outputDir = Join-Path $outputRoot 'api'
        $fixturePath = Join-Path $profileDir 'fixture.ps1'
        $legacyDoc = Join-Path $outputRoot 'LegacyCommand.md'
        Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Dry-run fixture function.
#>
function Get-DryRunFixture {
    'ok'
}

Set-Alias -Name dry-run-fixture -Value Get-DryRunFixture
'@ -Encoding UTF8
        Set-Content -LiteralPath $legacyDoc -Value '# Legacy command' -Encoding UTF8

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '2'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:GenerateDocsScript -DryRun -ProfilePath $profileDir -OutputPath $outputDir -Verbose 4>&1
            $outputText = $output | Out-String

            $outputText | Should -Match 'DRY RUN'
            Test-Path -LiteralPath $outputDir | Should -BeFalse
            Test-Path -LiteralPath $legacyDoc | Should -BeTrue
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'generates function and alias docs and removes stale and legacy documentation' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsCleanupProfile'
        $outputRoot = New-TestTempDirectory -Prefix 'GenerateDocsCleanupOutput'
        $outputDir = Join-Path $outputRoot 'api'
        $functionsDir = Join-Path $outputDir 'functions'
        $aliasesDir = Join-Path $outputDir 'aliases'
        $fixturePath = Join-Path $profileDir 'fixture.ps1'
        $legacyDoc = Join-Path $outputRoot 'LegacyCommand.md'
        New-Item -ItemType Directory -Path $functionsDir, $aliasesDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $functionsDir 'Stale-Function.md') -Value '# stale' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $aliasesDir 'stale-alias.md') -Value '# stale' -Encoding UTF8
        Set-Content -LiteralPath $legacyDoc -Value '# legacy' -Encoding UTF8
        Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Cleanup fixture function.
#>
function Get-CleanupFixture {
    'ok'
}

Set-Alias -Name cleanup-fixture -Value Get-CleanupFixture
'@ -Encoding UTF8

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '3'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir -Verbose 4>&1
            $outputText = $output | Out-String

            Test-Path -LiteralPath (Join-Path $functionsDir 'Get-CleanupFixture.md') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $aliasesDir 'cleanup-fixture.md') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $functionsDir 'Stale-Function.md') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $aliasesDir 'stale-alias.md') | Should -BeFalse
            Test-Path -LiteralPath $legacyDoc | Should -BeFalse
            $outputText | Should -Match 'Generated documentation for 1 functions and 1 aliases'
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'reports partial generation failures when an output subdirectory is unusable' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsFailureProfile'
        $outputDir = New-TestTempDirectory -Prefix 'GenerateDocsFailureOutput'
        $fixturePath = Join-Path $profileDir 'fixture.ps1'
        $functionsDir = Join-Path $outputDir 'functions'
        New-Item -ItemType Directory -Path (Join-Path $functionsDir 'Get-GenerationFailureFixture.md') -Force | Out-Null
        Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Failure fixture function.
#>
function Get-GenerationFailureFixture {
    'ok'
}
'@ -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            {
                & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir 2>&1
            } | Should -Throw -ExpectedMessage '*Documentation generation failed in 1 step*'

            Test-Path -LiteralPath (Join-Path $outputDir 'README.md') | Should -BeTrue
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'handles an empty function collection without creating an output directory' {
        Import-Module (Join-Path $script:DocsModulesPath 'DocGenerator.psm1') -DisableNameChecking -Force
        $outputDir = Join-Path (New-TestTempDirectory -Prefix 'EmptyFunctionDocs') 'functions'
        $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
        $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
        $documentedNames = [System.Collections.Generic.List[string]]::new()

        { Write-FunctionDocumentation -Functions $functions -Aliases $aliases -DocsPath $outputDir -DocumentedCommandNames $documentedNames } |
            Should -Not -Throw
        Test-Path -LiteralPath $outputDir | Should -BeFalse
    }

    It 'returns typed empty collections when a profile file has no documented commands' {
        Remove-Module Doc* -ErrorAction SilentlyContinue
        Import-Module (Join-Path $script:DocsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

        $profileDir = New-TestTempDirectory -Prefix 'IncrementalEmptyProfile'
        $fixturePath = Join-Path $profileDir 'empty.ps1'
        Set-Content -LiteralPath $fixturePath -Value '$value = 1' -Encoding UTF8

        $parsed = Get-DocumentedCommands -ProfilePath $profileDir -Files @($fixturePath)

        $parsed.Functions.GetType().FullName | Should -Match '^System\.Collections\.Generic\.List'
        $parsed.Aliases.GetType().FullName | Should -Match '^System\.Collections\.Generic\.List'
        $parsed.Functions.Count | Should -Be 0
        $parsed.Aliases.Count | Should -Be 0
    }

    It 'parses only requested profile files when -Files is supplied' {
        Remove-Module Doc* -ErrorAction SilentlyContinue
        Import-Module (Join-Path $script:DocsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

        $profileDir = New-TestTempDirectory -Prefix 'IncrementalFilesProfile'
        $fileA = Join-Path $profileDir 'a.ps1'
        $fileB = Join-Path $profileDir 'b.ps1'
        Set-Content -LiteralPath $fileA -Value @'
<#
.SYNOPSIS
    Function A.
#>
function Get-IncrementalDocA { }
'@ -Encoding UTF8
        Set-Content -LiteralPath $fileB -Value @'
<#
.SYNOPSIS
    Function B.
#>
function Get-IncrementalDocB { }
'@ -Encoding UTF8

        $parsed = Get-DocumentedCommands -ProfilePath $profileDir -Files @($fileA)
        @($parsed.Functions | Where-Object { $_.Name -eq 'Get-IncrementalDocA' }) | Should -HaveCount 1
        @($parsed.Functions | Where-Object { $_.Name -eq 'Get-IncrementalDocB' }) | Should -HaveCount 0
    }

    It 'skips markdown writes on a second incremental run when sources are unchanged' {
        $profileDir = New-TestTempDirectory -Prefix 'IncrementalRunProfile'
        $outputDir = New-TestTempDirectory -Prefix 'IncrementalRunOutput'
        $fixturePath = Join-Path $profileDir 'fixture.ps1'
        Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Fixture function.
#>
function Get-IncrementalFixture {
    'ok'
}
'@ -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir -Incremental 2>&1 | Out-Null
            $functionDoc = Join-Path $outputDir 'functions' 'Get-IncrementalFixture.md'
            Test-Path -LiteralPath $functionDoc | Should -Be $true
            $firstWrite = (Get-Item -LiteralPath $functionDoc).LastWriteTimeUtc

            Start-Sleep -Seconds 1
            $secondOutput = & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir -Incremental 2>&1
            ($secondOutput | Out-String) | Should -Match 'No documentation changes detected'
            $secondWrite = (Get-Item -LiteralPath $functionDoc).LastWriteTimeUtc
            $secondWrite | Should -Be $firstWrite
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'regenerates docs for changed sources on incremental runs' {
        $profileDir = New-TestTempDirectory -Prefix 'IncrementalChangeProfile'
        $outputDir = New-TestTempDirectory -Prefix 'IncrementalChangeOutput'
        $fixturePath = Join-Path $profileDir 'fixture.ps1'
        Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Original synopsis.
#>
function Get-IncrementalChanged {
    'v1'
}
'@ -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir -Incremental 2>&1 | Out-Null
            $functionDoc = Join-Path $outputDir 'functions' 'Get-IncrementalChanged.md'
            (Get-Content -LiteralPath $functionDoc -Raw) | Should -Match 'Original synopsis'

            Set-Content -LiteralPath $fixturePath -Value @'
<#
.SYNOPSIS
    Updated synopsis.
#>
function Get-IncrementalChanged {
    'v2'
}
'@ -Encoding UTF8

            & $script:GenerateDocsScript -ProfilePath $profileDir -OutputPath $outputDir -Incremental 2>&1 | Out-Null
            (Get-Content -LiteralPath $functionDoc -Raw) | Should -Match 'Updated synopsis'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }
}
