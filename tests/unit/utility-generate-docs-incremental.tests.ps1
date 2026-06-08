<#
tests/unit/utility-generate-docs-incremental.tests.ps1
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DocsModulesPath = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'modules'
    $script:GenerateDocsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-docs.ps1'
}

Describe 'Incremental documentation generation' {
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
