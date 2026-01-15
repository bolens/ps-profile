# ===============================================
# database-enhanced.tests.ps1
# Integration tests for database.ps1 enhanced functions
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
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
        
        It 'Connect-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'dbeaver' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Query-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT 1' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Export-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'pg_dump' -Available $false
            
            { Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath 'backup.sql' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Import-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $testFile -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Backup-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'pg_dump' -Available $false
            
            { Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Restore-Database handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            $testFile = Join-Path $TestDrive 'backup.dump'
            'test content' | Out-File -FilePath $testFile
            
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $testFile -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        
        It 'Get-DatabaseSchema handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
    
    Context 'Function Behavior' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'database.ps1')
        }
        
        It 'Backup-Database returns string path' {
            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath 'backup.dump' -ErrorAction SilentlyContinue
            
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

