<#
tests/unit/library-file-filtering-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FileFiltering string inputs and pipeline behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileFiltering.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'FileFilteringExtended'
    $script:KeepFile = Join-Path $script:TempRoot 'keep.ps1'
    $script:TestTreeFile = Join-Path $script:TempRoot 'tests/nested/sample.tests.ps1'
    $script:GitTreeFile = Join-Path $script:TempRoot '.git/config'
    $script:NodeTreeFile = Join-Path $script:TempRoot 'node_modules/pkg/index.js'

    New-Item -ItemType Directory -Path (Split-Path $script:TestTreeFile) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $script:GitTreeFile) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $script:NodeTreeFile) -Force | Out-Null
    Set-Content -LiteralPath $script:KeepFile -Value '# keep' -Encoding UTF8
    Set-Content -LiteralPath $script:TestTreeFile -Value '# test' -Encoding UTF8
    Set-Content -LiteralPath $script:GitTreeFile -Value 'git' -Encoding UTF8
    Set-Content -LiteralPath $script:NodeTreeFile -Value 'js' -Encoding UTF8
}

AfterAll {
    Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileFiltering extended scenarios' {
    Context 'Filter-Files' {
        It 'Accepts plain string paths from the pipeline' {
            $filtered = @(
                $script:KeepFile,
                $script:TestTreeFile,
                $script:GitTreeFile,
                $script:NodeTreeFile
            ) | Filter-Files -ExcludeTests:$false

            @($filtered).Count | Should -BeGreaterThan 0
            $filtered | Should -Contain $script:KeepFile
            $filtered | Should -Not -Contain $script:GitTreeFile
            $filtered | Should -Not -Contain $script:NodeTreeFile
        }

        It 'Returns a single-element result without losing the lone entry' {
            $filtered = Filter-Files -Files @($script:KeepFile) -ExcludeTests:$false -ExcludeGit:$false -ExcludeNodeModules:$false

            @($filtered).Count | Should -Be 1
            @($filtered)[0] | Should -Be $script:KeepFile
        }

        It 'Honors ExcludeTests:$false while still excluding git and node_modules by default' {
            $filtered = @($script:KeepFile, $script:TestTreeFile, $script:GitTreeFile) | Filter-Files -ExcludeTests:$false

            $filtered | Should -Contain $script:TestTreeFile
            $filtered | Should -Not -Contain $script:GitTreeFile
        }
    }

    Context 'Get-DefaultExclusionPatterns' {
        It 'Matches forward-slash paths on Unix-style layouts' {
            $patterns = Get-DefaultExclusionPatterns

            '/tmp/project/tests/unit/sample.tests.ps1' | Should -Match $patterns.Tests
            '/tmp/project/.git/config' | Should -Match $patterns.Git
            '/tmp/project/node_modules/pkg/index.js' | Should -Match $patterns.NodeModules
        }
    }
}
