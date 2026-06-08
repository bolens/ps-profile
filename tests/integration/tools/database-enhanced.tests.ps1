# ===============================================
# database-enhanced.tests.ps1
# Integration tests for database.ps1 enhanced functions
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'database.ps1 - Enhanced Functions Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 'database.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 'database.ps1')
                . (Join-Path $script:ProfileDir 'database.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'database.ps1')
        }
        
        It 'Registers Connect-Database function' {
            Get-Command -Name 'Connect-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Query-Database function' {
            Get-Command -Name 'Query-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Export-Database function' {
            Get-Command -Name 'Export-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Import-Database function' {
            Get-Command -Name 'Import-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Backup-Database function' {
            Get-Command -Name 'Backup-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Restore-Database function' {
            Get-Command -Name 'Restore-Database' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Get-DatabaseSchema function' {
            Get-Command -Name 'Get-DatabaseSchema' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'database.ps1')
        }

        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }
        
        It 'Connect-Database handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'dbeaver' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'psql' -Available $false
            
            $output = & {
                Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'psql not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'psql'
        }
        
        It 'Query-Database handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'psql' -Available $false
            
            $output = & {
                Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT 1' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'psql not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'psql'
        }
        
        It 'Export-Database handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'pg_dump' -Available $false
            
            $output = & {
                Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath (Get-TestArtifactPath -FileName 'backup.sql') -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pg_dump not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pg_dump'
        }
        
        It 'Import-Database handles missing tools gracefully' {
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            
            Set-TestCommandAvailabilityState -CommandName 'psql' -Available $false
            
            $output = & {
                Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $testFile -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'psql not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'psql'
        }
        
        It 'Backup-Database handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'pg_dump' -Available $false
            
            $output = & {
                Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pg_dump not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pg_dump'
        }
        
        It 'Restore-Database handles missing tools gracefully' {
            $testFile = Join-Path $TestDrive 'backup.dump'
            'test content' | Out-File -FilePath $testFile
            
            Set-TestCommandAvailabilityState -CommandName 'psql' -Available $false
            
            $output = & {
                Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $testFile -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'psql not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'psql'
        }
        
        It 'Get-DatabaseSchema handles missing tools gracefully' {
            Set-TestCommandAvailabilityState -CommandName 'psql' -Available $false
            
            $output = & {
                Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'psql not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'psql'
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'database.ps1')
        }
        
        It 'Backup-Database returns string path' {
            $backupPath = Join-Path $TestDrive 'backup.dump'
            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $backupPath -ErrorAction SilentlyContinue
            
            # May be null if tools not available, but if it returns, should be string
            if ($null -ne $result) {
                $result | Should -BeOfType [string]
            }
        }
        
        It 'Import-Database returns boolean' {
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            
            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $testFile -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [bool]
        }
        
        It 'Restore-Database returns boolean' {
            $testFile = Join-Path $TestDrive 'backup.dump'
            'test content' | Out-File -FilePath $testFile
            
            $result = Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $testFile -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [bool]
        }
    }
}

