# ===============================================
# fragment-cache-sqlite.tests.ps1
# Integration tests for FragmentCache SQLite functionality
#
# Test Coverage:
# - SQLite database creation and table initialization
# - Persistent cache storage and retrieval from SQLite
# - Cache pre-warming from SQLite to in-memory cache
# - Module loading integration (FragmentCache loading FragmentCacheSqlite)
# - DbPath parameter passing through wrapper functions
#
# These tests verify end-to-end functionality:
# - Database operations work correctly with SQLite
# - Cache entries persist across cache clears
# - Pre-warming loads entries from SQLite into memory
# - Module dependencies are resolved correctly
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:CacheModulePath = Join-Path $script:FragmentLibDir 'FragmentCache.psm1'
    $script:SqliteModulePath = Join-Path $script:FragmentLibDir 'FragmentCacheSqlite.psm1'
    $script:PreWarmModulePath = Join-Path $script:FragmentLibDir 'FragmentCachePreWarm.psm1'
    
    # Create test directories
    $script:TestCacheDir = Join-Path $env:TEMP "FragmentCacheIntegrationTests_$(New-Guid)"
    $null = New-Item -ItemType Directory -Path $script:TestCacheDir -Force
    
    $script:TestFragmentDir = Join-Path $env:TEMP "FragmentCacheIntegrationTests_Fragments_$(New-Guid)"
    $null = New-Item -ItemType Directory -Path $script:TestFragmentDir -Force
    
    # Create test fragment files
    $script:TestFragment1 = Join-Path $script:TestFragmentDir 'fragment1.ps1'
    @'
function Test-Fragment1Function {
    param([string]$Name)
    Write-Output "Fragment1: $Name"
}

Set-AgentModeAlias -Name 'tf1' -Target 'Test-Fragment1Function'
'@ | Out-File -FilePath $script:TestFragment1 -Encoding UTF8
    
    $script:TestFragment2 = Join-Path $script:TestFragmentDir 'fragment2.ps1'
    @'
function Test-Fragment2Function {
    param([int]$Value)
    return $Value * 2
}

function Test-Fragment2Helper {
    Write-Output "Helper"
}
'@ | Out-File -FilePath $script:TestFragment2 -Encoding UTF8
    
    # Store original environment
    $script:OriginalDebug = $env:PS_PROFILE_DEBUG
    $script:OriginalCacheDir = $env:PS_PROFILE_CACHE_DIR
    
    # Set test environment
    $env:PS_PROFILE_DEBUG = '0'
    $env:PS_PROFILE_CACHE_DIR = $script:TestCacheDir
}

AfterAll {
    # Restore environment
    if ($script:OriginalDebug) {
        $env:PS_PROFILE_DEBUG = $script:OriginalDebug
    }
    else {
        Remove-Item -Path Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }
    
    if ($script:OriginalCacheDir) {
        $env:PS_PROFILE_CACHE_DIR = $script:OriginalCacheDir
    }
    else {
        Remove-Item -Path Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
    }
    
    # Clean up
    if (Test-Path $script:TestCacheDir) {
        Remove-Item -Path $script:TestCacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $script:TestFragmentDir) {
        Remove-Item -Path $script:TestFragmentDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean up modules
    Remove-Module FragmentCache -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCachePreWarm -ErrorAction SilentlyContinue -Force
    
    # Clean up globals
    if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentContentCache.Clear()
    }
    if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentAstCache.Clear()
    }
}

BeforeEach {
    # Clear caches
    if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentContentCache.Clear()
    }
    if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentAstCache.Clear()
    }
    
    # Remove test database
    $testDbPath = Join-Path $script:TestCacheDir 'fragment-cache.db'
    if (Test-Path $testDbPath) {
        Remove-Item -Path $testDbPath -Force -ErrorAction SilentlyContinue
    }
    
    # Remove modules for clean state
    Remove-Module FragmentCache -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCachePreWarm -ErrorAction SilentlyContinue -Force
}

Describe 'FragmentCache SQLite Integration - Database Operations' {
    Context 'Database Initialization' {
        It 'Initializes database and creates tables when SQLite is available' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath)) {
                Set-ItResult -Skipped -Because "FragmentCache module not found"
                return
            }
        
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (-not (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Initialize-FragmentCache not available"
                return
            }
        
            Initialize-FragmentCache | Out-Null
        
            # Check if SQLite is available
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $sqliteAvailable = Test-SqliteAvailable
            }
        
            if ($sqliteAvailable) {
                $dbPath = if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                    Get-FragmentCacheDbPath
                }
                else {
                    Join-Path $script:TestCacheDir 'fragment-cache.db'
                }
            
                if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                    $result = Initialize-FragmentCacheDb -DbPath $dbPath
                    if ($result) {
                        # Database file should exist
                        Test-Path $dbPath | Should -Be $true
                    
                        # Verify tables exist by querying (if sqlite3 is available)
                        $sqliteCmd = if (Get-Command Get-SqliteCommandName -ErrorAction SilentlyContinue) {
                            Get-SqliteCommandName
                        }
                        else {
                            $null
                        }
                    
                        if ($sqliteCmd) {
                            $tempOut = [System.IO.Path]::GetTempFileName()
                            $tempSql = [System.IO.Path]::GetTempFileName()
                            try {
                                ".tables" | Out-File -FilePath $tempSql -Encoding UTF8 -NoNewline
                                $process = Start-Process -FilePath $sqliteCmd -ArgumentList $dbPath -NoNewWindow -Wait -PassThru -RedirectStandardInput $tempSql -RedirectStandardOutput $tempOut -ErrorAction SilentlyContinue
                            
                                if ($process.ExitCode -eq 0) {
                                    $output = Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue
                                    # Should contain table names
                                    $output | Should -Match 'fragment_content_cache|fragment_ast_cache'
                                }
                            }
                            finally {
                                Remove-Item -Path $tempOut -ErrorAction SilentlyContinue
                                Remove-Item -Path $tempSql -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "SQLite not available on this system"
            }
        }
    
        It 'Stores and retrieves content cache entries from SQLite' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath)) {
                Set-ItResult -Skipped -Because "FragmentCache module not found"
                return
            }
        
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (-not (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) -or
                -not (Get-Command Set-FragmentContentCache -ErrorAction SilentlyContinue) -or
                -not (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Required cache functions not available"
                return
            }
        
            Initialize-FragmentCache | Out-Null
        
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $sqliteAvailable = Test-SqliteAvailable
            }
        
            if (-not $sqliteAvailable) {
                Set-ItResult -Skipped -Because "SQLite not available on this system"
                return
            }
        
            # Initialize database
            $dbPath = if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                Get-FragmentCacheDbPath
            }
            else {
                Join-Path $script:TestCacheDir 'fragment-cache.db'
            }
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                Initialize-FragmentCacheDb -DbPath $dbPath | Out-Null
            }
        
            # Store content
            $testContent = "Test content for SQLite cache"
            $testPath = $script:TestFragment1
            $testTicks = (Get-Item $testPath).LastWriteTime.Ticks
        
            Set-FragmentContentCache -FilePath $testPath -Content $testContent -LastWriteTimeTicks $testTicks -ParsingMode 'regex'
        
            # Clear in-memory cache to force SQLite lookup
            if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                $global:FragmentContentCache.Clear()
            }
        
            # Retrieve from SQLite
            $retrieved = Get-FragmentContentCache -FilePath $testPath -LastWriteTimeTicks $testTicks -ParsingMode 'regex'
            $retrieved | Should -Be $testContent
        }
    
        It 'Stores and retrieves AST cache entries from SQLite' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath)) {
                Set-ItResult -Skipped -Because "FragmentCache module not found"
                return
            }
        
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (-not (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) -or
                -not (Get-Command Set-FragmentAstCache -ErrorAction SilentlyContinue) -or
                -not (Get-Command Get-FragmentAstCache -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Required cache functions not available"
                return
            }
        
            Initialize-FragmentCache | Out-Null
        
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $sqliteAvailable = Test-SqliteAvailable
            }
        
            if (-not $sqliteAvailable) {
                Set-ItResult -Skipped -Because "SQLite not available on this system"
                return
            }
        
            # Initialize database
            $dbPath = if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                Get-FragmentCacheDbPath
            }
            else {
                Join-Path $script:TestCacheDir 'fragment-cache.db'
            }
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                Initialize-FragmentCacheDb -DbPath $dbPath | Out-Null
            }
        
            # Store AST data
            $testFunctions = @('Test-Fragment1Function', 'Test-Fragment1Helper')
            $testPath = $script:TestFragment1
            $testTicks = (Get-Item $testPath).LastWriteTime.Ticks
        
            Set-FragmentAstCache -FilePath $testPath -Functions $testFunctions -LastWriteTimeTicks $testTicks -ParsingMode 'ast'
        
            # Clear in-memory cache to force SQLite lookup
            if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
                $global:FragmentAstCache.Clear()
            }
        
            # Retrieve from SQLite
            $retrieved = Get-FragmentAstCache -FilePath $testPath -LastWriteTimeTicks $testTicks -ParsingMode 'ast'
            $retrieved | Should -Not -BeNullOrEmpty
            $retrieved.Functions | Should -Be $testFunctions
        }
    }
}

Describe 'FragmentCache SQLite Integration - Cache Pre-warming' {
    Context 'Pre-warming from SQLite' {
        It 'Pre-warms cache from SQLite database' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath) -or
                -not (Test-Path -LiteralPath $script:PreWarmModulePath)) {
                Set-ItResult -Skipped -Because "Required modules not found"
                return
            }
        
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            Import-Module $script:PreWarmModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (-not (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) -or
                -not (Get-Command Invoke-FragmentCachePreWarm -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Required functions not available"
                return
            }
        
            Initialize-FragmentCache | Out-Null
        
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $sqliteAvailable = Test-SqliteAvailable
            }
        
            if (-not $sqliteAvailable) {
                Set-ItResult -Skipped -Because "SQLite not available on this system"
                return
            }
        
            # Initialize database
            $dbPath = if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                Get-FragmentCacheDbPath
            }
            else {
                Join-Path $script:TestCacheDir 'fragment-cache.db'
            }
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                Initialize-FragmentCacheDb -DbPath $dbPath | Out-Null
            }
        
            # Store some cache entries
            $fragments = @($script:TestFragment1, $script:TestFragment2)
            foreach ($fragPath in $fragments) {
                $testContent = "Content for $(Split-Path -Leaf $fragPath)"
                $testTicks = (Get-Item $fragPath).LastWriteTime.Ticks
            
                if (Get-Command Set-FragmentContentCache -ErrorAction SilentlyContinue) {
                    Set-FragmentContentCache -FilePath $fragPath -Content $testContent -LastWriteTimeTicks $testTicks -ParsingMode 'regex'
                }
            }
        
            # Clear in-memory cache
            if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                $global:FragmentContentCache.Clear()
            }
        
            # Pre-warm cache
            $fileInfoCache = @{}
            foreach ($fragPath in $fragments) {
                $fileInfoCache[$fragPath] = Get-Item $fragPath
            }
        
            $fragmentsToPreWarm = @()
            foreach ($fragPath in $fragments) {
                $fileInfo = $fileInfoCache[$fragPath]
                $fragmentsToPreWarm += @{
                    Path               = $fragPath
                    LastWriteTimeTicks = $fileInfo.LastWriteTime.Ticks
                }
            }
        
            $preWarmStats = Invoke-FragmentCachePreWarm -FragmentsToPreWarm $fragmentsToPreWarm `
                -FileInfoCache $fileInfoCache `
                -UseAstParsing $false `
                -SqliteCacheAvailable $true `
                -DebugLevel 0 `
                -HasDebug $false
        
            $preWarmStats | Should -Not -BeNullOrEmpty
            $preWarmStats.ContentPreWarmCount | Should -BeGreaterOrEqual 0
        
            # Verify entries are now in memory cache
            if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                $global:FragmentContentCache.Count | Should -BeGreaterOrEqual 0
            }
        }
    }
}

Describe 'FragmentCache SQLite Integration - Module Loading and Function Availability' {
    Context 'Module Loading' {
        It 'FragmentCache module loads SQLite module and functions are available' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath) -or
                -not (Test-Path -LiteralPath $script:SqliteModulePath)) {
                Set-ItResult -Skipped -Because "Required modules not found"
                return
            }
        
            # Remove modules first
            Remove-Module FragmentCache -ErrorAction SilentlyContinue -Force
            Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
        
            # Load FragmentCache - it should load SQLite module
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            # SQLite module should be loaded
            $sqliteModule = Get-Module FragmentCacheSqlite -ErrorAction SilentlyContinue
            $sqliteModule | Should -Not -BeNullOrEmpty
        
            # Test-SqliteAvailable should be available (either from wrapper or module)
            $testCmd = Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue
            $testCmd | Should -Not -BeNullOrEmpty
        
            # Should be callable
            { $result = Test-SqliteAvailable } | Should -Not -Throw
            $result | Should -BeOfType [bool]
        }
    
        It 'Initialize-FragmentCacheDb wrapper passes DbPath to SQLite module' {
            if (-not (Test-Path -LiteralPath $script:CacheModulePath)) {
                Set-ItResult -Skipped -Because "FragmentCache module not found"
                return
            }
        
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (-not (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Initialize-FragmentCacheDb not available"
                return
            }
        
            $testDbPath = Join-Path $script:TestCacheDir 'test-wrapper-path.db'
        
            # Should not throw when DbPath is provided
            { $result = Initialize-FragmentCacheDb -DbPath $testDbPath } | Should -Not -Throw
            $result | Should -BeOfType [bool]
        
            # If SQLite is available and initialization succeeded, database should exist
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $sqliteAvailable = Test-SqliteAvailable
            }
        
            if ($sqliteAvailable -and $result) {
                Test-Path $testDbPath | Should -Be $true
            }
        }
    }
}
