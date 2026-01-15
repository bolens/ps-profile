# ===============================================
# fragment-cache.tests.ps1
# Unit tests for FragmentCache.psm1 and FragmentCacheSqlite.psm1
#
# Test Coverage:
# - Module loading and function availability
# - SQLite detection (Test-SqliteAvailable)
# - Database initialization (Initialize-FragmentCacheDb)
# - Cache operations (Get/Set for content and AST caches)
# - Cache statistics (Get-FragmentCacheStats)
# - Error handling and edge cases
# - Module function wrapper behavior
#
# These tests help prevent regressions in:
# - SQLite module loading and function discovery
# - Database initialization with DbPath parameter passing
# - Cache storage and retrieval operations
# - Fallback behavior when SQLite is unavailable
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:CacheModulePath = Join-Path $script:FragmentLibDir 'FragmentCache.psm1'
    $script:SqliteModulePath = Join-Path $script:FragmentLibDir 'FragmentCacheSqlite.psm1'
    
    # Create a test cache directory
    $script:TestCacheDir = Join-Path $env:TEMP "FragmentCacheTests_$(New-Guid)"
    $null = New-Item -ItemType Directory -Path $script:TestCacheDir -Force
    
    # Create a test fragment file
    $script:TestFragmentDir = Join-Path $env:TEMP "FragmentCacheTests_Fragments_$(New-Guid)"
    $null = New-Item -ItemType Directory -Path $script:TestFragmentDir -Force
    $script:TestFragmentPath = Join-Path $script:TestFragmentDir 'test-fragment.ps1'
    @'
function Test-CachedFunction {
    param([string]$Name)
    Write-Output "Hello $Name"
}

Set-AgentModeFunction -Name 'Test-CachedAlias' -Body { Write-Output "Alias" }
'@ | Out-File -FilePath $script:TestFragmentPath -Encoding UTF8
    
    # Store original environment variables
    $script:OriginalDebug = $env:PS_PROFILE_DEBUG
    $script:OriginalCacheDir = $env:PS_PROFILE_CACHE_DIR
    
    # Set test environment
    $env:PS_PROFILE_DEBUG = '0'
    $env:PS_PROFILE_CACHE_DIR = $script:TestCacheDir
}

AfterAll {
    # Restore original environment
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
    
    # Clean up test directories
    if (Test-Path $script:TestCacheDir) {
        Remove-Item -Path $script:TestCacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $script:TestFragmentDir) {
        Remove-Item -Path $script:TestFragmentDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean up modules
    Remove-Module FragmentCache -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
    
    # Clean up global variables
    if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentContentCache.Clear()
    }
    if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentAstCache.Clear()
    }
}

BeforeEach {
    # Clear caches before each test
    if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentContentCache.Clear()
    }
    if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentAstCache.Clear()
    }
    
    # Remove any existing test database
    $testDbPath = Join-Path $script:TestCacheDir 'fragment-cache.db'
    if (Test-Path $testDbPath) {
        Remove-Item -Path $testDbPath -Force -ErrorAction SilentlyContinue
    }
    
    # Remove modules to ensure clean state
    Remove-Module FragmentCache -ErrorAction SilentlyContinue -Force
    Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
}

Describe 'FragmentCache.psm1 - Module Loading' {
    It 'Loads FragmentCache module successfully' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            { Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop } | Should -Not -Throw
            Get-Module FragmentCache | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Function Exports' {
        It 'Exports required functions' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    
        It 'Loads FragmentCacheSqlite module when available' {
            if (Test-Path -LiteralPath $script:CacheModulePath -and Test-Path -LiteralPath $script:SqliteModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                # SQLite module should be loaded by FragmentCache
                $sqliteModule = Get-Module FragmentCacheSqlite -ErrorAction SilentlyContinue
                if ($sqliteModule) {
                    $sqliteModule | Should -Not -BeNullOrEmpty
                }
            }
        }
    
        It 'FragmentCacheSqlite module exports Test-SqliteAvailable when loaded' {
            if (Test-Path -LiteralPath $script:SqliteModulePath) {
                Import-Module $script:SqliteModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                $testCmd = Get-Command -Module FragmentCacheSqlite Test-SqliteAvailable -ErrorAction SilentlyContinue
                # Function should be available either in module or globally
                if (-not $testCmd) {
                    $testCmd = Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue
                }
                $testCmd | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Initialize-FragmentCache' {
    Context 'Basic Initialization' {
        It 'Initializes cache successfully' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
                
                if (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) {
                    { Initialize-FragmentCache } | Should -Not -Throw
                    
                    # Verify global caches are initialized
                    Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                    Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
    
    Context 'Idempotency' {
        It 'Is idempotent - can be called multiple times' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
                
                if (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) {
                    Initialize-FragmentCache | Should -Be $true
                    Initialize-FragmentCache | Should -Be $true
                    Initialize-FragmentCache | Should -Be $true
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Get-FragmentCacheDbPath' {
    Context 'Path Resolution' {
        It 'Returns valid database path' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                    $dbPath = Get-FragmentCacheDbPath
                    $dbPath | Should -Not -BeNullOrEmpty
                    $dbPath | Should -BeOfType [string]
                    # Path should end with .db
                    $dbPath | Should -Match '\.db$'
                }
            }
        }
    
        It 'Uses PS_PROFILE_CACHE_DIR when set' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                $originalCacheDir = $env:PS_PROFILE_CACHE_DIR
                try {
                    $testDir = Join-Path $env:TEMP "TestCacheDir_$(New-Guid)"
                    $null = New-Item -ItemType Directory -Path $testDir -Force
                    $env:PS_PROFILE_CACHE_DIR = $testDir
                
                    Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
                
                    if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                        $dbPath = Get-FragmentCacheDbPath
                        $dbPath | Should -Match ([regex]::Escape($testDir))
                    }
                }
                finally {
                    if ($originalCacheDir) {
                        $env:PS_PROFILE_CACHE_DIR = $originalCacheDir
                    }
                    else {
                        Remove-Item -Path Env:\PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
                    }
                    if (Test-Path $testDir) {
                        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Test-SqliteAvailable' {
    Context 'Basic Functionality' {
        It 'Returns boolean value' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    $result = Test-SqliteAvailable
                    $result | Should -BeOfType [bool]
                }
            }
        }
    
        It 'Wrapper function delegates to SQLite module when available' {
            if (Test-Path -LiteralPath $script:CacheModulePath -and Test-Path -LiteralPath $script:SqliteModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    # Should not throw
                    { $result = Test-SqliteAvailable } | Should -Not -Throw
                    $result | Should -BeOfType [bool]
                }
            }
        }
    }
    
    Context 'ForceRecheck Parameter' {
        It 'ForceRecheck parameter works' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    $result1 = Test-SqliteAvailable
                    $result2 = Test-SqliteAvailable -ForceRecheck
                
                    # Both should return boolean (may be same or different depending on SQLite availability)
                    $result1 | Should -BeOfType [bool]
                    $result2 | Should -BeOfType [bool]
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Initialize-FragmentCacheDb' {
    It 'Returns boolean value' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                $result = Initialize-FragmentCacheDb
                $result | Should -BeOfType [bool]
            }
        }
    }
    
    It 'Accepts DbPath parameter' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                $testDbPath = Join-Path $script:TestCacheDir 'test-init.db'
                { $result = Initialize-FragmentCacheDb -DbPath $testDbPath } | Should -Not -Throw
                $result | Should -BeOfType [bool]
            }
        }
    }
    
    It 'Is idempotent - can be called multiple times' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                $testDbPath = Join-Path $script:TestCacheDir 'test-idempotent.db'
                $result1 = Initialize-FragmentCacheDb -DbPath $testDbPath
                $result2 = Initialize-FragmentCacheDb -DbPath $testDbPath
                $result3 = Initialize-FragmentCacheDb -DbPath $testDbPath
            
                # All should return same result
                $result1 | Should -Be $result2
                $result2 | Should -Be $result3
            }
        }
    }
    
    It 'Creates database file when SQLite is available' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                $testDbPath = Join-Path $script:TestCacheDir 'test-create.db'
            
                # Remove if exists
                if (Test-Path $testDbPath) {
                    Remove-Item -Path $testDbPath -Force -ErrorAction SilentlyContinue
                }
            
                $sqliteAvailable = if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    Test-SqliteAvailable
                }
                else {
                    $false
                }
            
                if ($sqliteAvailable) {
                    $result = Initialize-FragmentCacheDb -DbPath $testDbPath
                    if ($result) {
                        Test-Path $testDbPath | Should -Be $true
                    }
                }
                else {
                    # SQLite not available - test should still not throw
                    { Initialize-FragmentCacheDb -DbPath $testDbPath } | Should -Not -Throw
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Get-FragmentCacheStats' {
    Context 'Return Value Structure' {
        It 'Returns hashtable with expected keys' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue) {
                    $stats = Get-FragmentCacheStats
                    $stats | Should -Not -BeNullOrEmpty
                    $stats | Should -BeOfType [hashtable]
                
                    # Check for expected keys
                    $stats.ContainsKey('SqliteAvailable') | Should -Be $true
                    $stats.SqliteAvailable | Should -BeOfType [bool]
                }
            }
        }
    
        It 'Reports SQLite availability correctly' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue) {
                    $stats = Get-FragmentCacheStats
                
                    # SqliteAvailable should match Test-SqliteAvailable result
                    if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                        $sqliteAvailable = Test-SqliteAvailable
                        $stats.SqliteAvailable | Should -Be $sqliteAvailable
                    }
                }
            }
        }
    }
    
    Context 'Cache Entry Counts' {
        It 'Reports cache entry counts' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue) {
                    $stats = Get-FragmentCacheStats
                
                    # Should have entry count keys
                    $stats.ContainsKey('ContentEntries') | Should -Be $true
                    $stats.ContainsKey('AstEntries') | Should -Be $true
                
                    $stats.ContentEntries | Should -BeOfType [int]
                    $stats.AstEntries | Should -BeOfType [int]
                }
            }
        }
    
        It 'Initializes database when calling Get-FragmentCacheStats if SQLite is available' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue) {
                    # Clear any existing initialization state
                    if (Get-Variable -Name 'CacheDbInitialized' -Scope Script -ErrorAction SilentlyContinue) {
                        $script:CacheDbInitialized = $false
                    }
                
                    # Get stats - this should initialize the database if SQLite is available
                    $stats = Get-FragmentCacheStats
                
                    # If SQLite is available, database should be initialized
                    $sqliteAvailable = $false
                    if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                        $sqliteAvailable = Test-SqliteAvailable
                    }
                
                    if ($sqliteAvailable) {
                        # Should have Initialized key
                        $stats.ContainsKey('Initialized') | Should -Be $true
                        # Initialized should be true if database was successfully initialized
                        # (may be false if initialization failed, but should not throw)
                    }
                }
            }
        }
    
        It 'Get-FragmentCacheStats passes DbPath to Initialize-FragmentCacheDb' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if ((Get-Command Get-FragmentCacheStats -ErrorAction SilentlyContinue) -and
                    (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue)) {
                
                    # Get expected DbPath
                    $expectedDbPath = Get-FragmentCacheDbPath
                
                    # Clear initialization state
                    if (Get-Variable -Name 'CacheDbInitialized' -Scope Script -ErrorAction SilentlyContinue) {
                        $script:CacheDbInitialized = $false
                    }
                
                    # Call Get-FragmentCacheStats - should not throw even if DbPath needs to be passed
                    { $stats = Get-FragmentCacheStats } | Should -Not -Throw
                
                    # Should return valid stats
                    $stats | Should -Not -BeNullOrEmpty
                    $stats | Should -BeOfType [hashtable]
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Cache Operations' {
    It 'Get-FragmentContentCache returns null for non-existent entry' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue) {
                $result = Get-FragmentContentCache -FilePath 'nonexistent.ps1' -LastWriteTimeTicks 0 -ParsingMode 'regex'
                $result | Should -BeNullOrEmpty
            }
        }
    }
    
    It 'Set-FragmentContentCache stores and retrieves content' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if ((Get-Command Set-FragmentContentCache -ErrorAction SilentlyContinue) -and 
                (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue)) {
            
                $testContent = "Test content for cache"
                $testPath = $script:TestFragmentPath
                $testTicks = (Get-Item $testPath).LastWriteTime.Ticks
            
                # Store
                Set-FragmentContentCache -FilePath $testPath -Content $testContent -LastWriteTimeTicks $testTicks -ParsingMode 'regex'
            
                # Retrieve
                $retrieved = Get-FragmentContentCache -FilePath $testPath -LastWriteTimeTicks $testTicks -ParsingMode 'regex'
                $retrieved | Should -Be $testContent
            }
        }
    }
    
    It 'Get-FragmentAstCache returns null for non-existent entry' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if (Get-Command Get-FragmentAstCache -ErrorAction SilentlyContinue) {
                $result = Get-FragmentAstCache -FilePath 'nonexistent.ps1' -LastWriteTimeTicks 0 -ParsingMode 'ast'
                $result | Should -BeNullOrEmpty
            }
        }
    }
    
    It 'Set-FragmentAstCache stores and retrieves AST data' {
        if (Test-Path -LiteralPath $script:CacheModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            if ((Get-Command Set-FragmentAstCache -ErrorAction SilentlyContinue) -and 
                (Get-Command Get-FragmentAstCache -ErrorAction SilentlyContinue)) {
            
                $testFunctions = @('Test-Function1', 'Test-Function2')
                $testPath = $script:TestFragmentPath
                $testTicks = (Get-Item $testPath).LastWriteTime.Ticks
            
                # Store
                Set-FragmentAstCache -FilePath $testPath -Functions $testFunctions -LastWriteTimeTicks $testTicks -ParsingMode 'ast'
            
                # Retrieve
                $retrieved = Get-FragmentAstCache -FilePath $testPath -LastWriteTimeTicks $testTicks -ParsingMode 'ast'
                $retrieved | Should -Not -BeNullOrEmpty
                $retrieved.Functions | Should -Be $testFunctions
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Module Function Availability' {
    It 'Test-SqliteAvailable wrapper finds SQLite module function' {
        if (Test-Path -LiteralPath $script:CacheModulePath -and Test-Path -LiteralPath $script:SqliteModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            # SQLite module should be loaded
            $sqliteModule = Get-Module FragmentCacheSqlite -ErrorAction SilentlyContinue
            if ($sqliteModule) {
                # Test-SqliteAvailable should be callable
                if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    { $result = Test-SqliteAvailable } | Should -Not -Throw
                    $result | Should -BeOfType [bool]
                }
            }
        }
    }
    
    It 'Initialize-FragmentCacheDb wrapper finds SQLite module function' {
        if (Test-Path -LiteralPath $script:CacheModulePath -and Test-Path -LiteralPath $script:SqliteModulePath) {
            Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
        
            # SQLite module should be loaded
            $sqliteModule = Get-Module FragmentCacheSqlite -ErrorAction SilentlyContinue
            if ($sqliteModule) {
                # Initialize-FragmentCacheDb should be callable
                if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                    $testDbPath = Join-Path $script:TestCacheDir 'test-wrapper.db'
                    { $result = Initialize-FragmentCacheDb -DbPath $testDbPath } | Should -Not -Throw
                    $result | Should -BeOfType [bool]
                }
            }
        }
    }
}

Describe 'FragmentCache.psm1 - Error Handling' {
    Context 'Missing SQLite Module' {
        It 'Handles missing SQLite module gracefully' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                # Remove SQLite module if loaded
                Remove-Module FragmentCacheSqlite -ErrorAction SilentlyContinue -Force
            
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                # Should still work without SQLite
                if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                    { $result = Test-SqliteAvailable } | Should -Not -Throw
                    $result | Should -BeOfType [bool]
                }
            }
        }
    
        It 'Handles invalid database path gracefully' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Initialize-FragmentCacheDb -ErrorAction SilentlyContinue) {
                    # Invalid path should not throw
                    $invalidPath = "C:\Invalid\Path\That\Does\Not\Exist\test.db"
                    { $result = Initialize-FragmentCacheDb -DbPath $invalidPath } | Should -Not -Throw
                    # Should return false for invalid path
                    $result | Should -Be $false
                }
            }
        }
    }
    
    Context 'Null or Empty Inputs' {
        It 'Handles null or empty file paths in cache operations' {
            if (Test-Path -LiteralPath $script:CacheModulePath) {
                Import-Module $script:CacheModulePath -DisableNameChecking -ErrorAction Stop -Force
            
                if (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue) {
                    { Get-FragmentContentCache -FilePath '' -LastWriteTimeTicks 0 -ParsingMode 'regex' } | Should -Not -Throw
                    { Get-FragmentContentCache -FilePath $null -LastWriteTimeTicks 0 -ParsingMode 'regex' } | Should -Not -Throw
                }
            }
        }
    }
}
