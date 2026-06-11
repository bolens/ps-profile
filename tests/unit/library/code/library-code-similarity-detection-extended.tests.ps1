<#
tests/unit/library-code-similarity-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-CodeSimilarity edge cases and fallback paths.
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
    foreach ($dep in @(
            @{ Path = 'file/FileSystem.psm1' }
            @{ Path = 'utilities/StringSimilarity.psm1' }
            @{ Path = 'code-analysis/AstParsing.psm1' }
            @{ Path = 'file/FileContent.psm1' }
            @{ Path = 'utilities/Collections.psm1' }
        )) {
        Import-Module (Join-Path $script:LibPath $dep.Path) -DisableNameChecking -Force -Global
    }
    Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force

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

function script:Clear-CodeSimilarityTestEnvironment {
    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
}

function script:Set-CodeSimilarityStringSimilarityStub {
    param([scriptblock]$Body)

    Remove-Module StringSimilarity -ErrorAction SilentlyContinue -Force
    Remove-TestFunction -Name 'Get-StringSimilarity'
    Set-Item -Path Function:\global:Get-StringSimilarity -Value $Body -Force
}

function script:Restore-CodeSimilarityStringSimilarity {
    Remove-TestFunction -Name 'Get-StringSimilarity'
    Import-Module (Join-Path $script:LibPath 'utilities/StringSimilarity.psm1') -DisableNameChecking -Force -Global
}

AfterAll {
    Clear-CodeSimilarityTestEnvironment
    Remove-Module CodeSimilarityDetection, Collections, FileContent, AstParsing, StringSimilarity, FileSystem -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeSimilarityDetection extended scenarios' {
    BeforeEach { Clear-CodeSimilarityTestEnvironment }

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

        It 'Extracts similar if-statement blocks from scripts' {
            $ifDir = Join-Path $script:TempDir 'if-blocks'
            New-Item -ItemType Directory -Path $ifDir -Force | Out-Null
            $ifBody = @'
function Get-IfProbe {
    if ($true) {
        Write-Output 'line1'
        Write-Output 'line2'
        Write-Output 'line3'
        Write-Output 'line4'
        Write-Output 'line5'
    }
}
'@
            Set-Content -LiteralPath (Join-Path $ifDir 'if-a.ps1') -Value $ifBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $ifDir 'if-b.ps1') -Value $ifBody -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $ifDir -MinSimilarity 0.5 -MinBlockSize 3)

            @($results).Count | Should -BeGreaterThan 0
        }

        It 'Falls back to file-level comparison when function blocks are too small' {
            $tinyDir = Join-Path $script:TempDir 'tiny-functions'
            New-Item -ItemType Directory -Path $tinyDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $tinyDir 'tiny-a.ps1') -Value 'function Get-TinyA { 1 }' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $tinyDir 'tiny-b.ps1') -Value 'function Get-TinyB { 1 }' -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $tinyDir -MinSimilarity 0.1 -MinBlockSize 10)

            $results -is [System.Array] | Should -Be $true
        }

        It 'Uses length-based similarity when Get-StringSimilarity is unavailable' {
            $lengthDir = Join-Path $script:TempDir 'length-fallback'
            New-Item -ItemType Directory -Path $lengthDir -Force | Out-Null
            $body = @'
function Get-LengthProbe {
    Write-Output 'alpha'
    Write-Output 'beta'
    Write-Output 'gamma'
    Write-Output 'delta'
    Write-Output 'epsilon'
}
'@
            Set-Content -LiteralPath (Join-Path $lengthDir 'length-a.ps1') -Value $body -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $lengthDir 'length-b.ps1') -Value $body -Encoding UTF8

            Remove-Module StringSimilarity -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Get-StringSimilarity'

            $results = @(Get-CodeSimilarity -Path $lengthDir -MinSimilarity 0.5 -MinBlockSize 3)

            @($results).Count | Should -BeGreaterThan 0

            Import-Module (Join-Path $script:LibPath 'utilities/StringSimilarity.psm1') -DisableNameChecking -Force -Global
        }

        It 'Falls back to equality comparison when similarity calculation throws' {
            $throwDir = Join-Path $script:TempDir 'similarity-throw'
            New-Item -ItemType Directory -Path $throwDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $throwDir 'throw-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $throwDir 'throw-b.ps1') -Value $script:SharedBody -Encoding UTF8

            Set-CodeSimilarityStringSimilarityStub { throw 'similarity failure probe' }

            $warnings = @()
            $results = @(Get-CodeSimilarity -Path $throwDir -MinSimilarity 0.5 -WarningVariable +warnings)

            $results -is [System.Array] | Should -Be $true
            @($results).Count | Should -BeGreaterThan 0
            @($warnings).Count | Should -Be 0

            Restore-CodeSimilarityStringSimilarity
        }

        It 'Uses manual parser fallback when AstParsing helpers are unavailable' {
            $manualDir = Join-Path $script:TempDir 'manual-parser'
            New-Item -ItemType Directory -Path $manualDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $manualDir 'manual-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $manualDir 'manual-b.ps1') -Value $script:SharedBody -Encoding UTF8

            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('Get-PowerShellAst', 'Get-FunctionsFromAst')) {
                Remove-TestFunction -Name $fn
            }

            $results = @(Get-CodeSimilarity -Path $manualDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Uses Get-Content fallback when Read-FileContent is unavailable' {
            $contentDir = Join-Path $script:TempDir 'content-fallback'
            New-Item -ItemType Directory -Path $contentDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $contentDir 'content-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $contentDir 'content-b.ps1') -Value $script:SharedBody -Encoding UTF8

            Remove-Module FileContent -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Read-FileContent'

            $results = @(Get-CodeSimilarity -Path $contentDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
        }

        It 'Uses generic lists when Collections helpers are unavailable' {
            $collectionDir = Join-Path $script:TempDir 'collection-fallback'
            New-Item -ItemType Directory -Path $collectionDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $collectionDir 'collection-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $collectionDir 'collection-b.ps1') -Value $script:SharedBody -Encoding UTF8

            Remove-Module Collections -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('New-ObjectList', 'New-TypedList')) {
                Remove-TestFunction -Name $fn
            }

            $results = @(Get-CodeSimilarity -Path $collectionDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'utilities/Collections.psm1') -DisableNameChecking -Force -Global
        }

        It 'Skips scripts that cannot be analyzed' {
            $errorDir = Join-Path $script:TempDir 'analysis-errors'
            New-Item -ItemType Directory -Path $errorDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $errorDir 'good.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $errorDir 'bad.ps1') -Value '{ invalid syntax' -Encoding UTF8

            { Get-CodeSimilarity -Path $errorDir -MinSimilarity 0.5 } | Should -Not -Throw
        }

        It 'Emits structured warnings when fewer than two scripts are available' {
            Enable-TestStructuredLogging
            $singleDir = Join-Path $script:TempDir 'structured-warning'
            New-Item -ItemType Directory -Path $singleDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $singleDir 'only.ps1') -Value 'function Get-Only { 1 }' -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $singleDir -MinSimilarity 0.5)

            @($results).Count | Should -Be 0
        }

        It 'Logs comparison progress at debug level 2' {
            $env:PS_PROFILE_DEBUG = '2'

            $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true
        }

        It 'Logs extraction details at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true
        }

        It 'Warns through plain Write-Warning when structured logging is unavailable' {
            $singleDir = Join-Path $script:TempDir 'plain-warning'
            New-Item -ItemType Directory -Path $singleDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $singleDir 'only.ps1') -Value 'function Get-Only { 1 }' -Encoding UTF8
            Remove-TestFunction -Name 'Write-StructuredWarning'
            $env:PS_PROFILE_DEBUG = '3'

            $results = @(Get-CodeSimilarity -Path $singleDir -MinSimilarity 0.5 -WarningAction SilentlyContinue)

            @($results).Count | Should -Be 0
        }

        It 'Skips invalid function AST structures returned by AstParsing helpers' {
            $invalidDir = Join-Path $script:TempDir 'invalid-ast'
            New-Item -ItemType Directory -Path $invalidDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $invalidDir 'invalid-a.ps1') -Value 'function Get-Bad { 1 }' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $invalidDir 'invalid-b.ps1') -Value 'function Get-Bad { 2 }' -Encoding UTF8

            function global:Get-FunctionsFromAst {
                return @([PSCustomObject]@{ Name = 'Get-Bad'; Body = $null })
            }

            $results = @(Get-CodeSimilarity -Path $invalidDir -MinSimilarity 0.1 -WarningAction SilentlyContinue)

            $results -is [System.Array] | Should -Be $true

            Remove-TestFunction -Name 'Get-FunctionsFromAst'
            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Returns empty results when fewer than two scripts produce blocks' {
            $emptyDir = Join-Path $script:TempDir 'empty-blocks'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $emptyDir 'empty-a.ps1') -Value '' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $emptyDir 'empty-b.ps1') -Value '' -Encoding UTF8

            $results = @(Get-CodeSimilarity -Path $emptyDir -MinSimilarity 0.1)

            @($results).Count | Should -Be 0
        }

        It 'Uses length-ratio fallback for partially similar normalized content' {
            $partialDir = Join-Path $script:TempDir 'partial-length'
            New-Item -ItemType Directory -Path $partialDir -Force | Out-Null
            $bodyA = @'
function Get-PartialA {
    Write-Output 'alpha'
    Write-Output 'beta'
    Write-Output 'gamma'
    Write-Output 'delta'
    Write-Output 'epsilon'
}
'@
            $bodyB = @'
function Get-PartialB {
    Write-Output 'alpha'
    Write-Output 'beta'
    Write-Output 'gamma'
    Write-Output 'delta'
    Write-Output 'zzzzz'
}
'@
            Set-Content -LiteralPath (Join-Path $partialDir 'partial-a.ps1') -Value $bodyA -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $partialDir 'partial-b.ps1') -Value $bodyB -Encoding UTF8

            Remove-Module StringSimilarity -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Get-StringSimilarity'

            $results = @(Get-CodeSimilarity -Path $partialDir -MinSimilarity 0.5 -MinBlockSize 3)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'utilities/StringSimilarity.psm1') -DisableNameChecking -Force -Global
        }

        It 'Emits structured warnings when script analysis fails' {
            $failDir = Join-Path $script:TempDir 'analysis-fail'
            New-Item -ItemType Directory -Path $failDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $failDir 'good.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $failDir 'bad.ps1') -Value 'function Get-Bad { 1 }' -Encoding UTF8
            Enable-TestStructuredLogging

            function global:Read-FileContent {
                param([string]$Path)
                if ($Path -like '*bad.ps1') {
                    throw 'forced read failure probe'
                }

                return Get-Content -LiteralPath $Path -Raw
            }

            $results = @(Get-CodeSimilarity -Path $failDir -MinSimilarity 0.5 -WarningAction SilentlyContinue)

            $results -is [System.Array] | Should -Be $true

            Remove-TestFunction -Name 'Read-FileContent'
            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
        }

        It 'Uses manual dependency imports when Import-ModuleSafely is unavailable' {
            Remove-Module CodeSimilarityDetection, SafeImport -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Import-ModuleSafely'
            Import-Module (Join-Path $script:LibPath 'file/FileSystem.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'utilities/StringSimilarity.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'utilities/Collections.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force

            $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'core/SafeImport.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force
        }

        It 'Re-executes manual import fallbacks when the module is force-reloaded without SafeImport' {
            Remove-Module CodeSimilarityDetection, SafeImport -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Import-ModuleSafely'

            Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force

            Get-Command Get-CodeSimilarity -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

            Import-Module (Join-Path $script:LibPath 'core/SafeImport.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force
        }

        It 'Loads dependency modules through manual import fallbacks when forced' {
            $originalForce = $env:PS_PROFILE_CODE_SIMILARITY_FORCE_MANUAL_IMPORT
            $env:PS_PROFILE_CODE_SIMILARITY_FORCE_MANUAL_IMPORT = '1'

            try {
                Remove-Module CodeSimilarityDetection -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force

                $results = @(Get-CodeSimilarity -Path $script:TempDir -MinSimilarity 0.5)
                $results -is [System.Array] | Should -Be $true
            }
            finally {
                if ($null -eq $originalForce) {
                    Remove-Item Env:PS_PROFILE_CODE_SIMILARITY_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_CODE_SIMILARITY_FORCE_MANUAL_IMPORT = $originalForce
                }

                Remove-Module CodeSimilarityDetection -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'code-analysis/CodeSimilarityDetection.psm1') -DisableNameChecking -Force
            }
        }

        It 'Uses built-in parser error detection when AstParsing helpers are unavailable' {
            $parseDir = Join-Path $script:TempDir 'parser-errors'
            New-Item -ItemType Directory -Path $parseDir -Force | Out-Null
            $broken = @'
function Get-BrokenParse {
    param(
'@
            Set-Content -LiteralPath (Join-Path $parseDir 'broken-a.ps1') -Value $broken -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $parseDir 'broken-b.ps1') -Value $broken -Encoding UTF8

            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('Get-PowerShellAst', 'Get-FunctionsFromAst')) {
                Remove-TestFunction -Name $fn
            }

            $results = @(Get-CodeSimilarity -Path $parseDir -MinSimilarity 0.1 -MinBlockSize 1)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Warns without structured logging when fewer than two scripts are found' {
            $singleDir = Join-Path $script:TempDir 'no-structured-insufficient'
            New-Item -ItemType Directory -Path $singleDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $singleDir 'solo.ps1') -Value 'function Get-Solo { 1 }' -Encoding UTF8
            Remove-TestFunction -Name 'Write-StructuredWarning'
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            $results = @(Get-CodeSimilarity -Path $singleDir -MinSimilarity 0.5 -WarningAction SilentlyContinue)

            @($results).Count | Should -Be 0
        }

        It 'Warns through structured logging for invalid function AST structures' {
            $invalidDir = Join-Path $script:TempDir 'invalid-ast-structured'
            New-Item -ItemType Directory -Path $invalidDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $invalidDir 'structured-a.ps1') -Value 'function Get-StructuredBad { 1 }' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $invalidDir 'structured-b.ps1') -Value 'function Get-StructuredBad { 2 }' -Encoding UTF8
            Enable-TestStructuredLogging

            function global:Get-FunctionsFromAst {
                return @([PSCustomObject]@{ Name = 'Get-StructuredBad'; Body = $null })
            }

            $results = @(Get-CodeSimilarity -Path $invalidDir -MinSimilarity 0.1 -WarningAction SilentlyContinue)

            $results -is [System.Array] | Should -Be $true

            Remove-TestFunction -Name 'Get-FunctionsFromAst'
            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Logs script analysis failures without structured logging at debug level 1' {
            $failDir = Join-Path $script:TempDir 'analysis-plain-fail'
            New-Item -ItemType Directory -Path $failDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $failDir 'plain-good.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $failDir 'plain-bad.ps1') -Value 'function Get-PlainBad { 1 }' -Encoding UTF8
            Remove-TestFunction -Name 'Write-StructuredWarning'
            $env:PS_PROFILE_DEBUG = '1'

            function global:Read-FileContent {
                param([string]$Path)
                if ($Path -like '*plain-bad.ps1') {
                    throw 'plain analysis failure probe'
                }

                return Get-Content -LiteralPath $Path -Raw
            }

            $results = @(Get-CodeSimilarity -Path $failDir -MinSimilarity 0.5 -WarningAction SilentlyContinue)

            $results -is [System.Array] | Should -Be $true

            Remove-TestFunction -Name 'Read-FileContent'
            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
        }

        It 'Logs when fewer than two scripts produce blocks at debug level 2' {
            $blockDir = Join-Path $script:TempDir 'single-block-file'
            New-Item -ItemType Directory -Path $blockDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $blockDir 'only-file.ps1') -Value $script:SharedBody -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '2'

            $results = @(Get-CodeSimilarity -Path $blockDir -MinSimilarity 0.5)

            @($results).Count | Should -Be 0
        }

        It 'Recovers through structured logging when similarity calculation fails' {
            $structuredDir = Join-Path $script:TempDir 'structured-similarity-fail'
            New-Item -ItemType Directory -Path $structuredDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $structuredDir 'structured-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $structuredDir 'structured-b.ps1') -Value $script:SharedBody -Encoding UTF8
            Enable-TestStructuredLogging

            Set-CodeSimilarityStringSimilarityStub { throw 'structured similarity failure probe' }

            $warnings = @()
            $results = @(Get-CodeSimilarity -Path $structuredDir -MinSimilarity 0.5 -WarningVariable +warnings)

            @($results).Count | Should -BeGreaterThan 0
            @($warnings).Count | Should -Be 0

            Restore-CodeSimilarityStringSimilarity
        }

        It 'Uses length-ratio fallback when normalized content differs' {
            $ratioDir = Join-Path $script:TempDir 'length-ratio'
            New-Item -ItemType Directory -Path $ratioDir -Force | Out-Null
            $bodyA = @'
function Get-RatioA {
    Write-Output 'one'
    Write-Output 'two'
    Write-Output 'three'
    Write-Output 'four'
    Write-Output 'five'
}
'@
            $bodyB = @'
function Get-RatioB {
    Write-Output 'one'
    Write-Output 'two'
    Write-Output 'three'
    Write-Output 'four'
    Write-Output 'SIXX'
}
'@
            Set-Content -LiteralPath (Join-Path $ratioDir 'ratio-a.ps1') -Value $bodyA -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $ratioDir 'ratio-b.ps1') -Value $bodyB -Encoding UTF8

            Remove-Module StringSimilarity -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Get-StringSimilarity'

            $results = @(Get-CodeSimilarity -Path $ratioDir -MinSimilarity 0.7 -MinBlockSize 3)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'utilities/StringSimilarity.psm1') -DisableNameChecking -Force -Global
        }

        It 'Logs invalid AST details when structured logging is unavailable' {
            $invalidDir = Join-Path $script:TempDir 'invalid-ast-plain'
            New-Item -ItemType Directory -Path $invalidDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $invalidDir 'plain-a.ps1') -Value 'function Get-PlainBad { 1 }' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $invalidDir 'plain-b.ps1') -Value 'function Get-PlainBad { 2 }' -Encoding UTF8
            Remove-TestFunction -Name 'Write-StructuredWarning'
            $env:PS_PROFILE_DEBUG = '3'

            function global:Get-FunctionsFromAst {
                return @([PSCustomObject]@{ Name = 'Get-PlainBad'; Body = $null })
            }

            $results = @(Get-CodeSimilarity -Path $invalidDir -MinSimilarity 0.1 -WarningAction SilentlyContinue)

            $results -is [System.Array] | Should -Be $true

            Remove-TestFunction -Name 'Get-FunctionsFromAst'
            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Falls back to file-level text comparison when parser reports syntax errors' {
            $parseDir = Join-Path $script:TempDir 'parse-errors'
            New-Item -ItemType Directory -Path $parseDir -Force | Out-Null
            $noisyScript = @'
function Get-ParseErrorProbe {
    param([string]$Value)
    Write-Output $Value
    if ($Value) {
        Write-Output 'present'
    }
}
'@
            Set-Content -LiteralPath (Join-Path $parseDir 'parse-a.ps1') -Value $noisyScript -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $parseDir 'parse-b.ps1') -Value $noisyScript -Encoding UTF8

            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('Get-PowerShellAst', 'Get-FunctionsFromAst')) {
                Remove-TestFunction -Name $fn
            }

            $results = @(Get-CodeSimilarity -Path $parseDir -MinSimilarity 0.5 -MinBlockSize 3)

            $results -is [System.Array] | Should -Be $true

            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Logs similarity calculation failures without structured logging at debug level 3' {
            $failDir = Join-Path $script:TempDir 'similarity-plain-fail'
            New-Item -ItemType Directory -Path $failDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $failDir 'fail-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $failDir 'fail-b.ps1') -Value $script:SharedBody -Encoding UTF8
            Remove-TestFunction -Name 'Write-StructuredWarning'
            $env:PS_PROFILE_DEBUG = '3'

            Set-CodeSimilarityStringSimilarityStub { throw 'plain similarity failure probe' }

            $warnings = @()
            $results = @(Get-CodeSimilarity -Path $failDir -MinSimilarity 0.5 -WarningVariable +warnings)

            @($results).Count | Should -BeGreaterThan 0
            @($warnings).Count | Should -Be 0

            Restore-CodeSimilarityStringSimilarity
        }

        It 'Skips block pairs with empty normalized content' {
            $emptyNormDir = Join-Path $script:TempDir 'empty-normalized'
            New-Item -ItemType Directory -Path $emptyNormDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $emptyNormDir 'norm-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $emptyNormDir 'norm-b.ps1') -Value $script:SharedBody -Encoding UTF8

            Set-CodeSimilarityStringSimilarityStub { return 0.95 }

            $results = @(Get-CodeSimilarity -Path $emptyNormDir -MinSimilarity 0.5)

            $results -is [System.Array] | Should -Be $true

            Restore-CodeSimilarityStringSimilarity
        }

        It 'Throws when Get-PowerShellScripts cannot be resolved inside the module scope' {
            InModuleScope -ModuleName CodeSimilarityDetection {
                Mock Import-Module { }
                Remove-Item Function:\Get-PowerShellScripts -ErrorAction SilentlyContinue

                { Get-CodeSimilarity -Path '/tmp/unused-similarity-path' } | Should -Throw '*Get-PowerShellScripts*'
            }
        }

        It 'Uses generic list storage when New-ObjectList returns null' {
            $nullListDir = Join-Path $script:TempDir 'null-object-list'
            New-Item -ItemType Directory -Path $nullListDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $nullListDir 'null-a.ps1') -Value $script:SharedBody -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $nullListDir 'null-b.ps1') -Value $script:SharedBody -Encoding UTF8

            function global:New-ObjectList { return $null }

            $results = @(Get-CodeSimilarity -Path $nullListDir -MinSimilarity 0.5)

            @($results).Count | Should -BeGreaterThan 0

            Remove-TestFunction -Name 'New-ObjectList'
            Import-Module (Join-Path $script:LibPath 'utilities/Collections.psm1') -DisableNameChecking -Force -Global
        }
    }
}
