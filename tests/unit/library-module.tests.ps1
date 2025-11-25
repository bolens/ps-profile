. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Module Management Functions' {
    BeforeAll {
        # Import the Module module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'Module.psm1') -DisableNameChecking -ErrorAction Stop
    }

    Context 'Import-RequiredModule' {
        It 'Imports existing module successfully' {
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                { Import-RequiredModule -ModuleName 'Pester' -Force } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because 'Pester module not available'
            }
        }

        It 'Throws error for non-existent module' {
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            { Import-RequiredModule -ModuleName $nonExistentModule 2>$null } | Should -Throw
        }
    }

    Context 'Ensure-ModuleAvailable' {
        It 'Ensures module is available when already installed' {
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                { Ensure-ModuleAvailable -ModuleName 'Pester' } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because 'Pester module not available'
            }
        }
    }
}
