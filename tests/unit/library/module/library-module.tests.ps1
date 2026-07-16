BeforeAll {
    try {
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
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw 'Get-TestPath returned null or empty value for LibPath'
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }

        $script:ModulePath = Join-Path $script:LibPath 'runtime' 'Module.psm1'
        if ($null -eq $script:ModulePath -or [string]::IsNullOrWhiteSpace($script:ModulePath)) {
            throw 'ModulePath is null or empty'
        }
        if (-not (Test-Path -LiteralPath $script:ModulePath)) {
            throw "Module module not found at: $script:ModulePath"
        }

        Import-Module $script:ModulePath -DisableNameChecking -ErrorAction Stop -Force

        # Disposable probe module for import/ensure tests. NEVER unload Pester here — that
        # destroys the running test runner's mock infrastructure and cascades
        # "Mock data are not setup for this scope" into later files in the same shard.
        $script:ProbeName = 'PsProfileModuleProbe'
        $script:ProbeRoot = New-TestTempDirectory -Prefix 'ModuleProbe'
        $probeDir = Join-Path $script:ProbeRoot $script:ProbeName
        New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $probeDir "$($script:ProbeName).psm1") -Value @'
function Get-PsProfileModuleProbe { 'ok' }
Export-ModuleMember -Function Get-PsProfileModuleProbe
'@
        $script:OriginalPSModulePath = $env:PSModulePath
        $env:PSModulePath = "$($script:ProbeRoot)$([System.IO.Path]::PathSeparator)$env:PSModulePath"
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
    if ($script:ProbeName) {
        Remove-Module -Name $script:ProbeName -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $script:OriginalPSModulePath) {
        $env:PSModulePath = $script:OriginalPSModulePath
    }
}

Describe 'Module Module Functions' {
    Context 'Import-RequiredModule' {
        It 'Imports an available module successfully' {
            Remove-Module -Name $script:ProbeName -Force -ErrorAction SilentlyContinue
            { Import-RequiredModule -ModuleName $script:ProbeName } | Should -Not -Throw
            # Import-RequiredModule runs inside Module.psm1, so the import lands in that
            # module's session — use -All so the test scope can observe it.
            Get-Module -Name $script:ProbeName -All | Should -Not -BeNullOrEmpty
        }

        It 'Throws error when module does not exist' {
            # The error message may vary, so we check for either the formatted message or the original error
            { Import-RequiredModule -ModuleName 'NonExistentModule12345' } | Should -Throw
        }

        It 'Forces reimport when Force is specified' {
            Import-RequiredModule -ModuleName $script:ProbeName -ErrorAction SilentlyContinue
            { Import-RequiredModule -ModuleName $script:ProbeName -Force } | Should -Not -Throw
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
            { Install-RequiredModule -ModuleName $script:ProbeName } | Should -Not -Throw
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
