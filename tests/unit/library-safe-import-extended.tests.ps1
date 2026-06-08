<#
tests/unit/library-safe-import-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for SafeImport path resolution and import behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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

        It 'Returns null when MustExist is true and the module file is missing' {
            Get-ModulePath -ModulePath (Join-Path $script:TempDir 'MissingModule.psm1') | Should -BeNullOrEmpty
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
            $module = Import-ModuleSafely -ModulePath $script:ModuleFile -Required -ErrorAction Stop

            $module.Name | Should -Be 'ExtendedImport'
            $module.ExportedCommands.Keys | Should -Contain 'Get-ExtendedImportValue'
        }

        It 'Supports repeated imports of the same module path' {
            $first = Import-ModuleSafely -ModulePath $script:ModuleFile -ErrorAction Stop
            $second = Import-ModuleSafely -ModulePath $script:ModuleFile -ErrorAction Stop

            $first.Name | Should -Be 'ExtendedImport'
            $second.Name | Should -Be 'ExtendedImport'
        }
    }
}
