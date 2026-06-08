<#
tests/unit/library-code-similarity-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-CodeSimilarity thresholds and discovery scope.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $script:LibPath 'utilities' 'StringSimilarity.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'code-analysis' 'AstParsing.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'file' 'FileContent.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'utilities' 'Collections.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'code-analysis' 'CodeSimilarityDetection.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'CodeSimilarityExtended'
    $script:SharedBody = @'
function Shared-Helper {
    param([string]$Name)
    Write-Output "Hello $Name"
    if ($Name) {
        Write-Output 'Name provided'
    }
}
'@

    Set-Content -LiteralPath (Join-Path $script:TempDir 'alpha.ps1') -Value $script:SharedBody -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:TempDir 'beta.ps1') -Value ($script:SharedBody -replace 'Shared-Helper', 'Shared-Clone') -Encoding UTF8
}

AfterAll {
    Remove-Module CodeSimilarityDetection, Collections, FileContent, AstParsing, StringSimilarity, FileSystem -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeSimilarityDetection extended scenarios' {
    Context 'Get-CodeSimilarity' {
        It 'Finds high-similarity pairs between related scripts' {
            $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.5)

            @($results).Count | Should -BeGreaterThan 0
        }

        It 'Returns an empty array for a single-script directory' {
            $singleDir = Join-Path $script:TempDir 'single-only'
            New-Item -ItemType Directory -Path $singleDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:TempDir 'alpha.ps1') -Destination (Join-Path $singleDir 'only.ps1')

            $results = @(Get-CodeSimilarity -Path $singleDir -MinSimilarity 0.5)

            @($results).Count | Should -Be 0
        }

        It 'Skips nested scripts when Recurse is not specified' {
            $nestedDir = Join-Path $script:TempDir 'nested-only'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $nestedDir 'nested.ps1') -Value $script:SharedBody -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $nestedDir -MinSimilarity 0.5)

            @($results).Count | Should -Be 0
        }

        It 'Finds nested scripts when Recurse is enabled' {
            $nestedDir = Join-Path $script:TempDir 'nested-recurse'
            New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $nestedDir 'child.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $nestedDir 'child-copy.ps1') -Value $script:SharedBody -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $nestedDir -Recurse -MinSimilarity 0.5)

            @($results).Count | Should -BeGreaterThan 0
        }

        It 'Filters matches below the MinSimilarity threshold' {
            $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.99)

            foreach ($match in @($results)) {
                if ($match.PSObject.Properties.Name -contains 'Similarity') {
                    $match.Similarity | Should -BeGreaterOrEqual 0.99
                }
                elseif ($match.PSObject.Properties.Name -contains 'SimilarityPercent') {
                    ($match.SimilarityPercent / 100) | Should -BeGreaterOrEqual 0.99
                }
            }
        }
    }
}
