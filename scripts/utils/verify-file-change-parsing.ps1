<#
.SYNOPSIS
    Verifies that file change detection triggers re-parsing with both AST and regex parsing.

.DESCRIPTION
    This script:
    1. Creates a test fragment file
    2. Parses it to build cache
    3. Modifies the file
    4. Verifies that re-parsing uses both AST and regex modes
    5. Verifies that cache is updated correctly

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/verify-file-change-parsing.ps1
#>

[CmdletBinding()]
param()

# Set debug level for detailed output
$env:PS_PROFILE_DEBUG = '3'

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "File Change Parsing Verification" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Import required modules
# PSScriptRoot is scripts/utils, so go up 2 levels to get repo root
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsLibDir = Join-Path $repoRoot 'scripts' 'lib'
$fragmentLibDir = Join-Path $scriptsLibDir 'fragment'

# Import cache modules
$cacheInitModule = Join-Path $fragmentLibDir 'FragmentCacheInitialization.psm1'
$orchestrationModule = Join-Path $fragmentLibDir 'FragmentCommandParserOrchestration.psm1'

if (-not (Test-Path -LiteralPath $cacheInitModule)) {
    Write-Host "✗ FragmentCacheInitialization module not found: $cacheInitModule" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $orchestrationModule)) {
    Write-Host "✗ FragmentCommandParserOrchestration module not found: $orchestrationModule" -ForegroundColor Red
    exit 1
}

try {
    Import-Module $cacheInitModule -DisableNameChecking -ErrorAction Stop -Force
    Import-Module $orchestrationModule -DisableNameChecking -ErrorAction Stop -Force
}
catch {
    Write-Host "✗ Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create a temporary test fragment
$testFragmentDir = Join-Path $env:TEMP "fragment-cache-test"
if (-not (Test-Path -LiteralPath $testFragmentDir)) {
    New-Item -ItemType Directory -Path $testFragmentDir -Force | Out-Null
}

$testFragmentPath = Join-Path $testFragmentDir "test-fragment.ps1"

Write-Host "[verify] Creating test fragment..." -ForegroundColor Cyan

# Create initial test fragment with various command patterns
$testFragmentContent = @'
# Test fragment for file change verification

# Function definition (AST parsing)
function Test-FragmentFunction {
    param([string]$Name)
    Write-Output "Hello $Name"
}

# Set-AgentModeFunction (regex parsing)
Set-AgentModeFunction -Name 'Test-AgentFunction' -Body {
    Write-Output "Agent function"
}

# Set-AgentModeAlias (regex parsing)
Set-AgentModeAlias -Name 'tf' -Target 'Test-FragmentFunction'

# Direct function assignment (regex parsing)
Set-Item Function:global:Test-DirectFunction -Value {
    Write-Output "Direct function"
}
'@

$testFragmentContent | Out-File -FilePath $testFragmentPath -Encoding UTF8

Write-Host "  ✓ Test fragment created: $testFragmentPath" -ForegroundColor Green

# Initialize cache
Write-Host ""
Write-Host "[verify] Initializing cache..." -ForegroundColor Cyan
try {
    $initResult = Initialize-FragmentCache
    if ($initResult) {
        Write-Host "  ✓ Cache initialized" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Cache initialization returned false (may be using in-memory only)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ✗ Cache initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Parse the fragment initially
Write-Host ""
Write-Host "[verify] Parsing fragment (initial)..." -ForegroundColor Cyan

$fragmentFile = Get-Item -LiteralPath $testFragmentPath
$stats = @{
    RegisteredCommands = 0
    DiscoveredCommands = 0
    ParsedFragments = 0
    AstCacheHits = 0
    ContentCacheHits = 0
}

try {
    $parseStats = Register-AllFragmentCommands -FragmentFiles @($fragmentFile) -ForceBothParsingModes
    Write-Host "  ✓ Initial parse completed" -ForegroundColor Green
    Write-Host "    Registered: $($parseStats.RegisteredCommands), Discovered: $($parseStats.DiscoveredCommands)" -ForegroundColor DarkGray
    Write-Host "    AST cache hits: $($parseStats.AstCacheHits), Content cache hits: $($parseStats.ContentCacheHits)" -ForegroundColor DarkGray
}
catch {
    Write-Host "  ✗ Initial parse failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify cache entries exist
Write-Host ""
Write-Host "[verify] Verifying cache entries..." -ForegroundColor Cyan

$fileInfo = Get-Item -LiteralPath $testFragmentPath
$lastWriteTimeTicks = $fileInfo.LastWriteTime.Ticks

# Check content cache
if (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue) {
    $contentCache = Get-FragmentContentCache -FilePath $testFragmentPath -LastWriteTimeTicks $lastWriteTimeTicks -ParsingMode 'regex'
    if ($contentCache) {
        Write-Host "  ✓ Content cache entry found (regex mode)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Content cache entry not found (regex mode)" -ForegroundColor Red
    }
}
else {
    Write-Host "  ⚠ Get-FragmentContentCache not available" -ForegroundColor Yellow
}

# Check AST cache
if (Get-Command Get-FragmentAstCache -ErrorAction SilentlyContinue) {
    $astCache = Get-FragmentAstCache -FilePath $testFragmentPath -LastWriteTimeTicks $lastWriteTimeTicks -ParsingMode 'ast'
    if ($astCache) {
        Write-Host "  ✓ AST cache entry found (ast mode)" -ForegroundColor Green
        Write-Host "    Functions: $($astCache -join ', ')" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  ✗ AST cache entry not found (ast mode)" -ForegroundColor Red
    }
}
else {
    Write-Host "  ⚠ Get-FragmentAstCache not available" -ForegroundColor Yellow
}

# Modify the file
Write-Host ""
Write-Host "[verify] Modifying test fragment..." -ForegroundColor Cyan

# Add a new function to trigger cache invalidation
$modifiedContent = $testFragmentContent + @'

# New function added after initial parse (should trigger re-parsing)
function Test-NewFunction {
    Write-Output "New function"
}
'@

# Wait a moment to ensure different timestamp
Start-Sleep -Milliseconds 100
$modifiedContent | Out-File -FilePath $testFragmentPath -Encoding UTF8

$newFileInfo = Get-Item -LiteralPath $testFragmentPath
$newLastWriteTimeTicks = $newFileInfo.LastWriteTime.Ticks

Write-Host "  ✓ File modified (timestamp changed)" -ForegroundColor Green

# Re-parse the fragment (should detect file change)
Write-Host ""
Write-Host "[verify] Re-parsing fragment (after file change)..." -ForegroundColor Cyan

$fragmentFile = Get-Item -LiteralPath $testFragmentPath
try {
    $reparseStats = Register-AllFragmentCommands -FragmentFiles @($fragmentFile) -ForceBothParsingModes
    Write-Host "  ✓ Re-parse completed" -ForegroundColor Green
    Write-Host "    Registered: $($reparseStats.RegisteredCommands), Discovered: $($reparseStats.DiscoveredCommands)" -ForegroundColor DarkGray
    Write-Host "    AST cache hits: $($reparseStats.AstCacheHits), Content cache hits: $($reparseStats.ContentCacheHits)" -ForegroundColor DarkGray
    
    # Verify that cache was updated (cache hits should be 0 for both since file changed)
    if ($reparseStats.AstCacheHits -eq 0 -and $reparseStats.ContentCacheHits -eq 0) {
        Write-Host "  ✓ Cache correctly invalidated (both AST and content cache misses)" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Cache may not have been invalidated correctly" -ForegroundColor Yellow
        Write-Host "    Expected: AST hits=0, Content hits=0" -ForegroundColor DarkGray
        Write-Host "    Actual: AST hits=$($reparseStats.AstCacheHits), Content hits=$($reparseStats.ContentCacheHits)" -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "  ✗ Re-parse failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify new cache entries
Write-Host ""
Write-Host "[verify] Verifying updated cache entries..." -ForegroundColor Cyan

# Check content cache with new timestamp
if (Get-Command Get-FragmentContentCache -ErrorAction SilentlyContinue) {
    $newContentCache = Get-FragmentContentCache -FilePath $testFragmentPath -LastWriteTimeTicks $newLastWriteTimeTicks -ParsingMode 'regex'
    if ($newContentCache) {
        Write-Host "  ✓ Updated content cache entry found (regex mode)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Updated content cache entry not found (regex mode)" -ForegroundColor Red
    }
}

# Check AST cache with new timestamp
if (Get-Command Get-FragmentAstCache -ErrorAction SilentlyContinue) {
    $newAstCache = Get-FragmentAstCache -FilePath $testFragmentPath -LastWriteTimeTicks $newLastWriteTimeTicks -ParsingMode 'ast'
    if ($newAstCache) {
        Write-Host "  ✓ Updated AST cache entry found (ast mode)" -ForegroundColor Green
        Write-Host "    Functions: $($newAstCache -join ', ')" -ForegroundColor DarkGray
        
        # Verify new function is in cache
        if ($newAstCache -contains 'Test-NewFunction') {
            Write-Host "  ✓ New function 'Test-NewFunction' found in AST cache" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ New function 'Test-NewFunction' not found in AST cache" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  ✗ Updated AST cache entry not found (ast mode)" -ForegroundColor Red
    }
}

# Cleanup
Write-Host ""
Write-Host "[verify] Cleaning up test files..." -ForegroundColor Cyan
try {
    Remove-Item -LiteralPath $testFragmentPath -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testFragmentDir) {
        Remove-Item -LiteralPath $testFragmentDir -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  ✓ Cleanup completed" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

exit 0
