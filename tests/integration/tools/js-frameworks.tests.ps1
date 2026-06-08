BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}

<#
.SYNOPSIS
    Integration tests for JavaScript framework tool fragments (Next.js, Vite, Angular, Vue, Nuxt).

.DESCRIPTION
    Tests Next.js, Vite, Angular, Vue, and Nuxt helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'JavaScript Framework Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize JavaScript framework tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Next.js helpers (nextjs.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('npx')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            . (Join-Path $script:ProfileDir 'nextjs.ps1')
            Register-TestFragmentAliases @{
                'next-dev'        = 'Start-NextJsDev'
                'next-build'      = 'Build-NextJsApp'
                'next-start'      = 'Start-NextJsProduction'
                'create-next-app' = 'New-NextJsApp'
            }
        }

        It 'Creates Start-NextJsDev function' {
            Get-Command Start-NextJsDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates next-dev alias for Start-NextJsDev' {
            Get-Alias next-dev -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias next-dev).ResolvedCommandName | Should -Be 'Start-NextJsDev'
        }

        It 'next-dev alias handles missing tool gracefully and recommends installation' {
            # Clear warning cache to ensure warning is shown
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('npx', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('npx')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-Alias -Name next-dev -Value Start-NextJsDev -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = next-dev 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'npx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nodejs' -ToolType 'node-package'
        }

        It 'Creates Build-NextJsApp function' {
            Get-Command Build-NextJsApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates next-build alias for Build-NextJsApp' {
            Get-Alias next-build -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias next-build).ResolvedCommandName | Should -Be 'Build-NextJsApp'
        }

        It 'next-build alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('npx', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('npx')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-Alias -Name next-build -Value Build-NextJsApp -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = next-build 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'npx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nodejs' -ToolType 'node-package'
        }

        It 'Creates Start-NextJsProduction function' {
            Get-Command Start-NextJsProduction -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates next-start alias for Start-NextJsProduction' {
            Get-Alias next-start -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias next-start).ResolvedCommandName | Should -Be 'Start-NextJsProduction'
        }

        It 'Creates New-NextJsApp function' {
            Get-Command New-NextJsApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates create-next-app alias for New-NextJsApp' {
            Get-Alias create-next-app -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias create-next-app).ResolvedCommandName | Should -Be 'New-NextJsApp'
        }
    }

    Context 'Vite helpers (vite.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('vite', 'npx')
            Set-TestCommandAvailabilityState -CommandName 'vite' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            . (Join-Path $script:ProfileDir 'vite.ps1')
            Register-TestFragmentAliases @{
                vite         = 'Invoke-Vite'
                'create-vite' = 'New-ViteProject'
                'vite-dev'   = 'Start-ViteDev'
                'vite-build' = 'Build-ViteApp'
            }
        }

        It 'Creates Invoke-Vite function' {
            Get-Command Invoke-Vite -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vite alias for Invoke-Vite' {
            Get-Alias vite -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vite).ResolvedCommandName | Should -Be 'Invoke-Vite'
        }

        It 'vite alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('vite', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('vite')
            Set-TestCommandAvailabilityState -CommandName 'vite' -Available $false
            Set-Alias -Name vite -Value Invoke-Vite -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = vite --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'vite not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'vite' -ToolType 'node-package'
        }

        It 'Creates New-ViteProject function' {
            Get-Command New-ViteProject -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates create-vite alias for New-ViteProject' {
            Get-Alias create-vite -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias create-vite).ResolvedCommandName | Should -Be 'New-ViteProject'
        }

        It 'Creates Start-ViteDev function' {
            Get-Command Start-ViteDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vite-dev alias for Start-ViteDev' {
            Get-Alias vite-dev -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vite-dev).ResolvedCommandName | Should -Be 'Start-ViteDev'
        }

        It 'Creates Build-ViteApp function' {
            Get-Command Build-ViteApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vite-build alias for Build-ViteApp' {
            Get-Alias vite-build -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vite-build).ResolvedCommandName | Should -Be 'Build-ViteApp'
        }
    }

    Context 'Angular CLI helpers (angular.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('npx', 'ng')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'ng' -Available $true
            . (Join-Path $script:ProfileDir 'angular.ps1')
            Register-TestFragmentAliases @{
                ng       = 'Invoke-Angular'
                'ng-new' = 'New-AngularApp'
                'ng-serve' = 'Start-AngularDev'
            }
        }

        It 'Creates Invoke-Angular function' {
            Get-Command Invoke-Angular -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ng alias for Invoke-Angular' {
            Get-Alias ng -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ng).ResolvedCommandName | Should -Be 'Invoke-Angular'
        }

        It 'ng alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('npx or ng', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('npx', 'ng')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'ng' -Available $false
            Set-Alias -Name ng -Value Invoke-Angular -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = ng --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'npx or ng not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolNames @('nodejs', '@angular/cli') -ToolType 'node-package'
        }

        It 'Creates New-AngularApp function' {
            Get-Command New-AngularApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ng-new alias for New-AngularApp' {
            Get-Alias ng-new -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ng-new).ResolvedCommandName | Should -Be 'New-AngularApp'
        }

        It 'Creates Start-AngularDev function' {
            Get-Command Start-AngularDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ng-serve alias for Start-AngularDev' {
            Get-Alias ng-serve -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ng-serve).ResolvedCommandName | Should -Be 'Start-AngularDev'
        }
    }

    Context 'Vue.js helpers (vue.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('npx', 'vue')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'vue' -Available $true
            . (Join-Path $script:ProfileDir 'vue.ps1')
            Register-TestFragmentAliases @{
                vue        = 'Invoke-Vue'
                'vue-create' = 'New-VueApp'
                'vue-serve'  = 'Start-VueDev'
            }
        }

        It 'Creates Invoke-Vue function' {
            Get-Command Invoke-Vue -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vue alias for Invoke-Vue' {
            Get-Alias vue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vue).ResolvedCommandName | Should -Be 'Invoke-Vue'
        }

        It 'vue alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('npx or vue', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('npx', 'vue')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'vue' -Available $false
            Set-Alias -Name vue -Value Invoke-Vue -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = vue --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'npx or vue not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolNames @('nodejs', '@vue/cli') -ToolType 'node-package'
        }

        It 'Creates New-VueApp function' {
            Get-Command New-VueApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vue-create alias for New-VueApp' {
            Get-Alias vue-create -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vue-create).ResolvedCommandName | Should -Be 'New-VueApp'
        }

        It 'Creates Start-VueDev function' {
            Get-Command Start-VueDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates vue-serve alias for Start-VueDev' {
            Get-Alias vue-serve -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias vue-serve).ResolvedCommandName | Should -Be 'Start-VueDev'
        }
    }

    Context 'Nuxt.js helpers (nuxt.ps1)' {
        BeforeAll {
            Mark-TestCommandsUnavailable -CommandNames @('npx', 'nuxi')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $true
            Set-TestCommandAvailabilityState -CommandName 'nuxi' -Available $true
            . (Join-Path $script:ProfileDir 'nuxt.ps1')
            Register-TestFragmentAliases @{
                nuxi            = 'Invoke-Nuxt'
                'nuxt-dev'      = 'Start-NuxtDev'
                'nuxt-build'    = 'Build-NuxtApp'
                'create-nuxt-app' = 'New-NuxtApp'
            }
        }

        It 'Creates Invoke-Nuxt function' {
            Get-Command Invoke-Nuxt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nuxi alias for Invoke-Nuxt' {
            Get-Alias nuxi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nuxi).ResolvedCommandName | Should -Be 'Invoke-Nuxt'
        }

        It 'nuxi alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('nuxi', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('nuxi')
            Set-TestCommandAvailabilityState -CommandName 'nuxi' -Available $false
            Set-Alias -Name nuxi -Value Invoke-Nuxt -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = nuxi --version 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'nuxi not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nuxi' -ToolType 'node-package'
        }

        It 'Creates Start-NuxtDev function' {
            Get-Command Start-NuxtDev -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nuxt-dev alias for Start-NuxtDev' {
            Get-Alias nuxt-dev -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nuxt-dev).ResolvedCommandName | Should -Be 'Start-NuxtDev'
        }

        It 'nuxt-dev alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('npx', [ref]$null)
            }
            Mark-TestCommandsUnavailable -CommandNames @('npx')
            Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
            Set-Alias -Name nuxt-dev -Value Start-NuxtDev -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            $output = nuxt-dev 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'npx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'nodejs' -ToolType 'node-package'
        }

        It 'Creates Build-NuxtApp function' {
            Get-Command Build-NuxtApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates nuxt-build alias for Build-NuxtApp' {
            Get-Alias nuxt-build -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias nuxt-build).ResolvedCommandName | Should -Be 'Build-NuxtApp'
        }

        It 'Creates New-NuxtApp function' {
            Get-Command New-NuxtApp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates create-nuxt-app alias for New-NuxtApp' {
            Get-Alias create-nuxt-app -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias create-nuxt-app).ResolvedCommandName | Should -Be 'New-NuxtApp'
        }
    }
}

