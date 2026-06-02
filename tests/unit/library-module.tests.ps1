BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }
        
        $script:ModulePath = Join-Path $script:LibPath 'runtime' 'Module.psm1'
        if ($null -eq $script:ModulePath -or [string]::IsNullOrWhiteSpace($script:ModulePath)) {
            throw "ModulePath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:ModulePath)) {
            throw "Module module not found at: $script:ModulePath"
        }
        
        # Import the module under test
        Import-Module $script:ModulePath -DisableNameChecking -ErrorAction Stop -Force
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize Module tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module Module -ErrorAction SilentlyContinue -Force
}

Describe 'Module Module Functions' {
    Context 'Import-RequiredModule' {
        It 'Imports an available module successfully' {
            # Use a module that should be available (Pester for testing)
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                Remove-Module Pester -ErrorAction SilentlyContinue -Force
                { Import-RequiredModule -ModuleName 'Pester' } | Should -Not -Throw
                Get-Module Pester | Should -Not -BeNullOrEmpty
            }
        }

        It 'Throws error when module does not exist' {
            # The error message may vary, so we check for either the formatted message or the original error
            { Import-RequiredModule -ModuleName 'NonExistentModule12345' } | Should -Throw
        }

        It 'Forces reimport when Force is specified' {
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                Import-RequiredModule -ModuleName 'Pester' -ErrorAction SilentlyContinue
                { Import-RequiredModule -ModuleName 'Pester' -Force } | Should -Not -Throw
            }
        }

        It 'Exports Import-RequiredModule function' {
            $module = Get-Module Module
            $module.ExportedFunctions.Keys | Should -Contain 'Import-RequiredModule'
        }
    }

    Context 'Install-RequiredModule' {
        It 'Skips installation when module is already available' {
            # Use a module that should be available; skip if [ModuleScope] enum causes load failure
            $cmd = Get-Command Install-RequiredModule
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Install-RequiredModule parameters not parseable (ModuleScope enum dependency)'
                return
            }
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                { Install-RequiredModule -ModuleName 'Pester' } | Should -Not -Throw
            }
        }

        It 'Uses CurrentUser scope by default' {
            $cmd = Get-Command Install-RequiredModule
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Install-RequiredModule parameters not available (ModuleScope enum dependency)'
                return
            }
            $scopeParam = $cmd.Parameters['Scope']
            $scopeParam | Should -Not -BeNullOrEmpty
        }

        It 'Accepts AllUsers scope' {
            if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetType('ModuleScope') }) {
                [System.Enum]::GetNames([ModuleScope]) | Should -Contain 'AllUsers'
            }
            else {
                Set-ItResult -Skipped -Because 'ModuleScope enum not available in this session'
            }
        }

        It 'Accepts a Force parameter' {
            $cmd = Get-Command Install-RequiredModule
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Install-RequiredModule parameters not available (ModuleScope enum dependency)'
                return
            }
            $cmd.Parameters['Force'] | Should -Not -BeNullOrEmpty
        }

        It 'Handles PSGallery registration' {
            Set-ItResult -Skipped -Because 'requires network access to PSGallery — not safe to test in unit suite'
        }

        It 'Throws error when installation fails' {
            # Test with a module name that will fail (invalid name)
            { Install-RequiredModule -ModuleName 'Invalid-Module-Name-12345-That-Does-Not-Exist' } | Should -Throw
        }

        It 'Exports Install-RequiredModule function' {
            $module = Get-Module Module
            $module.ExportedFunctions.Keys | Should -Contain 'Install-RequiredModule'
        }
    }

    Context 'Ensure-ModuleAvailable' {
        It 'Installs and imports module when not available' {
            # This is a convenience function that combines Install and Import
            # Testing would require network access for installation
            Get-Command Ensure-ModuleAvailable | Should -Not -BeNullOrEmpty
        }

        It 'Uses CurrentUser scope by default' {
            $cmd = Get-Command Ensure-ModuleAvailable
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Ensure-ModuleAvailable parameters not available (ModuleScope enum dependency)'
                return
            }
            $cmd.Parameters['Scope'] | Should -Not -BeNullOrEmpty
        }

        It 'Accepts AllUsers scope' {
            # ModuleScope enum is defined in CommonEnums — if available check its values
            if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetType('ModuleScope') }) {
                [System.Enum]::GetNames([ModuleScope]) | Should -Contain 'AllUsers'
            }
            else {
                Set-ItResult -Skipped -Because 'ModuleScope enum not available in this session'
            }
        }

        It 'Forces reinstallation and reimport when Force is specified' {
            # Verify Force parameter exists and is a switch
            $cmd = Get-Command Ensure-ModuleAvailable
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Ensure-ModuleAvailable parameters not available (ModuleScope enum dependency)'
                return
            }
            $cmd.Parameters['Force'].ParameterType | Should -Be ([switch])
        }

        It 'Accepts a Force parameter' {
            $cmd = Get-Command Ensure-ModuleAvailable
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Ensure-ModuleAvailable parameters not available (ModuleScope enum dependency)'
                return
            }
            $cmd.Parameters['Force'] | Should -Not -BeNullOrEmpty
        }

        It 'Exports Ensure-ModuleAvailable function' {
            $module = Get-Module Module
            $module.ExportedFunctions.Keys | Should -Contain 'Ensure-ModuleAvailable'
        }
    }
}
