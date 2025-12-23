# ===============================================
# security-tools.ps1
# Security scanning and analysis tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Security tools fragment for secret scanning, vulnerability detection, and malware analysis.

.DESCRIPTION
    Provides wrapper functions for security scanning tools:
    - gitleaks: Secret scanning in Git repositories
    - trufflehog: Secret scanning with pattern detection
    - osv-scanner: Vulnerability scanning using OSV database
    - yara: Pattern matching for malware detection
    - clamav: Antivirus scanning
    - dangerzone: Safe document viewing

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'security-tools') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Gitleaks - Secret scanning in Git repositories
    # ===============================================

    <#
    .SYNOPSIS
        Scans a Git repository for secrets using gitleaks.
    
    .DESCRIPTION
        Runs gitleaks scan on the specified repository path. Gitleaks detects
        secrets, API keys, passwords, and other sensitive information in Git
        repositories.
    
    .PARAMETER RepositoryPath
        Path to the Git repository to scan. Defaults to current directory.
    
    .PARAMETER OutputFormat
        Output format: json, csv, sarif. Defaults to json.
    
    .PARAMETER ReportPath
        Optional path to save the scan report.
    
    .EXAMPLE
        Invoke-GitLeaksScan -RepositoryPath "C:\Projects\MyRepo"
    
        Scans the specified repository for secrets.
    
    .EXAMPLE
        Invoke-GitLeaksScan -OutputFormat "sarif" -ReportPath "scan-results.sarif"
    
        Scans current directory and saves results in SARIF format.
    
    .OUTPUTS
        System.String. Scan results in the specified format.
    #>
    function Invoke-GitLeaksScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromPipeline)]
            [string]$RepositoryPath = (Get-Location).Path,
            
            [ValidateSet('json', 'csv', 'sarif')]
            [string]$OutputFormat = 'json',
            
            [string]$ReportPath
        )

        if (-not (Test-CachedCommand 'gitleaks')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                $null
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gitleaks' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install gitleaks"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'gitleaks' -InstallHint $installHint
            }
            else {
                Write-Warning "gitleaks not found. $installHint"
            }
            return $null
        }

        $repoPath = if ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
            (Get-Location).Path
        }
        else {
            $RepositoryPath
        }

        if (-not (Test-Path -LiteralPath $repoPath -PathType Container)) {
            Write-Error "Repository path not found: $repoPath"
            return $null
        }

        $args = @('detect', '--source', $repoPath, '--format', $OutputFormat)

        if ($ReportPath) {
            $args += '--report-path', $ReportPath
        }
        else {
            $args += '--no-git'
        }

        try {
            $result = & gitleaks $args 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run gitleaks: $($_.Exception.Message)"
            return $null
        }
    }

    # Register function and alias
    if (-not (Test-Path Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-GitLeaksScan' -Body ${function:Invoke-GitLeaksScan}
        Set-AgentModeAlias -Name 'gitleaks-scan' -Target 'Invoke-GitLeaksScan'
    }

    # ===============================================
    # TruffleHog - Secret scanning with pattern detection
    # ===============================================

    <#
    .SYNOPSIS
        Scans for secrets using TruffleHog.
    
    .DESCRIPTION
        Runs TruffleHog scan to detect secrets, API keys, and credentials
        using pattern matching and entropy analysis.
    
    .PARAMETER Path
        Path to scan (file, directory, or Git repository). Defaults to current directory.
    
    .PARAMETER OutputFormat
        Output format: json, yaml. Defaults to json.
    
    .EXAMPLE
        Invoke-TruffleHogScan -Path "C:\Projects\MyRepo"
    
        Scans the specified path for secrets.
    #>
    function Invoke-TruffleHogScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromPipeline)]
            [string]$Path = (Get-Location).Path,
            
            [ValidateSet('json', 'yaml')]
            [string]$OutputFormat = 'json'
        )

        process {
            if (-not (Test-CachedCommand 'trufflehog')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    $null
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'trufflehog' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install trufflehog"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'trufflehog' -InstallHint $installHint
                }
                else {
                    Write-Warning "trufflehog not found. $installHint"
                }
                return $null
            }

            $scanPath = if ([string]::IsNullOrWhiteSpace($Path)) {
                (Get-Location).Path
            }
            else {
                $Path
            }

            if (-not (Test-Path -LiteralPath $scanPath)) {
                Write-Error "Path not found: $scanPath"
                return $null
            }

            try {
                $args = @('filesystem', $scanPath, "--$OutputFormat")
                $result = & trufflehog $args 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run trufflehog: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-TruffleHogScan -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-TruffleHogScan' -Body ${function:Invoke-TruffleHogScan}
        Set-AgentModeAlias -Name 'trufflehog-scan' -Target 'Invoke-TruffleHogScan'
    }

    # ===============================================
    # OSV-Scanner - Vulnerability scanning
    # ===============================================

    <#
    .SYNOPSIS
        Scans for vulnerabilities using OSV-Scanner.
    
    .DESCRIPTION
        Uses the OSV (Open Source Vulnerabilities) database to scan dependencies
        and identify known vulnerabilities in projects.
    
    .PARAMETER Path
        Path to the project to scan. Defaults to current directory.
    
    .PARAMETER OutputFormat
        Output format: json, table. Defaults to table.
    
    .EXAMPLE
        Invoke-OSVScan -Path "C:\Projects\MyProject"
    
        Scans the project for known vulnerabilities.
    #>
    function Invoke-OSVScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromPipeline)]
            [string]$Path = (Get-Location).Path,
            
            [ValidateSet('json', 'table')]
            [string]$OutputFormat = 'table'
        )

        process {
            if (-not (Test-CachedCommand 'osv-scanner')) {
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                        Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                    }
                    else {
                        $null
                    }
                    Get-ToolInstallHint -ToolName 'osv-scanner' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install osv-scanner"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'osv-scanner' -InstallHint $installHint
                }
                else {
                    Write-Warning "osv-scanner not found. $installHint"
                }
                return $null
            }

            $scanPath = if ([string]::IsNullOrWhiteSpace($Path)) {
                (Get-Location).Path
            }
            else {
                $Path
            }

            if (-not (Test-Path -LiteralPath $scanPath)) {
                Write-Error "Path not found: $scanPath"
                return $null
            }

            try {
                $args = @('--format', $OutputFormat, $scanPath)
                $result = & osv-scanner $args 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run osv-scanner: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-OSVScan -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-OSVScan' -Body ${function:Invoke-OSVScan}
        Set-AgentModeAlias -Name 'osv-scan' -Target 'Invoke-OSVScan'
    }

    # ===============================================
    # YARA - Pattern matching for malware detection
    # ===============================================

    <#
    .SYNOPSIS
        Scans files using YARA rules.
    
    .DESCRIPTION
        Uses YARA to scan files against pattern rules for malware detection
        and threat hunting.
    
    .PARAMETER FilePath
        Path to the file or directory to scan.
    
    .PARAMETER RulesPath
        Path to YARA rules file or directory.
    
    .PARAMETER Recursive
        Scan directories recursively.
    
    .EXAMPLE
        Invoke-YaraScan -FilePath "C:\Downloads\file.exe" -RulesPath "C:\Rules\malware.yar"
    
        Scans the file against the specified YARA rules.
    #>
    function Invoke-YaraScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$FilePath,
            
            [Parameter(Mandatory)]
            [string]$RulesPath,
            
            [switch]$Recursive
        )

        if (-not (Test-CachedCommand 'yara')) {
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    $null
                }
                Get-ToolInstallHint -ToolName 'yara' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install yara"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'yara' -InstallHint $installHint
            }
            else {
                Write-Warning "yara not found. $installHint"
            }
            return $null
        }

        if (-not (Test-Path -LiteralPath $FilePath)) {
            Write-Error "File path not found: $FilePath"
            return $null
        }

        if (-not (Test-Path -LiteralPath $RulesPath)) {
            Write-Error "Rules path not found: $RulesPath"
            return $null
        }

        try {
            $args = @()
            if ($Recursive) {
                $args += '-r'
            }
            $args += $RulesPath, $FilePath
            $result = & yara $args 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run yara: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-YaraScan -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-YaraScan' -Body ${function:Invoke-YaraScan}
        Set-AgentModeAlias -Name 'yara-scan' -Target 'Invoke-YaraScan'
    }

    # ===============================================
    # ClamAV - Antivirus scanning
    # ===============================================

    <#
    .SYNOPSIS
        Scans files or directories using ClamAV.
    
    .DESCRIPTION
        Uses ClamAV antivirus engine to scan for malware and viruses.
    
    .PARAMETER Path
        Path to file or directory to scan.
    
    .PARAMETER Recursive
        Scan directories recursively.
    
    .PARAMETER Quarantine
        Move infected files to quarantine directory.
    
    .EXAMPLE
        Invoke-ClamAVScan -Path "C:\Downloads" -Recursive
    
        Recursively scans the Downloads directory for malware.
    #>
    function Invoke-ClamAVScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$Path,
            
            [switch]$Recursive,
            
            [string]$Quarantine
        )

        if (-not (Test-CachedCommand 'clamscan')) {
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    $null
                }
                Get-ToolInstallHint -ToolName 'clamav' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install clamav"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'clamscan' -InstallHint $installHint
            }
            else {
                Write-Warning "clamscan (ClamAV) not found. $installHint"
            }
            return $null
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Path not found: $Path"
            return $null
        }

        try {
            $args = @()
            if ($Recursive) {
                $args += '-r'
            }
            if ($Quarantine) {
                if (-not (Test-Path -LiteralPath $Quarantine -PathType Container)) {
                    New-Item -ItemType Directory -Path $Quarantine -Force | Out-Null
                }
                $args += '--move', $Quarantine
            }
            $args += $Path
            $result = & clamscan $args 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run clamscan: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-ClamAVScan -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-ClamAVScan' -Body ${function:Invoke-ClamAVScan}
        Set-AgentModeAlias -Name 'clamav-scan' -Target 'Invoke-ClamAVScan'
    }

    # ===============================================
    # Dangerzone - Safe document viewing
    # ===============================================

    <#
    .SYNOPSIS
        Converts potentially dangerous documents to safe PDFs using Dangerzone.
    
    .DESCRIPTION
        Uses Dangerzone to convert PDFs, Office documents, and images to safe
        PDFs by rendering them in a sandboxed environment.
    
    .PARAMETER InputPath
        Path to the document to convert.
    
    .PARAMETER OutputPath
        Optional output path for the safe PDF. Defaults to input path with .safe.pdf extension.
    
    .EXAMPLE
        Invoke-DangerzoneConvert -InputPath "C:\Downloads\document.pdf"
    
        Converts the document to a safe PDF.
    #>
    function Invoke-DangerzoneConvert {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$InputPath,
            
            [string]$OutputPath
        )

        if (-not (Test-CachedCommand 'dangerzone')) {
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    $null
                }
                Get-ToolInstallHint -ToolName 'dangerzone' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install dangerzone"
            }
            if ($installHint -notmatch 'Docker') {
                $installHint += ' (requires Docker)'
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'dangerzone' -InstallHint $installHint
            }
            else {
                Write-Warning "dangerzone not found. $installHint"
            }
            return $null
        }

        if (-not (Test-Path -LiteralPath $InputPath)) {
            Write-Error "Input file not found: $InputPath"
            return $null
        }

        try {
            $output = if ($OutputPath) {
                $OutputPath
            }
            else {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
                $dir = Split-Path -Parent $InputPath
                Join-Path $dir "$baseName.safe.pdf"
            }

            $result = & dangerzone --input $InputPath --output $output 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run dangerzone: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-DangerzoneConvert -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-DangerzoneConvert' -Body ${function:Invoke-DangerzoneConvert}
        Set-AgentModeAlias -Name 'dangerzone-convert' -Target 'Invoke-DangerzoneConvert'
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'security-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: security-tools' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load security-tools fragment: $($_.Exception.Message)"
    }
}
