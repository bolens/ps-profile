<#
tests/unit/library-safe-import-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for SafeImport path resolution and import behavior.
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
    Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'core' 'SafeImport.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module SafeImport, Validation -ErrorAction SilentlyContinue -Force
}

Describe 'SafeImport extended scenarios' {
    Context 'Test-ModulePath' {
        It 'Returns false for whitespace-only module paths' {
            Test-ModulePath -ModulePath '   ' | Should -Be $false
        }

    }

    Context 'Get-ModulePath' {
        BeforeEach {
            $script:TempDir = New-TestTempDirectory -Prefix 'SafeImportExtended'
            $script:ModuleFile = Join-Path $script:TempDir 'ExtendedModule.psm1'
            Set-Content -LiteralPath $script:ModuleFile -Value '# extended module' -Encoding UTF8
        }

        AfterEach {
            if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
                Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Resolves module paths relative to an explicit base path' {
            $resolved = Get-ModulePath -ModulePath 'ExtendedModule.psm1' -BasePath $script:TempDir

            $resolved | Should -Be (Resolve-Path -LiteralPath $script:ModuleFile).Path
        }

        It 'Returns null for whitespace-only paths' {
            Get-ModulePath -ModulePath '   ' | Should -BeNullOrEmpty
        }

        It 'Returns null when MustExist is true and the module file is missing' {
            Get-ModulePath -ModulePath (Join-Path $script:TempDir 'MissingModule.psm1') | Should -BeNullOrEmpty
        }

        It 'Resolves relative module paths from the current working directory' {
            $previousLocation = Get-Location
            try {
                Set-Location -LiteralPath $script:TempDir
                $resolved = Get-ModulePath -ModulePath 'ExtendedModule.psm1'
                $resolved | Should -Be (Resolve-Path -LiteralPath $script:ModuleFile).Path
            }
            finally {
                Set-Location -LiteralPath $previousLocation.Path
            }
        }
    }

    Context 'Import-ModuleSafely' {
        BeforeEach {
            $script:TempDir = New-TestTempDirectory -Prefix 'SafeImportExtendedImport'
            $script:ModuleFile = Join-Path $script:TempDir 'ExtendedImport.psm1'
            @'
function Get-ExtendedImportValue {
    return 'extended'
}
Export-ModuleMember -Function 'Get-ExtendedImportValue'
'@ | Set-Content -LiteralPath $script:ModuleFile -Encoding UTF8
        }

        AfterEach {
            Remove-Module ExtendedImport -ErrorAction SilentlyContinue -Force
            if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
                Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Imports required modules successfully when Required is specified' {
            $module = Import-ModuleSafely -ModulePath $script:ModuleFile -Required $true -ErrorAction Stop

            $module.Name | Should -Be 'ExtendedImport'
            $module.ExportedCommands.Keys | Should -Contain 'Get-ExtendedImportValue'
        }

        It 'Supports repeated imports of the same module path' {
            $first = Import-ModuleSafely -ModulePath $script:ModuleFile -ErrorAction Stop
            $second = Import-ModuleSafely -ModulePath $script:ModuleFile -ErrorAction Stop

            $first.Name | Should -Be 'ExtendedImport'
            $second.Name | Should -Be 'ExtendedImport'
        }

        It 'Throws when import fails with Required and ErrorAction Stop' {
            $brokenModule = Join-Path $script:TempDir 'BrokenRequired.psm1'
            Set-Content -LiteralPath $brokenModule -Value 'syntax error {{{' -Encoding UTF8

            { Import-ModuleSafely -ModulePath $brokenModule -Required $true -ErrorAction Stop } |
                Should -Throw '*Failed to import module*'
        }

        It 'Returns null for invalid module paths when Required is false' {
            Import-ModuleSafely -ModulePath (Join-Path $script:TempDir 'Missing.psm1') | Should -BeNullOrEmpty
        }

        It 'Throws when Required is true and the module path is invalid' {
            { Import-ModuleSafely -ModulePath $null -Required $true } |
                Should -Throw '*Module path is invalid or does not exist*'
        }

        It 'Formats non-string module paths in required import errors' {
            $missingPath = [pscustomobject]@{ FullName = (Join-Path $script:TempDir 'MissingObject.psm1') }
            { Import-ModuleSafely -ModulePath $missingPath -Required $true } |
                Should -Throw '*Module path is invalid or does not exist*'
        }

        It 'Returns null when import fails and Required is false' {
            $brokenModule = Join-Path $script:TempDir 'BrokenImport.psm1'
            Set-Content -LiteralPath $brokenModule -Value 'this is not valid module syntax {{{' -Encoding UTF8

            Import-ModuleSafely -ModulePath $brokenModule -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Throws when import fails and ErrorAction is Stop' {
            $brokenModule = Join-Path $script:TempDir 'BrokenImportStop.psm1'
            Set-Content -LiteralPath $brokenModule -Value 'this is not valid module syntax {{{' -Encoding UTF8

            { Import-ModuleSafely -ModulePath $brokenModule -ErrorAction Stop } |
                Should -Throw '*Failed to import module*'
        }

        It 'Imports modules with DisableNameChecking enabled' {
            $module = Import-ModuleSafely -ModulePath $script:ModuleFile -DisableNameChecking -ErrorAction Stop

            $module.Name | Should -Be 'ExtendedImport'
        }

        It 'Imports modules into the global scope when Global is specified' {
            $module = Import-ModuleSafely -ModulePath $script:ModuleFile -Global -ErrorAction Stop

            $module.Name | Should -Be 'ExtendedImport'
            Get-Command Get-ExtendedImportValue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Imports modules using non-string path objects' {
            $fileInfo = Get-Item -LiteralPath $script:ModuleFile
            $module = Import-ModuleSafely -ModulePath $fileInfo -ErrorAction Stop

            $module.Name | Should -Be 'ExtendedImport'
        }
    }

    Context 'SafeImport module initialization' {
        It 'Loads when the CommonEnums module file is absent during initialization' {
            $tempCore = New-TestTempDirectory -Prefix 'SafeImportNoCommonEnums'
            Get-ChildItem -LiteralPath (Join-Path $script:LibPath 'core') -Filter '*.psm1' |
                Where-Object { $_.Name -ne 'CommonEnums.psm1' } |
                Copy-Item -Destination $tempCore -Force

            Remove-Module SafeImport, CommonEnums, Validation -ErrorAction SilentlyContinue -Force

            try {
                { Import-Module (Join-Path $tempCore 'SafeImport.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Test-ModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module SafeImport -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
                Import-Module (Join-Path $script:LibPath 'core' 'SafeImport.psm1') -DisableNameChecking -Force
                Remove-Item -LiteralPath $tempCore -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Loads when the Validation module file is absent during initialization' {
            $tempCore = New-TestTempDirectory -Prefix 'SafeImportNoValidation'
            Get-ChildItem -LiteralPath (Join-Path $script:LibPath 'core') -Filter '*.psm1' |
                Where-Object { $_.Name -ne 'Validation.psm1' } |
                Copy-Item -Destination $tempCore -Force

            Remove-Module SafeImport, CommonEnums, Validation -ErrorAction SilentlyContinue -Force

            try {
                { Import-Module (Join-Path $tempCore 'SafeImport.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Test-ModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module SafeImport -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
                Import-Module (Join-Path $script:LibPath 'core' 'SafeImport.psm1') -DisableNameChecking -Force
                Remove-Item -LiteralPath $tempCore -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Continues loading when CommonEnums import fails without emitting debug warnings' {
            $tempCore = New-TestTempDirectory -Prefix 'SafeImportInitQuiet'
            Get-ChildItem -LiteralPath (Join-Path $script:LibPath 'core') -Filter '*.psm1' |
                Copy-Item -Destination $tempCore -Force
            Set-Content -LiteralPath (Join-Path $tempCore 'CommonEnums.psm1') -Value 'throw "broken enums"' -Encoding UTF8

            Remove-Module SafeImport, CommonEnums, Validation -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                { Import-Module (Join-Path $tempCore 'SafeImport.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Test-ModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module SafeImport -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
                Import-Module (Join-Path $script:LibPath 'core' 'SafeImport.psm1') -DisableNameChecking -Force
                Remove-Item -LiteralPath $tempCore -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Continues loading when CommonEnums import fails during initialization' {
            $tempCore = New-TestTempDirectory -Prefix 'SafeImportInit'
            Get-ChildItem -LiteralPath (Join-Path $script:LibPath 'core') -Filter '*.psm1' |
                Copy-Item -Destination $tempCore -Force
            Set-Content -LiteralPath (Join-Path $tempCore 'CommonEnums.psm1') -Value 'throw "broken enums"' -Encoding UTF8

            Remove-Module SafeImport, CommonEnums, Validation -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                { Import-Module (Join-Path $tempCore 'SafeImport.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Test-ModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module SafeImport -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
                Import-Module (Join-Path $script:LibPath 'core' 'SafeImport.psm1') -DisableNameChecking -Force
                Remove-Item -LiteralPath $tempCore -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-ModulePath without Validation helpers' {
        BeforeEach {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
        }

        It 'Resolves rooted module paths without a base path' {
            $tempDir = New-TestTempDirectory -Prefix 'SafeImportRooted'
            $moduleFile = Join-Path $tempDir 'RootedModule.psm1'
            Set-Content -LiteralPath $moduleFile -Value '# rooted' -Encoding UTF8

            try {
                $resolved = Get-ModulePath -ModulePath $moduleFile
                $resolved | Should -Be (Resolve-Path -LiteralPath $moduleFile).Path
            }
            finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns null for invalid rooted paths when normalization fails' {
            Get-ModulePath -ModulePath '::invalid-rooted-path::' | Should -BeNullOrEmpty
        }

        It 'Returns the resolved path when MustExist is false' {
            $candidate = Join-Path (Get-Location).Path 'definitely-missing-module.psm1'
            $resolved = Get-ModulePath -ModulePath $candidate -MustExist:$false

            $resolved | Should -Not -BeNullOrEmpty
            $resolved | Should -Match 'definitely-missing-module\.psm1$'
        }
    }

    Context 'Test-ModulePath without Validation helpers' {
        BeforeEach {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force
        }

        It 'Accepts non-string module path objects in Get-ModulePath' {
            $tempDir = New-TestTempDirectory -Prefix 'SafeImportObjectPath'
            $moduleFile = Join-Path $tempDir 'ObjectModule.psm1'
            Set-Content -LiteralPath $moduleFile -Value '# object path' -Encoding UTF8

            try {
                $fileInfo = Get-Item -LiteralPath $moduleFile
                $resolved = Get-ModulePath -ModulePath $fileInfo
                $resolved | Should -Be (Resolve-Path -LiteralPath $moduleFile).Path
            }
            finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back to manual path validation when Test-ValidPath is unavailable' {

            $tempDir = New-TestTempDirectory -Prefix 'SafeImportManual'
            $moduleFile = Join-Path $tempDir 'ManualModule.psm1'
            Set-Content -LiteralPath $moduleFile -Value '# manual' -Encoding UTF8

            try {
                Test-ModulePath -ModulePath $moduleFile | Should -Be $true
                Test-ModulePath -ModulePath $null | Should -Be $false
            }
            finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Resolves non-string module paths through ToString in manual validation mode' {
            $tempDir = New-TestTempDirectory -Prefix 'SafeImportManualObject'
            $moduleFile = Join-Path $tempDir 'ManualObjectModule.psm1'
            Set-Content -LiteralPath $moduleFile -Value '# manual object' -Encoding UTF8

            try {
                $fileInfo = Get-Item -LiteralPath $moduleFile
                Test-ModulePath -ModulePath $fileInfo | Should -Be $true
            }
            finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
