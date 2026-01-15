# ===============================================
# profile-database-enhanced.tests.ps1
# Unit tests for enhanced database functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database.ps1')
}

Describe 'database.ps1 - Enhanced Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('psql', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('mysql', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('sqlite3', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('mongosh', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('dbeaver', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('mongodb-compass', [ref]$null)
        }
        
        # Mock Start-Process to prevent actual launches
        Mock Start-Process -MockWith { return $null }
    }
    
    Context 'Connect-Database' {
        It 'Opens DBeaver for PostgreSQL when available' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            
            Connect-Database -DatabaseType PostgreSQL -Host 'localhost' -Database 'testdb' -ErrorAction SilentlyContinue
            
            Should -Invoke 'Start-Process' -Times 1 -Exactly
        }
        
        It 'Falls back to psql when DBeaver not available' {
            Mock-CommandAvailabilityPester -CommandName 'dbeaver' -Available $false
            Setup-AvailableCommandMock -CommandName 'psql'
            
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'psql') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            Connect-Database -DatabaseType PostgreSQL -Host 'localhost' -Database 'testdb' -UseGui:$false -ErrorAction SilentlyContinue
            
            # Should attempt to call psql
            $script:capturedArgs | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'dbeaver' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            { Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
    
    Context 'Query-Database' {
        It 'Returns null when required tools are not available' {
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            $result = Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT 1' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Validates DatabaseType parameter' {
            # Test with invalid DatabaseType value
            { Query-Database -DatabaseType InvalidType -Database 'testdb' -Query 'SELECT 1' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls psql with correct arguments for PostgreSQL' {
            Setup-AvailableCommandMock -CommandName 'psql'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'psql') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return 'Query result'
                }
            }
            
            $result = Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT * FROM users' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-d'
            $script:capturedArgs | Should -Contain 'testdb'
            $script:capturedArgs | Should -Contain '-c'
        }
        
        It 'Calls mysql with correct arguments for MySQL' {
            Setup-AvailableCommandMock -CommandName 'mysql'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'mysql') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return 'Query result'
                }
            }
            
            $result = Query-Database -DatabaseType MySQL -Database 'testdb' -Query 'SELECT * FROM users' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-D'
            $script:capturedArgs | Should -Contain 'testdb'
            $script:capturedArgs | Should -Contain '-e'
        }
        
        It 'Requires Database for SQLite' {
            Setup-AvailableCommandMock -CommandName 'sqlite3'
            
            { Query-Database -DatabaseType SQLite -Query 'SELECT 1' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Requires Database for MongoDB' {
            Setup-AvailableCommandMock -CommandName 'mongosh'
            
            { Query-Database -DatabaseType MongoDB -Query 'db.users.find()' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Export-Database' {
        It 'Returns null when required tools are not available' {
            Mock-CommandAvailabilityPester -CommandName 'pg_dump' -Available $false
            
            $result = Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath 'backup.sql' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Validates DatabaseType parameter' {
            # Test with invalid DatabaseType value
            { Export-Database -DatabaseType InvalidType -Database 'testdb' -OutputPath 'backup.sql' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls pg_dump with correct arguments for PostgreSQL' {
            Setup-AvailableCommandMock -CommandName 'pg_dump'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'pg_dump') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath 'backup.dump' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-F'
            $script:capturedArgs | Should -Contain 'c'
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain 'backup.dump'
            $script:capturedArgs | Should -Contain 'testdb'
        }
        
        It 'Adds schema-only flag when SchemaOnly is specified' {
            Setup-AvailableCommandMock -CommandName 'pg_dump'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'pg_dump') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath 'backup.dump' -SchemaOnly -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--schema-only'
        }
    }
    
    Context 'Import-Database' {
        It 'Returns false when input file does not exist' {
            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath 'nonexistent.sql' -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Returns false when required tools are not available' {
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $testFile -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Validates DatabaseType parameter' {
            # Test with invalid DatabaseType value
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            { Import-Database -DatabaseType InvalidType -Database 'testdb' -InputPath $testFile -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls psql with correct arguments for PostgreSQL' {
            Setup-AvailableCommandMock -CommandName 'psql'
            $testFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $testFile
            
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'psql') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $testFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-d'
            $script:capturedArgs | Should -Contain 'testdb'
            $result | Should -Be $true
        }
    }
    
    Context 'Backup-Database' {
        It 'Generates default backup path with timestamp' {
            Setup-AvailableCommandMock -CommandName 'pg_dump'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'pg_dump') {
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            
            $result | Should -Match '^testdb-\d{14}\.dump$'
        }
        
        It 'Uses provided BackupPath' {
            Setup-AvailableCommandMock -CommandName 'pg_dump'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'pg_dump') {
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath 'custom-backup.dump' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'custom-backup.dump'
        }
        
        It 'Compresses backup when Compress is specified' {
            Setup-AvailableCommandMock -CommandName 'pg_dump'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'pg_dump') {
                    $global:LASTEXITCODE = 0
                }
            }
            
            $backupFile = Join-Path $TestDrive 'backup.dump'
            'test content' | Out-File -FilePath $backupFile
            
            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $backupFile -Compress -ErrorAction SilentlyContinue
            
            $result | Should -Match '\.gz$'
        }
    }
    
    Context 'Restore-Database' {
        It 'Returns false when backup file does not exist' {
            $result = Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath 'nonexistent.dump' -ErrorAction SilentlyContinue
            
            $result | Should -Be $false
        }
        
        It 'Validates DatabaseType parameter' {
            # Test with invalid DatabaseType value
            $testFile = Join-Path $TestDrive 'backup.dump'
            'test content' | Out-File -FilePath $testFile
            { Restore-Database -DatabaseType InvalidType -Database 'testdb' -BackupPath $testFile -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles compressed backups' {
            Setup-AvailableCommandMock -CommandName 'psql'
            $compressedFile = Join-Path $TestDrive 'backup.sql.gz'
            $extractedFile = Join-Path $TestDrive 'backup.sql'
            'CREATE TABLE test (id INT);' | Out-File -FilePath $extractedFile
            Compress-Archive -Path $extractedFile -DestinationPath $compressedFile -Force
            
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'psql') {
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $compressedFile -ErrorAction SilentlyContinue
            
            $result | Should -Be $true
        }
    }
    
    Context 'Get-DatabaseSchema' {
        It 'Returns null when required tools are not available' {
            Mock-CommandAvailabilityPester -CommandName 'psql' -Available $false
            
            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Validates DatabaseType parameter' {
            # Test with invalid DatabaseType value
            { Get-DatabaseSchema -DatabaseType InvalidType -Database 'testdb' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Calls Query-Database with schema query for PostgreSQL' {
            Setup-AvailableCommandMock -CommandName 'psql'
            Mock Query-Database -MockWith {
                return 'Schema information'
            }
            
            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'Schema information'
        }
        
        It 'Filters by TableName when specified' {
            Setup-AvailableCommandMock -CommandName 'psql'
            Mock Query-Database -MockWith {
                return 'Table schema'
            }
            
            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -TableName 'users' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'Table schema'
        }
    }
}

