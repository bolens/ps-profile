# ===============================================
# find-unsafe-testpath.ps1
# Finds Test-Path calls that might receive null/empty paths
# ===============================================

<#
.SYNOPSIS
    Finds Test-Path calls that don't have null/empty checks.

.DESCRIPTION
    Searches for Test-Path calls that might receive null/empty paths and reports them.
    Focuses on calls that use variables directly without null checks.
#>

$repoRoot = if ($PSScriptRoot) { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) } else { Get-Location }

Write-Host "🔍 Searching for potentially unsafe Test-Path calls..." -ForegroundColor Cyan
Write-Host ""

# Patterns to find Test-Path calls that might be unsafe
$patterns = @(
    @{
        Pattern     = 'Test-Path\s+\$(\w+)'
        Description = 'Test-Path with variable (no null check)'
        Files       = @()
    },
    @{
        Pattern     = 'Test-Path\s+(\$[^)]+)'
        Description = 'Test-Path with expression (might be null)'
        Files       = @()
    }
)

# Search in profile fragments, modules, tests, and conversion modules
$searchPaths = @(
    'profile.d',
    'scripts/lib',
    'tests',
    'profile.d/conversion-modules'
)

$unsafeCalls = @()

foreach ($searchPath in $searchPaths) {
    $fullPath = Join-Path $repoRoot $searchPath
    if (-not (Test-Path $fullPath)) { continue }
    
    $files = Get-ChildItem -Path $fullPath -Recurse -Filter '*.ps1', '*.psm1' -File
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $lines = Get-Content $file.FullName
        $lineNum = 0
        
        foreach ($line in $lines) {
            $lineNum++
            
            # Skip comments and already-safe patterns
            if ($line -match '^\s*#') { continue }
            if ($line -match 'IsNullOrWhiteSpace|Test-SafePath|Test-ModulePath') { continue }
            
            # Check for Test-Path with variable
            if ($line -match 'Test-Path\s+\$(\w+)' -and 
                $line -notmatch 'IsNullOrWhiteSpace' -and
                $line -notmatch 'Test-SafePath' -and
                $line -notmatch 'Test-ModulePath') {
                
                $varName = $matches[1]
                
                # Check if previous lines have null checks (look back up to 3 lines)
                $hasNullCheck = $false
                $checkStart = [Math]::Max(0, $lineNum - 4)
                for ($i = $checkStart; $i -lt $lineNum; $i++) {
                    if ($lines[$i] -match "`$$varName.*IsNullOrWhiteSpace|`$$varName.*-and.*Test-Path") {
                        $hasNullCheck = $true
                        break
                    }
                }
                
                if (-not $hasNullCheck) {
                    $unsafeCalls += [PSCustomObject]@{
                        File     = $file.FullName.Replace($repoRoot, '').TrimStart('\', '/')
                        Line     = $lineNum
                        Code     = $line.Trim()
                        Variable = $varName
                    }
                }
            }
        }
    }
}

if ($unsafeCalls.Count -gt 0) {
    Write-Host "⚠️  Found $($unsafeCalls.Count) potentially unsafe Test-Path calls:" -ForegroundColor Yellow
    Write-Host ""
    
    $unsafeCalls | Group-Object File | ForEach-Object {
        Write-Host "📄 $($_.Name)" -ForegroundColor Cyan
        $_.Group | ForEach-Object {
            Write-Host "   Line $($_.Line): $($_.Code)" -ForegroundColor Gray
            Write-Host "   Variable: `$$($_.Variable)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    Write-Host "💡 Tip: Add null checks like:" -ForegroundColor Green
    Write-Host "   if (`$var -and -not [string]::IsNullOrWhiteSpace(`$var) -and (Test-Path -LiteralPath `$var))" -ForegroundColor Gray
}
else {
    Write-Host "✅ No obviously unsafe Test-Path calls found!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Note: This is a heuristic search. Some calls may be safe in context." -ForegroundColor DarkGray

