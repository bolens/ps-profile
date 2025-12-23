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
            # Mock Get-Command to return null for 'npx' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'npx' } -MockWith { $null }
            # Mock npx command before loading fragment to prevent conflicts
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'nextjs.ps1')
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
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            $output = next-dev 2>&1 3>&1 | Out-String
            $output | Should -Match 'npx not found'
            $output | Should -Match 'npm install -g npm'
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
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            $output = next-build 2>&1 3>&1 | Out-String
            $output | Should -Match 'npx not found'
            $output | Should -Match 'npm install -g npm'
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
            # Mock Get-Command to return null for 'vite' and 'npx' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'vite' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'npx' } -MockWith { $null }
            # Mock vite and npx commands before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'vite' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'vite' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'vite.ps1')
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
            Mock-CommandAvailabilityPester -CommandName 'vite' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'vite' } -MockWith { $false }
            $output = vite --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'vite not found'
            $output | Should -Match 'npm install -g vite'
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
            # Mock Get-Command to return null for 'npx' and 'ng' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'npx' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'ng' } -MockWith { $null }
            # Mock npx and ng commands before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'ng' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'ng' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'angular.ps1')
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
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'ng' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'ng' } -MockWith { $false }
            $output = ng --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'npx or ng not found'
            $output | Should -Match 'npm install -g npm or npm install -g @angular/cli'
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
            # Mock Get-Command to return null for 'npx' and 'vue' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'npx' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'vue' } -MockWith { $null }
            # Mock npx and vue commands before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'vue' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'vue' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'vue.ps1')
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
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'vue' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'vue' } -MockWith { $false }
            $output = vue --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'npx or vue not found'
            $output | Should -Match 'npm install -g npm or npm install -g @vue/cli'
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
            # Mock Get-Command to return null for 'npx' and 'nuxi' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'npx' } -MockWith { $null }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'nuxi' } -MockWith { $null }
            # Mock npx and nuxi commands before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope Context
            Mock-CommandAvailabilityPester -CommandName 'nuxi' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'nuxi' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'nuxt.ps1')
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
            Mock-CommandAvailabilityPester -CommandName 'nuxi' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'nuxi' } -MockWith { $false }
            $output = nuxi --version 2>&1 3>&1 | Out-String
            $output | Should -Match 'nuxi not found'
            $output | Should -Match 'npm install -g nuxi'
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
            Mock-CommandAvailabilityPester -CommandName 'npx' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'npx' } -MockWith { $false }
            $output = nuxt-dev 2>&1 3>&1 | Out-String
            $output | Should -Match 'npx not found'
            $output | Should -Match 'npm install -g npm'
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

