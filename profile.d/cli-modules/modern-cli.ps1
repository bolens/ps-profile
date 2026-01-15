# ===============================================
# Modern CLI tools helper functions
# Modern CLI tool wrappers with command detection
# ===============================================

<#
Register modern CLI tools helpers using standardized Register-ToolWrapper function.
This replaces the previous repetitive pattern with a clean, maintainable approach.
#>

# bat - cat clone with syntax highlighting and Git integration
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

# fd - find files and directories
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'

# http - command-line HTTP client
Register-ToolWrapper -FunctionName 'http' -CommandName 'http' -WarningMessage 'httpie (http) not found' -InstallHint 'Install with: scoop install httpie'

# zoxide - smarter cd command
Register-ToolWrapper -FunctionName 'zoxide' -CommandName 'zoxide' -InstallHint 'Install with: scoop install zoxide'

# delta - syntax-highlighting pager for git
Register-ToolWrapper -FunctionName 'delta' -CommandName 'delta' -InstallHint 'Install with: scoop install delta'

# tldr - simplified man pages
Register-ToolWrapper -FunctionName 'tldr' -CommandName 'tldr' -InstallHint 'Install with: scoop install tldr'

# procs - modern replacement for ps
Register-ToolWrapper -FunctionName 'procs' -CommandName 'procs' -InstallHint 'Install with: scoop install procs'

# dust - more intuitive du command
Register-ToolWrapper -FunctionName 'dust' -CommandName 'dust' -InstallHint 'Install with: scoop install dust'

# ===============================================
# Enhanced Modern CLI Wrapper Functions
# ===============================================

# Find-WithFd - Enhanced file finding
<#
.SYNOPSIS
    Finds files and directories using fd with enhanced options.

.DESCRIPTION
    Enhanced wrapper for fd (find alternative) with common search patterns,
    case-insensitive search, hidden files, and follow symlinks options.

.PARAMETER Pattern
    Search pattern (file name or path pattern).

.PARAMETER Path
    Starting directory for search. Defaults to current directory.

.PARAMETER Type
    File type filter: f (files), d (directories), l (symlinks).

.PARAMETER Extension
    File extension filter (e.g., "ps1", "md").

.PARAMETER CaseSensitive
    Enable case-sensitive search (default: false).

.PARAMETER Hidden
    Include hidden files and directories (default: false).

.PARAMETER FollowSymlinks
    Follow symbolic links (default: false).

.EXAMPLE
    Find-WithFd -Pattern "test"
    
    Finds all files and directories containing "test" in the name.

.EXAMPLE
    Find-WithFd -Pattern "*.ps1" -Type f -Extension "ps1"
    
    Finds all PowerShell script files.

.EXAMPLE
    Find-WithFd -Pattern "config" -Path "C:\Users" -Hidden
    
    Finds config files including hidden ones.

.OUTPUTS
    System.String[]. Array of matching file/directory paths.
#>
function Find-WithFd {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,
        
        [string]$Path = (Get-Location).Path,
        
        [ValidateSet('f', 'd', 'l')]
        [string]$Type,
        
        [string]$Extension,
        
        [switch]$CaseSensitive,
        
        [switch]$Hidden,
        
        [switch]$FollowSymlinks
    )
    
    if (-not (Test-CachedCommand fd)) {
        Write-MissingToolWarning -Tool 'fd' -InstallHint 'Install with: scoop install fd'
        return
    }
    
    # Use standardized error handling if available
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        return Invoke-WithWideEvent -OperationName "cli.fd.find" -Context @{
            pattern         = $Pattern
            path            = $Path
            type            = $Type
            extension       = $Extension
            case_sensitive  = $CaseSensitive.IsPresent
            hidden          = $Hidden.IsPresent
            follow_symlinks = $FollowSymlinks.IsPresent
        } -ScriptBlock {
            $args = @()
            
            if ($Type) {
                $args += '--type', $Type
            }
            
            if ($Extension) {
                $args += '--extension', $Extension
            }
            
            if (-not $CaseSensitive) {
                $args += '--ignore-case'
            }
            
            if ($Hidden) {
                $args += '--hidden'
            }
            
            if ($FollowSymlinks) {
                $args += '--follow'
            }
            
            $args += $Pattern
            
            if ($Path -and $Path -ne (Get-Location).Path) {
                $args += $Path
            }
            
            $output = & fd $args 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                throw "fd search failed: $output"
            }
        }
    }
    else {
        # Fallback to original implementation
        try {
            $args = @()
            
            if ($Type) {
                $args += '--type', $Type
            }
            
            if ($Extension) {
                $args += '--extension', $Extension
            }
            
            if (-not $CaseSensitive) {
                $args += '--ignore-case'
            }
            
            if ($Hidden) {
                $args += '--hidden'
            }
            
            if ($FollowSymlinks) {
                $args += '--follow'
            }
            
            $args += $Pattern
            
            if ($Path -and $Path -ne (Get-Location).Path) {
                $args += $Path
            }
            
            $output = & fd $args 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                Write-Error "fd search failed: $output"
                return @()
            }
        }
        catch {
            Write-Error "Failed to execute fd: $_"
            return @()
        }
    }
}

# Grep-WithRipgrep - Enhanced text search
<#
.SYNOPSIS
    Searches text using ripgrep with enhanced options.

.DESCRIPTION
    Enhanced wrapper for ripgrep (rg) with line numbers, context lines,
    file type filtering, and case-insensitive search options.

.PARAMETER Pattern
    Text pattern to search for (regex supported).

.PARAMETER Path
    Directory or file to search in. Defaults to current directory.

.PARAMETER FileType
    File type filter (e.g., "ps1", "md", "json"). Uses ripgrep type filters.

.PARAMETER CaseSensitive
    Enable case-sensitive search (default: false).

.PARAMETER Context
    Number of context lines to show before and after matches.

.PARAMETER OnlyMatching
    Show only matching text, not full lines.

.PARAMETER FilesWithMatches
    Show only file names that contain matches.

.PARAMETER Hidden
    Search hidden files and directories (default: false).

.EXAMPLE
    Grep-WithRipgrep -Pattern "function"
    
    Searches for "function" in all files in current directory.

.EXAMPLE
    Grep-WithRipgrep -Pattern "error" -FileType "ps1" -Context 3
    
    Searches for "error" in PowerShell files with 3 lines of context.

.EXAMPLE
    Grep-WithRipgrep -Pattern "TODO" -FilesWithMatches
    
    Lists only files containing "TODO".

.OUTPUTS
    System.String. Search results from ripgrep.
#>
function Grep-WithRipgrep {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,
        
        [string]$Path = (Get-Location).Path,
        
        [string]$FileType,
        
        [switch]$CaseSensitive,
        
        [int]$Context = 0,
        
        [switch]$OnlyMatching,
        
        [switch]$FilesWithMatches,
        
        [switch]$Hidden
    )
    
    if (-not (Test-CachedCommand rg)) {
        Write-MissingToolWarning -Tool 'rg' -InstallHint 'Install with: scoop install ripgrep'
        return
    }
    
    # Use standardized error handling if available
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        return Invoke-WithWideEvent -OperationName "cli.ripgrep.grep" -Context @{
            pattern            = $Pattern
            path               = $Path
            file_type          = $FileType
            case_sensitive     = $CaseSensitive.IsPresent
            context            = $Context
            only_matching      = $OnlyMatching.IsPresent
            files_with_matches = $FilesWithMatches.IsPresent
            hidden             = $Hidden.IsPresent
        } -ScriptBlock {
            $args = @()
            
            if (-not $CaseSensitive) {
                $args += '--ignore-case'
            }
            
            if ($Context -gt 0) {
                $args += '-C', $Context.ToString()
            }
            
            if ($OnlyMatching) {
                $args += '-o'
            }
            
            if ($FilesWithMatches) {
                $args += '-l'
            }
            
            if ($Hidden) {
                $args += '--hidden'
            }
            
            if ($FileType) {
                $args += '-t', $FileType
            }
            
            $args += '--line-number'
            $args += $Pattern
            
            if ($Path -and $Path -ne (Get-Location).Path) {
                $args += $Path
            }
            
            $output = & rg $args 2>&1
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
                # Exit code 1 means no matches found, which is valid
                return $output
            }
            else {
                throw "ripgrep search failed: $output"
            }
        }
    }
    else {
        # Fallback to original implementation
        try {
            $args = @()
            
            if (-not $CaseSensitive) {
                $args += '--ignore-case'
            }
            
            if ($Context -gt 0) {
                $args += '-C', $Context.ToString()
            }
            
            if ($OnlyMatching) {
                $args += '-o'
            }
            
            if ($FilesWithMatches) {
                $args += '-l'
            }
            
            if ($Hidden) {
                $args += '--hidden'
            }
            
            if ($FileType) {
                $args += '-t', $FileType
            }
            
            $args += '--line-number'
            $args += $Pattern
            
            if ($Path -and $Path -ne (Get-Location).Path) {
                $args += $Path
            }
            
            $output = & rg $args 2>&1
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
                # Exit code 1 means no matches found, which is valid
                return $output
            }
            else {
                Write-Error "ripgrep search failed: $output"
                return ""
            }
        }
        catch {
            Write-Error "Failed to execute ripgrep: $_"
            return ""
        }
    }
}

# Navigate-WithZoxide - Smart directory navigation
<#
.SYNOPSIS
    Navigates to directories using zoxide's smart matching.

.DESCRIPTION
    Enhanced wrapper for zoxide (smart cd) that provides intelligent directory
    navigation based on usage frequency and fuzzy matching.

.PARAMETER Query
    Directory name or path to navigate to. Can be partial match.

.PARAMETER Interactive
    Use interactive mode to select from multiple matches.

.PARAMETER Add
    Add current directory to zoxide database.

.PARAMETER Remove
    Remove directory from zoxide database.

.PARAMETER QueryAll
    Query all directories in database.

.EXAMPLE
    Navigate-WithZoxide -Query "Documents"
    
    Navigates to the most frequently used directory matching "Documents".

.EXAMPLE
    Navigate-WithZoxide -Query "PowerShell" -Interactive
    
    Shows interactive menu if multiple matches found.

.EXAMPLE
    Navigate-WithZoxide -Add
    
    Adds current directory to zoxide database.

.OUTPUTS
    System.String. Path navigated to, or null if navigation failed.
#>
function Navigate-WithZoxide {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [string]$Query,
        
        [switch]$Interactive,
        
        [switch]$Add,
        
        [string]$Remove,
        
        [switch]$QueryAll
    )
    
    if (-not (Test-CachedCommand zoxide)) {
        Write-MissingToolWarning -Tool 'zoxide' -InstallHint 'Install with: scoop install zoxide'
        return
    }
    
    # Use standardized error handling if available
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        return Invoke-WithWideEvent -OperationName "cli.zoxide.navigate" -Context @{
            query       = $Query
            interactive = $Interactive.IsPresent
            add         = $Add.IsPresent
            remove      = $Remove
            query_all   = $QueryAll.IsPresent
        } -ScriptBlock {
            if ($Add) {
                & zoxide add (Get-Location).Path
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Added current directory to zoxide database" -ForegroundColor Green
                }
                return (Get-Location).Path
            }
            
            if ($Remove) {
                & zoxide remove $Remove
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Removed directory from zoxide database" -ForegroundColor Green
                }
                return
            }
            
            if ($QueryAll) {
                $output = & zoxide query --all 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                return @()
            }
            
            if ($Query) {
                $args = @()
                if ($Interactive) {
                    $args += '--interactive'
                }
                $args += $Query
                
                $result = & zoxide query $args 2>&1
                if ($LASTEXITCODE -eq 0 -and $result) {
                    Set-Location $result
                    return $result
                }
                else {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "No matching directory found for: $Query" -OperationName "cli.zoxide.navigate" -Context @{ query = $Query }
                    }
                    else {
                        Write-Warning "No matching directory found for: $Query"
                    }
                    return $null
                }
            }
            else {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "No query specified. Use -Query to navigate or -Add to add current directory." -OperationName "cli.zoxide.navigate"
                }
                else {
                    Write-Warning "No query specified. Use -Query to navigate or -Add to add current directory."
                }
                return $null
            }
        }
    }
    else {
        # Fallback to original implementation
        try {
            if ($Add) {
                & zoxide add (Get-Location).Path
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Added current directory to zoxide database" -ForegroundColor Green
                }
                return (Get-Location).Path
            }
            
            if ($Remove) {
                & zoxide remove $Remove
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Removed directory from zoxide database" -ForegroundColor Green
                }
                return
            }
            
            if ($QueryAll) {
                $output = & zoxide query --all 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                return @()
            }
            
            if ($Query) {
                $args = @()
                if ($Interactive) {
                    $args += '--interactive'
                }
                $args += $Query
                
                $result = & zoxide query $args 2>&1
                if ($LASTEXITCODE -eq 0 -and $result) {
                    Set-Location $result
                    return $result
                }
                else {
                    Write-Warning "No matching directory found for: $Query"
                    return $null
                }
            }
            else {
                Write-Warning "No query specified. Use -Query to navigate or -Add to add current directory."
                return $null
            }
        }
        catch {
            Write-Error "Failed to execute zoxide: $_"
            return $null
        }
    }
}

# View-WithBat - Syntax-highlighted file viewing
<#
.SYNOPSIS
    Views files with syntax highlighting using bat.

.DESCRIPTION
    Enhanced wrapper for bat (cat clone) with syntax highlighting, line numbers,
    Git integration, and paging support.

.PARAMETER Path
    File path to view. Can be a single file or multiple files.

.PARAMETER Language
    Explicitly set syntax highlighting language (e.g., "powershell", "markdown").

.PARAMETER LineNumbers
    Show line numbers (default: true).

.PARAMETER Plain
    Disable syntax highlighting (plain text mode).

.PARAMETER Pager
    Use pager for output (default: true if output is long).

.PARAMETER Wrap
    Wrap long lines (default: false).

.PARAMETER Theme
    Color theme to use (e.g., "dark", "light", "GitHub").

.EXAMPLE
    View-WithBat -Path "script.ps1"
    
    Views PowerShell script with syntax highlighting.

.EXAMPLE
    View-WithBat -Path "README.md" -Language "markdown" -Wrap
    
    Views markdown file with wrapping enabled.

.EXAMPLE
    View-WithBat -Path "file.txt" -Plain
    
    Views file as plain text without highlighting.

.OUTPUTS
    System.String. File contents with syntax highlighting.
#>
function View-WithBat {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]$Path,
        
        [string]$Language,
        
        [switch]$LineNumbers = $true,
        
        [switch]$Plain,
        
        [switch]$Pager,
        
        [switch]$Wrap,
        
        [string]$Theme
    )
    
    if (-not (Test-CachedCommand bat)) {
        Write-MissingToolWarning -Tool 'bat' -InstallHint 'Install with: scoop install bat'
        return
    }
    
    # Use standardized error handling if available
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        return Invoke-WithWideEvent -OperationName "cli.bat.view" -Context @{
            paths        = $Path
            language     = $Language
            line_numbers = $LineNumbers.IsPresent
            plain        = $Plain.IsPresent
            pager        = $Pager.IsPresent
            wrap         = $Wrap.IsPresent
            theme        = $Theme
        } -ScriptBlock {
            $args = @()
            
            if (-not $LineNumbers) {
                $args += '--no-line-numbers'
            }
            
            if ($Plain) {
                $args += '--plain'
            }
            
            if ($Pager) {
                $args += '--paging=always'
            }
            else {
                $args += '--paging=never'
            }
            
            if ($Wrap) {
                $args += '--wrap=auto'
            }
            else {
                $args += '--wrap=never'
            }
            
            if ($Language) {
                $args += '--language', $Language
            }
            
            if ($Theme) {
                $args += '--theme', $Theme
            }
            
            foreach ($filePath in $Path) {
                if (-not (Test-Path -LiteralPath $filePath)) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "File not found: $filePath" -OperationName "cli.bat.view" -Context @{ file_path = $filePath }
                    }
                    else {
                        Write-Warning "File not found: $filePath"
                    }
                    continue
                }
                
                $args += $filePath
            }
            
            if ($args.Count -eq 0) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "No valid files specified" -OperationName "cli.bat.view"
                }
                else {
                    Write-Warning "No valid files specified"
                }
                return
            }
            
            & bat $args
        }
    }
    else {
        # Fallback to original implementation
        try {
            $args = @()
            
            if (-not $LineNumbers) {
                $args += '--no-line-numbers'
            }
            
            if ($Plain) {
                $args += '--plain'
            }
            
            if ($Pager) {
                $args += '--paging=always'
            }
            else {
                $args += '--paging=never'
            }
            
            if ($Wrap) {
                $args += '--wrap=auto'
            }
            else {
                $args += '--wrap=never'
            }
            
            if ($Language) {
                $args += '--language', $Language
            }
            
            if ($Theme) {
                $args += '--theme', $Theme
            }
            
            foreach ($filePath in $Path) {
                if (-not (Test-Path -LiteralPath $filePath)) {
                    Write-Warning "File not found: $filePath"
                    continue
                }
                
                $args += $filePath
            }
            
            if ($args.Count -eq 0) {
                Write-Warning "No valid files specified"
                return
            }
            
            & bat $args
        }
        catch {
            Write-Error "Failed to execute bat: $_"
        }
    }
}

# Register enhanced functions
if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Find-WithFd' -Body ${function:Find-WithFd}
    Set-AgentModeFunction -Name 'Grep-WithRipgrep' -Body ${function:Grep-WithRipgrep}
    Set-AgentModeFunction -Name 'Navigate-WithZoxide' -Body ${function:Navigate-WithZoxide}
    Set-AgentModeFunction -Name 'View-WithBat' -Body ${function:View-WithBat}
}
else {
    # Fallback: direct function registration
    Set-Item -Path Function:Find-WithFd -Value ${function:Find-WithFd} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Grep-WithRipgrep -Value ${function:Grep-WithRipgrep} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Navigate-WithZoxide -Value ${function:Navigate-WithZoxide} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:View-WithBat -Value ${function:View-WithBat} -Force -ErrorAction SilentlyContinue
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ffd' -Target 'Find-WithFd'
    Set-AgentModeAlias -Name 'grg' -Target 'Grep-WithRipgrep'
    Set-AgentModeAlias -Name 'z' -Target 'Navigate-WithZoxide'
    Set-AgentModeAlias -Name 'vbat' -Target 'View-WithBat'
}
else {
    Set-Alias -Name 'ffd' -Value 'Find-WithFd' -ErrorAction SilentlyContinue
    Set-Alias -Name 'grg' -Value 'Grep-WithRipgrep' -ErrorAction SilentlyContinue
    Set-Alias -Name 'z' -Value 'Navigate-WithZoxide' -ErrorAction SilentlyContinue
    Set-Alias -Name 'vbat' -Value 'View-WithBat' -ErrorAction SilentlyContinue
}
