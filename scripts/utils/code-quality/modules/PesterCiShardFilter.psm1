#Requires -Version 7.0
<#
.SYNOPSIS
    Maps changed repository paths to Pester CI shards (shared by GitHub Actions and local runners).
#>

Set-StrictMode -Version Latest

function Get-PesterCiFilterRules {
    <#
    .SYNOPSIS
        Returns ordered filter id → glob patterns and the shards each filter enables.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $unitProfileCoreShards = @(
        'unit-profile-core-lang'
        'unit-profile-core-files'
        'unit-profile-core-boot-main'
        'unit-profile-core-git-util-sys'
    )
    $integrationToolsShards = @(
        'integration-tools-a'
        'integration-tools-e'
        'integration-tools-m'
        'integration-tools-s'
    )
    $performanceShards = @(
        'performance-lang-core'
        'performance-profile-a'
        'performance-profile-b'
    )
    $conversionDocumentShards = @(
        'conversion-document-markdown'
        'conversion-document-other'
    )
    $conversionStructuredShards = @(
        'conversion-data-structured-a'
        'conversion-data-structured-b'
    )

    return [ordered]@{
        ci_contract = @{
            Patterns = @(
                '.github/workflows/test-pester.yml'
                'PSScriptAnalyzerSettings.psd1'
                'scripts/utils/code-quality/run-pester.ps1'
                'scripts/utils/code-quality/run-pester-ci-shard.ps1'
                'scripts/utils/code-quality/run-pester-changed-shards.ps1'
                'scripts/utils/code-quality/modules/PesterCiShardFilter.psm1'
                'scripts/utils/code-quality/run-*-batch.ps1'
                'scripts/utils/code-quality/modules/**'
            )
            Shards   = @('__ALL__')
        }
        profile_core = @{
            Patterns = @(
                'Microsoft.PowerShell_profile.ps1'
                'Modules/**'
                'scripts/lib/**'
                'scripts/checks/**'
                'profile.d/**'
            )
            # conversion-modules handled separately; exclude below in matcher
            ExcludePrefixes = @('profile.d/conversion-modules/')
            Shards = @(
                'unit-library', 'unit-utility', 'unit-support'
                'unit-profile-conversion'
            ) + $unitProfileCoreShards + @(
                'unit-profile-infra'
                'unit-profile-misc-a', 'unit-profile-misc-b'
                'integration-core'
            ) + $integrationToolsShards + @(
                'coverage-smoke'
            ) + $performanceShards
        }
        conversion = @{
            Patterns = @(
                'profile.d/conversion-modules/**'
                'tests/integration/conversion/**'
                'tests/unit/profile/conversion/**'
            )
            Shards = @(
                'unit-profile-conversion'
            ) + $conversionDocumentShards + @(
                'conversion-media'
            ) + $conversionStructuredShards + @(
                'conversion-data-units', 'conversion-data-encoding'
                'conversion-data-binary', 'conversion-data-compression', 'conversion-data-scientific'
                'conversion-data-misc'
            )
        }
        unit_library = @{
            Patterns = @('tests/unit/library/**')
            Shards   = @('unit-library', 'coverage-smoke')
        }
        unit_utility = @{
            Patterns = @('tests/unit/utility/**')
            Shards   = @('unit-utility')
        }
        unit_test_runner = @{
            Patterns = @('tests/unit/test-runner/**')
            Shards   = @('unit-test-runner')
        }
        unit_support = @{
            Patterns = @(
                'tests/unit/test-support/**'
                'tests/unit/validation/**'
                'tests/TestSupport.ps1'
                'tests/TestSupport/**'
            )
            Shards = @('unit-support', 'coverage-smoke')
        }
        unit_profile_conversion = @{
            Patterns = @('tests/unit/profile/conversion/**')
            Shards   = @('unit-profile-conversion')
        }
        unit_profile_core = @{
            Patterns = @(
                'tests/unit/profile/lang/**'
                'tests/unit/profile/files/**'
                'tests/unit/profile/bootstrap/**'
                'tests/unit/profile/main/**'
                'tests/unit/profile/git/**'
                'tests/unit/profile/utilities/**'
                'tests/unit/profile/system/**'
            )
            Shards = @($unitProfileCoreShards + @('coverage-smoke'))
        }
        unit_profile_infra = @{
            Patterns = @(
                'tests/unit/profile/dev-tools/**'
                'tests/unit/profile/cloud/**'
                'tests/unit/profile/api/**'
                'tests/unit/profile/ai/**'
                'tests/unit/profile/command/**'
                'tests/unit/profile/tool/**'
                'tests/unit/profile/embedded/**'
                'tests/unit/profile/containers/**'
                'tests/unit/profile/kubernetes/**'
                'tests/unit/profile/database/**'
                'tests/unit/profile/network/**'
                'tests/unit/profile/security/**'
                'tests/unit/profile/module/**'
                'tests/unit/profile/diagnostics/**'
            )
            Shards = @('unit-profile-infra')
        }
        unit_profile_misc = @{
            Patterns = @('tests/unit/profile/**')
            ExcludePrefixes = @(
                'tests/unit/profile/conversion/'
                'tests/unit/profile/lang/'
                'tests/unit/profile/files/'
                'tests/unit/profile/bootstrap/'
                'tests/unit/profile/main/'
                'tests/unit/profile/git/'
                'tests/unit/profile/utilities/'
                'tests/unit/profile/system/'
                'tests/unit/profile/dev-tools/'
                'tests/unit/profile/cloud/'
                'tests/unit/profile/api/'
                'tests/unit/profile/ai/'
                'tests/unit/profile/command/'
                'tests/unit/profile/tool/'
                'tests/unit/profile/embedded/'
                'tests/unit/profile/containers/'
                'tests/unit/profile/kubernetes/'
                'tests/unit/profile/database/'
                'tests/unit/profile/network/'
                'tests/unit/profile/security/'
                'tests/unit/profile/module/'
                'tests/unit/profile/diagnostics/'
            )
            Shards = @('unit-profile-misc-a', 'unit-profile-misc-b')
        }
        integration_tools = @{
            Patterns = @(
                'tests/integration/tools/**'
                'scripts/utils/code-quality/run-tools-integration-batch.ps1'
            )
            Shards = @($integrationToolsShards)
        }
        integration_core = @{
            Patterns = @(
                'tests/integration/bootstrap/**'
                'tests/integration/system/**'
                'tests/integration/profile/**'
                'tests/integration/filesystem/**'
                'tests/integration/terminal/**'
                'tests/integration/fragments/**'
                'tests/integration/test-runner/**'
                'tests/integration/utilities/**'
                'tests/integration/error-handling/**'
                'tests/integration/validation/**'
                'tests/integration/cross-platform/**'
                'tests/integration/cloud-provider/**'
            )
            Shards = @('integration-core')
        }
        performance = @{
            Patterns = @(
                'tests/performance/**'
                'scripts/utils/code-quality/run-performance-batch.ps1'
            )
            Shards = @($performanceShards)
        }
    }
}

function Get-PesterCiAllShards {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'unit-library', 'unit-utility', 'unit-test-runner', 'unit-support'
        'unit-profile-conversion'
        'unit-profile-core-lang', 'unit-profile-core-files'
        'unit-profile-core-boot-main', 'unit-profile-core-git-util-sys'
        'unit-profile-infra'
        'unit-profile-misc-a', 'unit-profile-misc-b'
        'integration-tools-a', 'integration-tools-e', 'integration-tools-m', 'integration-tools-s'
        'integration-core'
        'conversion-document-markdown', 'conversion-document-other', 'conversion-media'
        'conversion-data-structured-a', 'conversion-data-structured-b'
        'conversion-data-units', 'conversion-data-encoding'
        'conversion-data-binary', 'conversion-data-compression', 'conversion-data-scientific'
        'conversion-data-misc'
        'performance-lang-core', 'performance-profile-a', 'performance-profile-b'
        'coverage-smoke'
    )
}

function Get-PesterCiWindowsShards {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'unit-library'
        'unit-profile-core-lang', 'unit-profile-core-files'
        'unit-profile-core-boot-main', 'unit-profile-core-git-util-sys'
        'integration-tools-a', 'integration-tools-e', 'integration-tools-m', 'integration-tools-s'
        'integration-core'
        'performance-lang-core', 'performance-profile-a', 'performance-profile-b'
    )
}

function Test-PesterCiPathMatch {
    <#
    .SYNOPSIS
        Returns $true if a normalized repo-relative path matches a filter glob pattern.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $normalizedPath = ($Path -replace '\\', '/').TrimStart('./')
    $normalizedPattern = ($Pattern -replace '\\', '/').TrimStart('./')

    if ($normalizedPattern.EndsWith('/**')) {
        $prefix = $normalizedPattern.Substring(0, $normalizedPattern.Length - 3)
        return ($normalizedPath -eq $prefix -or $normalizedPath.StartsWith($prefix + '/'))
    }

    if ($normalizedPattern.Contains('*')) {
        # Translate simple globs: * = one path segment piece, ** = any depth
        $regex = [regex]::Escape($normalizedPattern) -replace '\\\*\\\*', '<<<DD>>>' -replace '\\\*', '[^/]*' -replace '<<<DD>>>', '.*'
        return $normalizedPath -match ('^' + $regex + '$')
    }

    return $normalizedPath -eq $normalizedPattern
}

function Test-PesterCiFileMatchesRule {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Rule
    )

    $normalizedPath = ($Path -replace '\\', '/').TrimStart('./')

    if ($Rule.ContainsKey('ExcludePrefixes') -and $Rule.ExcludePrefixes) {
        foreach ($prefix in $Rule.ExcludePrefixes) {
            $normPrefix = ($prefix -replace '\\', '/').TrimStart('./')
            if (-not $normPrefix.EndsWith('/')) { $normPrefix += '/' }
            if ($normalizedPath.StartsWith($normPrefix)) {
                return $false
            }
        }
    }

    foreach ($pattern in $Rule.Patterns) {
        if (Test-PesterCiPathMatch -Path $normalizedPath -Pattern $pattern) {
            return $true
        }
    }

    return $false
}

function Resolve-PesterCiShards {
    <#
    .SYNOPSIS
        Resolves CI shard names from a list of changed repository-relative paths.

    .PARAMETER ChangedFiles
        Repo-relative paths (forward or backslash). Empty with -All yields all shards.

    .PARAMETER All
        Force the full shard set (workflow_dispatch / CI contract).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string[]]$ChangedFiles = @(),

        [switch]$All
    )

    if ($All) {
        return @(Get-PesterCiAllShards)
    }

    $shards = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $rules = Get-PesterCiFilterRules
    $files = @($ChangedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
            ($_ -replace '\\', '/').TrimStart('./')
        })

    if ($files.Count -eq 0) {
        # Unary comma preserves empty [string[]] (bare `return @()` unwraps to $null).
        return , [string[]]@()
    }

    foreach ($ruleName in $rules.Keys) {
        $rule = $rules[$ruleName]
        $hit = $false
        foreach ($file in $files) {
            if (Test-PesterCiFileMatchesRule -Path $file -Rule $rule) {
                $hit = $true
                break
            }
        }
        if (-not $hit) { continue }

        if ($rule.Shards -contains '__ALL__') {
            return @(Get-PesterCiAllShards)
        }

        foreach ($shard in $rule.Shards) {
            [void]$shards.Add($shard)
        }
    }

    $ordered = [string[]]@($shards | Sort-Object)
    if ($ordered.Count -eq 0) {
        return , [string[]]@()
    }
    return $ordered
}

function Get-PesterCiShardMatrix {
    <#
    .SYNOPSIS
        Builds GitHub Actions matrix include entries for the given shards (Ubuntu-first).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Shards
    )

    $windowsShards = @(Get-PesterCiWindowsShards)
    $include = [System.Collections.Generic.List[object]]::new()

    foreach ($shard in ($Shards | Sort-Object -Unique)) {
        # Performance shards are Windows-only (historically flaky / slow on Ubuntu).
        if ($shard -notlike 'performance*') {
            $include.Add([pscustomobject]@{ os = 'ubuntu-latest'; shard = $shard })
        }
        if ($shard -in $windowsShards) {
            $include.Add([pscustomobject]@{ os = 'windows-latest'; shard = $shard })
        }
    }

    return @($include)
}

Export-ModuleMember -Function @(
    'Get-PesterCiFilterRules'
    'Get-PesterCiAllShards'
    'Get-PesterCiWindowsShards'
    'Test-PesterCiPathMatch'
    'Resolve-PesterCiShards'
    'Get-PesterCiShardMatrix'
)
