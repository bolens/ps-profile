<#
tests/unit/library-module-import-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-LibModule subdirectory resolution.
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
    $pathResolutionPath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
    $cachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'

    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    Remove-Module ModuleImport -ErrorAction SilentlyContinue -Force

    Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop -Force -Global
    if (-not (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue)) {
        throw 'Get-RepoRoot function not available after importing PathResolution module'
    }

    if (Test-Path -LiteralPath $cachePath) {
        Import-Module $cachePath -DisableNameChecking -Force -Global
    }

    Import-Module (Join-Path $script:LibPath 'ModuleImport.psm1') -DisableNameChecking -ErrorAction Stop -Force

    $script:TestScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
}

AfterAll {
    Remove-Module ModuleImport -ErrorAction SilentlyContinue -Force
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    Remove-Module Logging -ErrorAction SilentlyContinue -Force
    Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force
    Remove-Module FileBackup -ErrorAction SilentlyContinue -Force
}

Describe 'ModuleImport extended scenarios' {
    Context 'Import-LibModule' {
        It 'Resolves PathResolution from the path subdirectory' {
            $module = Import-LibModule -ModuleName 'PathResolution' -ScriptPath $script:TestScriptPath -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/path/PathResolution\.psm1'
        }

        It 'Resolves FileFiltering from the file subdirectory' {
            Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force

            $module = Import-LibModule -ModuleName 'FileFiltering' -ScriptPath $script:TestScriptPath -Global -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/file/FileFiltering\.psm1'
            $module.ExportedFunctions.Keys | Should -Contain 'Filter-Files'
        }

        It 'Resolves FileBackup from the file subdirectory' {
            Remove-Module FileBackup -ErrorAction SilentlyContinue -Force

            $module = Import-LibModule -ModuleName 'FileBackup' -ScriptPath $script:TestScriptPath -Global -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/file/FileBackup\.psm1'
            $module.ExportedFunctions.Keys | Should -Contain 'New-FileBackup'
            $module.ExportedFunctions.Keys | Should -Contain 'Restore-FileBackup'
        }
    }

    Context 'Import-LibModules' {
        It 'Imports a mix of root and subdirectory modules' {
            Remove-Module Logging -ErrorAction SilentlyContinue -Force
            Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force

            $modules = Import-LibModules -ModuleNames @('Logging', 'FileFiltering') -ScriptPath $script:TestScriptPath -ErrorAction Stop

            @($modules).Count | Should -Be 2
            $exported = @($modules | ForEach-Object { $_.ExportedFunctions.Keys })
            $exported | Should -Contain 'Write-ScriptMessage'
            $exported | Should -Contain 'Filter-Files'
        }
    }

    Context 'Initialize-ScriptEnvironment' {
        It 'Combines repository root and imported module metadata' {
            $environment = Initialize-ScriptEnvironment `
                -ScriptPath $script:TestScriptPath `
                -GetRepoRoot `
                -ImportModules @('Logging')

            $environment.RepoRoot | Should -Not -BeNullOrEmpty
            @($environment.ImportedModules).Count | Should -BeGreaterThan 0
            $environment.LibPath | Should -Not -BeNullOrEmpty
        }
    }
}
