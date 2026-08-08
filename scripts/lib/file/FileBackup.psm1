<#
scripts/lib/file/FileBackup.psm1

.SYNOPSIS
    Repository file backup, restore, and retention utilities.

.DESCRIPTION
    Stores script-created file backups under a gitignored .backups directory at the
    repository root. Each backup includes metadata so files can be restored without
    guessing the original path.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.0+
#>

Set-StrictMode -Version Latest

$script:RepoBackupDirName = '.backups'
$script:BackupTimestampFormat = 'yyyyMMddHHmmssfff'
$script:DefaultKeepCount = 10

# Import FileSystem for Ensure-DirectoryExists when available
$fileSystemModulePath = Join-Path $PSScriptRoot 'FileSystem.psm1'
if ($fileSystemModulePath -and (Test-Path -LiteralPath $fileSystemModulePath)) {
    Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

function Get-RepoBackupRoot {
    <#
    .SYNOPSIS
        Gets the repository backup root directory (.backups).

    .DESCRIPTION
        Resolves the gitignored backup root under a repository. When -Create is
        specified, ensures the directory exists before returning the path.

    .PARAMETER RepoRoot
        Absolute or relative path to the repository root.

    .PARAMETER Create
        Creates the backup root directory when it does not already exist.

    .OUTPUTS
        System.String. Path to the .backups directory.

    .EXAMPLE
        Get-RepoBackupRoot -RepoRoot $repoRoot -Create
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [switch]$Create
    )

    $backupRoot = Join-Path $RepoRoot $script:RepoBackupDirName
    if ($Create) {
        if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
            Ensure-DirectoryExists -Path $backupRoot
        }
        elseif (-not (Test-Path -LiteralPath $backupRoot)) {
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        }
    }

    return $backupRoot
}

function Get-RepoBackupCategoryPath {
    <#
    .SYNOPSIS
        Gets the backup directory for a category.

    .DESCRIPTION
        Returns .backups/<Category> under the repository root. Use -Create to
        ensure the category directory exists.

    .PARAMETER RepoRoot
        Path to the repository root.

    .PARAMETER Category
        Backup category name (for example, scripts or config).

    .PARAMETER Create
        Creates the category directory when it does not already exist.

    .OUTPUTS
        System.String. Path to the category backup directory.

    .EXAMPLE
        Get-RepoBackupCategoryPath -RepoRoot $repoRoot -Category 'scripts' -Create
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Category,

        [switch]$Create
    )

    $categoryPath = Join-Path (Get-RepoBackupRoot -RepoRoot $RepoRoot -Create:$Create) $Category
    if ($Create) {
        if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
            Ensure-DirectoryExists -Path $categoryPath
        }
        elseif (-not (Test-Path -LiteralPath $categoryPath)) {
            New-Item -ItemType Directory -Path $categoryPath -Force | Out-Null
        }
    }

    return $categoryPath
}

function Get-FileBackupBaseName {
    <#
    .SYNOPSIS
        Derives the leaf file name used when naming backups.

    .DESCRIPTION
        Returns the file name portion of a source path. Throws when the path
        does not resolve to a non-empty leaf name.

    .PARAMETER SourcePath
        Path to the file being backed up.

    .OUTPUTS
        System.String. Leaf file name from the source path.

    .EXAMPLE
        Get-FileBackupBaseName -SourcePath 'C:\repo\Taskfile.yml'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath
    )

    $leaf = Split-Path -Leaf $SourcePath
    if ([string]::IsNullOrWhiteSpace($leaf)) {
        throw "Could not determine backup base name for source path: $SourcePath"
    }

    return $leaf
}

function New-FileBackup {
    <#
    .SYNOPSIS
        Creates a timestamped backup of a file under .backups.

    .DESCRIPTION
        Copies the source file into .backups/<Category>/ and writes metadata used by
        Restore-FileBackup. Optionally prunes older backups for the same source file.

    .PARAMETER SourcePath
        File to back up.

    .PARAMETER RepoRoot
        Repository root that owns the .backups directory.

    .PARAMETER Category
        Backup category subdirectory under .backups.

    .PARAMETER KeepCount
        Number of recent backups to retain per source file when pruning.

    .PARAMETER SkipPrune
        Skips pruning older backups after creating a new one.

    .OUTPUTS
        PSCustomObject with BackupPath, SourcePath, Category, and CreatedAt properties.

    .EXAMPLE
        New-FileBackup -SourcePath $file -RepoRoot $repoRoot -Category 'scripts'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Category,

        [int]$KeepCount = $script:DefaultKeepCount,

        [switch]$SkipPrune
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Source file not found: $SourcePath"
    }

    $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
    $timestamp = Get-Date -Format $script:BackupTimestampFormat
    $baseName = Get-FileBackupBaseName -SourcePath $resolvedSource
    $categoryPath = Get-RepoBackupCategoryPath -RepoRoot $RepoRoot -Category $Category -Create
    $backupFileName = "$baseName.backup.$timestamp"
    $backupPath = Join-Path $categoryPath $backupFileName
    $metaPath = "$backupPath.meta.json"

    if ($PSCmdlet.ShouldProcess($resolvedSource, "Create backup at $backupPath")) {
        Copy-Item -LiteralPath $resolvedSource -Destination $backupPath -Force -ErrorAction Stop

        $metadata = [ordered]@{
            SourcePath = $resolvedSource
            Category   = $Category
            CreatedAt  = (Get-Date).ToUniversalTime().ToString('o')
            BackupPath = $backupPath
        }
        $metadata | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $metaPath -Encoding UTF8

        if (-not $SkipPrune -and $KeepCount -gt 0) {
            Remove-OldFileBackups -RepoRoot $RepoRoot -Category $Category -SourcePath $resolvedSource -KeepCount $KeepCount |
                Out-Null
        }

        return [pscustomobject]$metadata
    }

    return $null
}

function Get-FileBackups {
    <#
    .SYNOPSIS
        Lists backups stored under .backups.

    .DESCRIPTION
        Reads backup metadata files and returns matching entries sorted by
        CreatedAt descending. Filter by category and/or original source path.

    .PARAMETER RepoRoot
        Repository root that owns the .backups directory.

    .PARAMETER Category
        Optional category name to limit the search.

    .PARAMETER SourcePath
        Optional original source path to filter results.

    .OUTPUTS
        System.Object[]. Backup metadata objects sorted newest first.

    .EXAMPLE
        Get-FileBackups -RepoRoot $repoRoot -Category 'scripts'
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [string]$Category,

        [string]$SourcePath
    )

    $backupRoot = Get-RepoBackupRoot -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $backupRoot)) {
        return @()
    }

    $searchRoots = if ($Category) {
        @(Get-RepoBackupCategoryPath -RepoRoot $RepoRoot -Category $Category)
    }
    else {
        @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }

    $resolvedSource = if ($SourcePath) { (Resolve-Path -LiteralPath $SourcePath).Path } else { $null }
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($searchRoot in $searchRoots) {
        if (-not (Test-Path -LiteralPath $searchRoot)) {
            continue
        }

        $metaFiles = Get-ChildItem -LiteralPath $searchRoot -Filter '*.meta.json' -File -ErrorAction SilentlyContinue
        foreach ($metaFile in $metaFiles) {
            try {
                $metadata = Get-Content -LiteralPath $metaFile.FullName -Raw | ConvertFrom-Json
            }
            catch {
                continue
            }

            if ($resolvedSource -and $metadata.SourcePath -ne $resolvedSource) {
                continue
            }

            $results.Add([pscustomobject]@{
                    SourcePath = [string]$metadata.SourcePath
                    Category   = [string]$metadata.Category
                    CreatedAt  = [datetime]$metadata.CreatedAt
                    BackupPath = [string]$metadata.BackupPath
                    MetaPath   = $metaFile.FullName
                })
        }
    }

    return @($results | Sort-Object CreatedAt -Descending)
}

function Restore-FileBackup {
    <#
    .SYNOPSIS
        Restores a file from a backup.

    .DESCRIPTION
        Restores by explicit backup path or by selecting the latest backup for a source
        file within a category.

    .PARAMETER RepoRoot
        Repository root that owns the .backups directory.

    .PARAMETER BackupPath
        Explicit backup file path to restore.

    .PARAMETER DestinationPath
        Destination file path. Inferred from metadata when omitted.

    .PARAMETER Category
        Category used when restoring the latest backup for a source file.

    .PARAMETER SourcePath
        Original source path used with -Latest.

    .PARAMETER Latest
        Restores the newest backup for -SourcePath within -Category.

    .PARAMETER Force
        Overwrites an existing destination file.

    .OUTPUTS
        System.String. Restored destination path.

    .EXAMPLE
        Restore-FileBackup -RepoRoot $repoRoot -Latest -Category 'scripts' -SourcePath $file
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [string]$BackupPath,

        [string]$DestinationPath,

        [string]$Category,

        [string]$SourcePath,

        [switch]$Latest,

        [switch]$Force
    )

    if (-not $BackupPath) {
        if (-not $Latest -or -not $SourcePath) {
            throw 'Specify -BackupPath or use -Latest with -SourcePath.'
        }

        if (-not $Category) {
            throw 'Category is required when restoring the latest backup by source path.'
        }

        $candidate = Get-FileBackups -RepoRoot $RepoRoot -Category $Category -SourcePath $SourcePath | Select-Object -First 1
        if (-not $candidate) {
            throw "No backups found for source path '$SourcePath' in category '$Category'."
        }

        $BackupPath = $candidate.BackupPath
        if (-not $DestinationPath) {
            $DestinationPath = $candidate.SourcePath
        }
    }
    else {
        if (-not (Test-Path -LiteralPath $BackupPath -PathType Leaf)) {
            throw "Backup file not found: $BackupPath"
        }

        if (-not $DestinationPath) {
            $metaPath = "$BackupPath.meta.json"
            if (Test-Path -LiteralPath $metaPath) {
                $metadata = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
                $DestinationPath = [string]$metadata.SourcePath
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
        throw 'DestinationPath could not be determined. Provide -DestinationPath explicitly.'
    }

    if ((Test-Path -LiteralPath $DestinationPath) -and -not $Force) {
        throw "Destination already exists: $DestinationPath. Use -Force to overwrite."
    }

    if ($PSCmdlet.ShouldProcess($DestinationPath, "Restore from $BackupPath")) {
        $destinationParent = Split-Path -Parent $DestinationPath
        if ($destinationParent -and -not (Test-Path -LiteralPath $destinationParent)) {
            if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
                Ensure-DirectoryExists -Path $destinationParent
            }
            else {
                New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
            }
        }

        Copy-Item -LiteralPath $BackupPath -Destination $DestinationPath -Force -ErrorAction Stop
        return $DestinationPath
    }

    return $null
}

function Remove-OldFileBackups {
    <#
    .SYNOPSIS
        Prunes old backups by count and/or age.

    .DESCRIPTION
        Removes backup files and metadata that exceed -KeepCount per source file
        or are older than -MaxAgeDays. At least one retention rule must be set.

    .PARAMETER RepoRoot
        Repository root that owns the .backups directory.

    .PARAMETER Category
        Optional category name to limit pruning.

    .PARAMETER SourcePath
        Optional original source path to limit pruning.

    .PARAMETER KeepCount
        Maximum number of backups to retain per source file.

    .PARAMETER MaxAgeDays
        Removes backups older than this many days.

    .OUTPUTS
        System.Int32. Number of backups removed.

    .EXAMPLE
        Remove-OldFileBackups -RepoRoot $repoRoot -Category 'scripts' -KeepCount 5
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [string]$Category,

        [string]$SourcePath,

        [int]$KeepCount = 0,

        [int]$MaxAgeDays = 0
    )

    if ($KeepCount -le 0 -and $MaxAgeDays -le 0) {
        throw 'Specify -KeepCount and/or -MaxAgeDays greater than zero.'
    }

    $backups = Get-FileBackups -RepoRoot $RepoRoot -Category $Category -SourcePath $SourcePath
    if ($backups.Count -eq 0) {
        return 0
    }

    $toRemove = [System.Collections.Generic.List[object]]::new()
    $grouped = $backups | Group-Object -Property SourcePath

    foreach ($group in $grouped) {
        $sorted = @($group.Group | Sort-Object CreatedAt -Descending)
        if ($KeepCount -gt 0 -and $sorted.Count -gt $KeepCount) {
            foreach ($oldBackup in ($sorted | Select-Object -Skip $KeepCount)) {
                $toRemove.Add($oldBackup)
            }
        }
    }

    if ($MaxAgeDays -gt 0) {
        $cutoff = (Get-Date).AddDays(-$MaxAgeDays)
        foreach ($backup in $backups) {
            if ($backup.CreatedAt -lt $cutoff) {
                $toRemove.Add($backup)
            }
        }
    }

    $uniqueToRemove = @($toRemove | Sort-Object BackupPath -Unique)
    $removedCount = 0

    foreach ($backup in $uniqueToRemove) {
        if ($PSCmdlet.ShouldProcess($backup.BackupPath, 'Remove old backup')) {
            if (Test-Path -LiteralPath $backup.BackupPath) {
                Remove-Item -LiteralPath $backup.BackupPath -Force -ErrorAction SilentlyContinue
            }
            if ($backup.MetaPath -and (Test-Path -LiteralPath $backup.MetaPath)) {
                Remove-Item -LiteralPath $backup.MetaPath -Force -ErrorAction SilentlyContinue
            }
            $removedCount++
        }
    }

    return $removedCount
}

Export-ModuleMember -Function @(
    'Get-RepoBackupRoot'
    'Get-RepoBackupCategoryPath'
    'New-FileBackup'
    'Get-FileBackups'
    'Restore-FileBackup'
    'Remove-OldFileBackups'
)
