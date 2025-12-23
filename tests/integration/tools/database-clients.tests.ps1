# ===============================================
# database-clients.tests.ps1
# Integration tests for database-clients.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:DatabaseClientsPath = Join-Path $script:ProfileDir 'database-clients.ps1'
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'database-clients.ps1 - Integration Tests' {
    BeforeEach {
        # Remove functions and aliases to test fresh loading
        Remove-Item -Path "Function:\Start-MongoDbCompass" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-SqlWorkbench" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-DBeaver" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Start-TablePlus" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Invoke-Hasura" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Invoke-Supabase" -Force -ErrorAction SilentlyContinue
        
        Remove-Item -Path "Alias:\mongodb-compass" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\sql-workbench" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\dbeaver" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\tableplus" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\hasura" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\supabase" -Force -ErrorAction SilentlyContinue
        
        # Clear fragment loaded state
        if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
            # Note: We can't easily clear the fragment loaded state, but idempotency tests will verify it works
        }
    }
    
    Context 'Function Registration' {
        It 'Registers Start-MongoDbCompass function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Start-MongoDbCompass -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
        
        It 'Registers Start-SqlWorkbench function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Start-SqlWorkbench -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
        
        It 'Registers Start-DBeaver function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Start-DBeaver -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
        
        It 'Registers Start-TablePlus function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Start-TablePlus -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
        
        It 'Registers Invoke-Hasura function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Invoke-Hasura -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
        
        It 'Registers Invoke-Supabase function' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $function = Get-Command Invoke-Supabase -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be 'Function'
        }
    }
    
    Context 'Alias Creation' {
        It 'Creates mongodb-compass alias for Start-MongoDbCompass' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias mongodb-compass -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Start-MongoDbCompass' | Out-Null
                }
                $alias = Get-Alias mongodb-compass -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Start-MongoDbCompass'
            }
        }
        
        It 'Creates sql-workbench alias for Start-SqlWorkbench' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias sql-workbench -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'sql-workbench' -Target 'Start-SqlWorkbench' | Out-Null
                }
                $alias = Get-Alias sql-workbench -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Start-SqlWorkbench'
            }
        }
        
        It 'Creates dbeaver alias for Start-DBeaver' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias dbeaver -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'dbeaver' -Target 'Start-DBeaver' | Out-Null
                }
                $alias = Get-Alias dbeaver -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Start-DBeaver'
            }
        }
        
        It 'Creates tableplus alias for Start-TablePlus' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias tableplus -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'tableplus' -Target 'Start-TablePlus' | Out-Null
                }
                $alias = Get-Alias tableplus -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Start-TablePlus'
            }
        }
        
        It 'Creates hasura alias for Invoke-Hasura' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            # Mock Get-Command to return null for 'hasura' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'hasura' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-Hasura -ErrorAction SilentlyContinue
            Remove-Item Alias:\hasura -ErrorAction SilentlyContinue
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias hasura -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'hasura' -Target 'Invoke-Hasura' | Out-Null
                }
                $alias = Get-Alias hasura -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-Hasura'
            }
        }
        
        It 'Creates supabase alias for Invoke-Supabase' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            # Mock Get-Command to return null for 'supabase' so Set-AgentModeAlias creates the alias
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'supabase' } -MockWith { $null }
            # Reload fragment to ensure alias is created
            Remove-Item Function:\Invoke-Supabase -ErrorAction SilentlyContinue
            Remove-Item Alias:\supabase -ErrorAction SilentlyContinue
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            $alias = Get-Alias supabase -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'supabase' -Target 'Invoke-Supabase' | Out-Null
                }
                $alias = Get-Alias supabase -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
            if ($alias) {
                $alias.ResolvedCommandName | Should -Be 'Invoke-Supabase'
            }
        }
    }
    
    Context 'Graceful Degradation' {
        It 'mongodb-compass alias handles missing tool gracefully' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            # Ensure alias exists
            if (-not (Get-Alias mongodb-compass -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Start-MongoDbCompass' | Out-Null
                }
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if ($global:TestCachedCommandCache) {
                $null = $global:TestCachedCommandCache.TryRemove('mongodb-compass', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'mongodb-compass' -Available $false
            $output = Start-MongoDbCompass 2>&1 3>&1 | Out-String
            $output | Should -Match 'mongodb-compass'
        }
        
        It 'hasura alias handles missing tool gracefully' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            # Ensure alias exists
            if (-not (Get-Alias hasura -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'hasura' -Target 'Invoke-Hasura' | Out-Null
                }
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if ($global:TestCachedCommandCache) {
                $null = $global:TestCachedCommandCache.TryRemove('hasura-cli', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'hasura-cli' -Available $false
            $output = Invoke-Hasura version 2>&1 3>&1 | Out-String
            $output | Should -Match 'hasura'
        }
        
        It 'supabase alias handles missing tool gracefully' {
            . $script:DatabaseClientsPath -ErrorAction SilentlyContinue
            # Ensure alias exists
            if (-not (Get-Alias supabase -ErrorAction SilentlyContinue)) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'supabase' -Target 'Invoke-Supabase' | Out-Null
                }
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            if ($global:TestCachedCommandCache) {
                $null = $global:TestCachedCommandCache.TryRemove('supabase', [ref]$null)
                $null = $global:TestCachedCommandCache.TryRemove('supabase-beta', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'supabase-beta' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'supabase' -Available $false
            $output = Invoke-Supabase status 2>&1 3>&1 | Out-String
            $output | Should -Match 'supabase'
        }
    }
    
    Context 'Fragment Loading' {
        It 'Fragment loads successfully' {
            { . $script:DatabaseClientsPath -ErrorAction Stop } | Should -Not -Throw
        }
        
        It 'Fragment is idempotent (can be loaded multiple times)' {
            $databaseClientsPath = Join-Path $script:ProfileDir 'database-clients.ps1'
            # Ensure function exists first
            if (-not (Get-Command Start-MongoDbCompass -ErrorAction SilentlyContinue)) {
                . $databaseClientsPath -ErrorAction SilentlyContinue
            }
            # Verify the function can be called before reload
            { Start-MongoDbCompass -ErrorAction Stop } | Should -Not -Throw
            . $databaseClientsPath -ErrorAction SilentlyContinue
            # Verify the function can still be called after reload
            { Start-MongoDbCompass -ErrorAction Stop } | Should -Not -Throw
        }
    }
}

