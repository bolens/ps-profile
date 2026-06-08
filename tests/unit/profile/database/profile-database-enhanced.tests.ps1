# ===============================================
# profile-database-enhanced.tests.ps1
# Unit tests for enhanced database functions
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
    . (Join-Path $script:ProfileDir 'database.ps1')

    $script:OriginalQueryDatabase = ${function:Query-Database}
}

Describe 'database.ps1 - Enhanced Functions' {
    BeforeEach {
        $script:TestWorkDir = New-TestTempDirectory -Prefix 'DbEnhanced'
        $script:TestImportFile = Join-Path $script:TestWorkDir 'backup.sql'
        $script:TestDumpFile = Join-Path $script:TestWorkDir 'backup.dump'
        $script:TestCustomBackupFile = Join-Path $script:TestWorkDir 'custom-backup.dump'
        Set-Content -Path $script:TestImportFile -Value 'CREATE TABLE test (id INT);'

        Clear-TestStartProcessCapture
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($command in @('psql', 'mysql', 'sqlite3', 'mongosh', 'dbeaver', 'pg_dump', 'mongodb-compass')) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        }

        Set-Item -Path Function:\Query-Database -Value $script:OriginalQueryDatabase -Force
        Reset-TestStartProcessMock
    }

    Context 'Connect-Database' {
        It 'Opens DBeaver for PostgreSQL when available' {
            Set-TestCommandAvailabilityState -CommandName 'dbeaver'

            Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'dbeaver'
        }

        It 'Falls back to psql when DBeaver not available' {
            Mark-TestCommandsUnavailable -CommandNames 'dbeaver'
            Setup-CapturingCommandMock -CommandName 'psql' -Output 'connected'

            Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -UseGui:$false -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Not -BeNullOrEmpty
            $args | Should -Contain '-d'
            $args | Should -Contain 'testdb'
        }

        It 'Handles missing tools gracefully' {
            Mark-TestCommandsUnavailable -CommandNames @('dbeaver', 'psql')

            { Connect-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Query-Database' {
        It 'Returns null when required tools are not available' {
            Mark-TestCommandsUnavailable -CommandNames 'psql'

            $result = Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT 1' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Validates DatabaseType parameter' {
            { Query-Database -DatabaseType InvalidType -Database 'testdb' -Query 'SELECT 1' -ErrorAction Stop } | Should -Throw
        }

        It 'Calls psql with correct arguments for PostgreSQL' {
            Setup-CapturingCommandMock -CommandName 'psql' -Output 'Query result'

            Query-Database -DatabaseType PostgreSQL -Database 'testdb' -Query 'SELECT * FROM users' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-d'
            $args | Should -Contain 'testdb'
            $args | Should -Contain '-c'
        }

        It 'Calls mysql with correct arguments for MySQL' {
            Setup-CapturingCommandMock -CommandName 'mysql' -Output 'Query result'

            Query-Database -DatabaseType MySQL -Database 'testdb' -Query 'SELECT * FROM users' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-D'
            $args | Should -Contain 'testdb'
            $args | Should -Contain '-e'
        }

        It 'Requires Database for SQLite' {
            Set-TestCommandAvailabilityState -CommandName 'sqlite3'

            $result = Query-Database -DatabaseType SQLite -Query 'SELECT 1' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Requires Database for MongoDB' {
            Set-TestCommandAvailabilityState -CommandName 'mongosh'

            $result = Query-Database -DatabaseType MongoDB -Query 'db.users.find()' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Export-Database' {
        It 'Returns null when required tools are not available' {
            Mark-TestCommandsUnavailable -CommandNames 'pg_dump'

            $result = Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath $script:TestImportFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Validates DatabaseType parameter' {
            { Export-Database -DatabaseType InvalidType -Database 'testdb' -OutputPath $script:TestImportFile -ErrorAction Stop } | Should -Throw
        }

        It 'Calls pg_dump with correct arguments for PostgreSQL' {
            Setup-CapturingCommandMock -CommandName 'pg_dump' -Output ''

            Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath $script:TestDumpFile -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-F'
            $args | Should -Contain 'c'
            $args | Should -Contain '-f'
            $args | Should -Contain $script:TestDumpFile
            $args | Should -Contain 'testdb'
        }

        It 'Adds schema-only flag when SchemaOnly is specified' {
            Setup-CapturingCommandMock -CommandName 'pg_dump' -Output ''

            Export-Database -DatabaseType PostgreSQL -Database 'testdb' -OutputPath $script:TestDumpFile -SchemaOnly -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--schema-only'
        }
    }

    Context 'Import-Database' {
        It 'Returns false when input file does not exist' {
            $missingImport = Join-Path $script:TestWorkDir 'nonexistent.sql'
            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $missingImport -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Returns false when required tools are not available' {
            Mark-TestCommandsUnavailable -CommandNames 'psql'

            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $script:TestImportFile -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Validates DatabaseType parameter' {
            { Import-Database -DatabaseType InvalidType -Database 'testdb' -InputPath $script:TestImportFile -ErrorAction Stop } | Should -Throw
        }

        It 'Calls psql with correct arguments for PostgreSQL' {
            Setup-CapturingCommandMock -CommandName 'psql' -Output 'import complete'

            $result = Import-Database -DatabaseType PostgreSQL -Database 'testdb' -InputPath $script:TestImportFile -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'testdb'
            @($result)[-1] | Should -Be $true
        }
    }

    Context 'Backup-Database' {
        It 'Generates default backup path with timestamp' {
            Setup-CapturingCommandMock -CommandName 'pg_dump' -Output ''

            Push-Location $script:TestWorkDir
            try {
                $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue
                @($result)[-1] | Should -Match '^testdb-\d{14}\.dump$'
            }
            finally {
                Pop-Location
            }
        }

        It 'Uses provided BackupPath' {
            Setup-CapturingCommandMock -CommandName 'pg_dump' -Output ''

            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $script:TestCustomBackupFile -ErrorAction SilentlyContinue

            @($result)[-1] | Should -Be $script:TestCustomBackupFile
        }

        It 'Compresses backup when Compress is specified' {
            Setup-CapturingCommandMock -CommandName 'pg_dump' -Output ''
            $backupFile = $script:TestDumpFile
            Set-Content -Path $backupFile -Value 'test content'

            $result = Backup-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $backupFile -Compress -ErrorAction SilentlyContinue

            $result | Should -Match '\.gz$'
        }
    }

    Context 'Restore-Database' {
        It 'Returns false when backup file does not exist' {
            $missingBackup = Join-Path $script:TestWorkDir 'nonexistent.dump'
            $result = Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $missingBackup -ErrorAction SilentlyContinue

            $result | Should -Be $false
        }

        It 'Validates DatabaseType parameter' {
            $testFile = Join-Path (New-TestTempDirectory -Prefix 'DbRestore') 'backup.dump'
            Set-Content -Path $testFile -Value 'test content'

            { Restore-Database -DatabaseType InvalidType -Database 'testdb' -BackupPath $testFile -ErrorAction Stop } | Should -Throw
        }

        It 'Handles compressed backups' {
            Setup-CapturingCommandMock -CommandName 'psql' -Output ''
            $restoreDir = New-TestTempDirectory -Prefix 'DbRestoreCompressed'
            $extractedFile = Join-Path $restoreDir 'backup.sql'
            Set-Content -Path $extractedFile -Value 'CREATE TABLE test (id INT);'
            $compressedFile = Join-Path $restoreDir 'backup.sql.gz'
            Compress-Archive -Path $extractedFile -DestinationPath $compressedFile -Force

            $result = Restore-Database -DatabaseType PostgreSQL -Database 'testdb' -BackupPath $compressedFile -ErrorAction SilentlyContinue

            @($result)[-1] | Should -Be $true
        }
    }

    Context 'Get-DatabaseSchema' {
        It 'Returns null when required tools are not available' {
            Mark-TestCommandsUnavailable -CommandNames 'psql'

            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Validates DatabaseType parameter' {
            { Get-DatabaseSchema -DatabaseType InvalidType -Database 'testdb' -ErrorAction Stop } | Should -Throw
        }

        It 'Calls Query-Database with schema query for PostgreSQL' {
            Set-TestCommandAvailabilityState -CommandName 'psql'
            Set-Item -Path Function:\Query-Database -Value {
                param(
                    [string]$DatabaseType,
                    [string]$Query,
                    [string]$Database
                )
                return 'Schema information'
            } -Force

            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -ErrorAction SilentlyContinue

            $result | Should -Be 'Schema information'
        }

        It 'Filters by TableName when specified' {
            Set-TestCommandAvailabilityState -CommandName 'psql'
            Set-Item -Path Function:\Query-Database -Value {
                param(
                    [string]$DatabaseType,
                    [string]$Query,
                    [string]$Database
                )
                return 'Table schema'
            } -Force

            $result = Get-DatabaseSchema -DatabaseType PostgreSQL -Database 'testdb' -TableName 'users' -ErrorAction SilentlyContinue

            $result | Should -Be 'Table schema'
        }
    }
}
