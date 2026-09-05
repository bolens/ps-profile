#Requires -Version 7.0
Describe 'PesterCiShardFilter' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../../../scripts/utils/code-quality/modules/PesterCiShardFilter.psm1' | Resolve-Path
        Import-Module $modulePath -Force -DisableNameChecking
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
        # Read the real definitions without executing a shard or its process exit.
        $runnerPath = Join-Path $repoRoot 'scripts/utils/code-quality/run-pester-ci-shard.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($runnerPath, [ref]$null, [ref]$null)
        $definitionFunction = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Get-PesterCiShardDefinitions'
        }, $true)
        . ([scriptblock]::Create($definitionFunction.Extent.Text))
        $definitions = Get-PesterCiShardDefinitions

        function Get-ShardTestFiles {
            param([string[]]$Paths)
            foreach ($path in $Paths) {
                $resolved = if ([System.IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $repoRoot $path }
                Test-Path -LiteralPath $resolved | Should -BeTrue -Because "shard path $path must exist"
                Get-ChildItem -LiteralPath $resolved -Filter '*.tests.ps1' -File -Recurse |
                    ForEach-Object { $_.FullName }
            }
        }
    }

    It 'Returns no shards for docs-only changes' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('docs/api/README.md', 'README.md')
        @($shards).Count | Should -Be 0
    }

    It 'Maps conversion module changes to conversion shards' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('profile.d/conversion-modules/data/core/csv.ps1')
        $shards | Should -Contain 'conversion-document-markdown-core'
        $shards | Should -Contain 'conversion-document-markdown-extra'
        $shards | Should -Contain 'conversion-document-other'
        $shards | Should -Contain 'conversion-data-structured-a'
        $shards | Should -Contain 'conversion-data-structured-n'
        $shards | Should -Contain 'conversion-data-structured-t'
        $shards | Should -Contain 'conversion-media'
        $shards | Should -Contain 'unit-profile-conversion'
        $shards | Should -Not -Contain 'unit-library'
    }

    It 'Maps library test changes to unit-library and coverage-smoke' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('tests/unit/library/common/library-common.tests.ps1')
        $shards | Should -Be @('coverage-smoke', 'unit-library')
    }

    It 'Maps unit-profile-core paths to split core shards' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('tests/unit/profile/lang/java/profile-lang-java-version.tests.ps1')
        $shards | Should -Contain 'unit-profile-core-lang'
        $shards | Should -Contain 'unit-profile-core-files'
        $shards | Should -Contain 'coverage-smoke'
        $shards | Should -Not -Contain 'unit-profile-core'
    }

    It 'Maps tools integration changes to all tools letter shards' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('tests/integration/tools/git.tests.ps1')
        $shards | Should -Contain 'integration-tools-ab'
        $shards | Should -Contain 'integration-tools-c'
        $shards | Should -Contain 'integration-tools-d'
        $shards | Should -Contain 'integration-tools-eh'
        $shards | Should -Contain 'integration-tools-il'
        $shards | Should -Contain 'integration-tools-m'
        $shards | Should -Contain 'integration-tools-s'
        $shards | Should -Not -Contain 'integration-tools'
        $shards | Should -Not -Contain 'integration-tools-a'
        $shards | Should -Not -Contain 'integration-tools-e'
    }

    It 'Enables full suite for CI contract changes' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('.github/workflows/test-pester.yml')
        $shards.Count | Should -Be (Get-PesterCiAllShards).Count
    }

    It 'Builds Ubuntu-first matrix with Windows/Arch includes and Windows-only performance' {
        $matrix = Get-PesterCiShardMatrix -Shards @(
            'unit-library'
            'conversion-media'
            'performance-lang-core'
            'performance-profile-a'
            'coverage-smoke'
        )
        $matrix | Where-Object { $_.label -eq 'ubuntu-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'windows-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'arch-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $archUnit = $matrix | Where-Object { $_.label -eq 'arch-latest' -and $_.shard -eq 'unit-library' } | Select-Object -First 1
        $archUnit.container | Should -Be 'archlinux:latest'
        $archUnit.os | Should -Be 'ubuntu-latest'
        $matrix | Where-Object { $_.label -eq 'ubuntu-latest' -and $_.shard -like 'performance*' } | Should -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'windows-latest' -and $_.shard -eq 'performance-lang-core' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'windows-latest' -and $_.shard -eq 'performance-profile-a' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'windows-latest' -and $_.shard -eq 'conversion-media' } | Should -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'arch-latest' -and $_.shard -eq 'conversion-media' } | Should -BeNullOrEmpty
        $matrix | Where-Object { $_.label -eq 'arch-latest' -and $_.shard -eq 'coverage-smoke' } | Should -Not -BeNullOrEmpty
    }

    It 'Accepts empty or blank shard lists without throwing' {
        @(Get-PesterCiShardMatrix -Shards @()) | Should -HaveCount 0
        @(Get-PesterCiShardMatrix -Shards @('')) | Should -HaveCount 0
        @(Get-PesterCiShardMatrix -Shards $null) | Should -HaveCount 0
    }

    It 'Returns a true empty array for workflow-only changes with no Pester shards' {
        $shards = @(Resolve-PesterCiShards -ChangedFiles @('.github/workflows/codeql.yml'))
        $shards.Count | Should -Be 0
        @($shards | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) | Should -HaveCount 0
        @(Get-PesterCiShardMatrix -Shards ([string[]]@($shards))) | Should -HaveCount 0
    }

    It 'Exposes a curated Arch shard set' {
        $arch = Get-PesterCiArchShards
        $arch | Should -Contain 'unit-library'
        $arch | Should -Contain 'coverage-smoke'
        $arch | Should -Not -Contain 'conversion-media'
    }

    It 'Does not expose retired fat shard names in the full set' {
        $all = Get-PesterCiAllShards
        $all | Should -Not -Contain 'integration-tools'
        $all | Should -Not -Contain 'integration-tools-a'
        $all | Should -Not -Contain 'integration-tools-e'
        $all | Should -Not -Contain 'unit-profile-core'
        $all | Should -Not -Contain 'unit-profile-core-boot-main'
        $all | Should -Not -Contain 'conversion-document'
        $all | Should -Not -Contain 'conversion-document-markdown'
        $all | Should -Not -Contain 'conversion-data-structured'
        $all | Should -Not -Contain 'conversion-data-structured-b'
        $all | Should -Not -Contain 'performance'
        $all | Should -Contain 'unit-profile-core-bootstrap'
        $all | Should -Not -Contain 'unit-profile-core-main'
        $all | Should -Contain 'unit-profile-core-main-a'
        $all | Should -Contain 'unit-profile-core-main-d'
        $all | Should -Contain 'integration-tools-eh'
        $all | Should -Contain 'conversion-document-markdown-core'
        $all | Should -Contain 'conversion-data-structured-n'
    }

    It 'Keeps the filter and executable shard inventories identical' {
        @(Get-PesterCiAllShards | Sort-Object) | Should -Be @($definitions.Keys | Sort-Object)
    }

    It 'Runs every main loader file exactly once in groups of at most two on both hosted platforms' {
        $names = @($definitions.Keys | Where-Object { $_ -like 'unit-profile-core-main-*' })
        $actual = @(
            foreach ($name in $names) {
                $definitions[$name].Paths.Count | Should -BeLessOrEqual 2
                $definitions[$name].MaxParallelThreads | Should -Be 1
                Get-ShardTestFiles -Paths $definitions[$name].Paths
            }
        )
        $expected = @(Get-ShardTestFiles -Paths @('tests/unit/profile/main'))
        @($actual | Sort-Object) | Should -Be @($expected | Sort-Object)
        @($actual | Select-Object -Unique).Count | Should -Be $actual.Count
        foreach ($name in $names) {
            $labels = @(Get-PesterCiShardMatrix -Shards @($name) | ForEach-Object { $_.label })
            $labels | Should -Be @('ubuntu-latest', 'windows-latest')
            Resolve-PesterCiShards -ChangedFiles @('tests/unit/profile/main/loader/example.tests.ps1') |
                Should -Contain $name
        }
    }

    It 'Preserves every integration-core file exactly once on Ubuntu Windows and Arch' {
        $names = @($definitions.Keys | Where-Object { $_ -like 'integration-core*' })
        $actual = @(
            foreach ($name in $names) {
                $definitions[$name].MaxParallelThreads | Should -Be 1
                Get-ShardTestFiles -Paths $definitions[$name].Paths
            }
        )
        $originalDirectories = @(
            'bootstrap', 'system', 'profile', 'filesystem', 'terminal', 'fragments',
            'test-runner', 'utilities', 'error-handling', 'validation', 'cross-platform', 'cloud-provider'
        ) | ForEach-Object { "tests/integration/$_" }
        $expected = @(Get-ShardTestFiles -Paths $originalDirectories)
        @($actual | Sort-Object) | Should -Be @($expected | Sort-Object)
        @($actual | Select-Object -Unique).Count | Should -Be $actual.Count
        foreach ($name in $names) {
            $labels = @(Get-PesterCiShardMatrix -Shards @($name) | ForEach-Object { $_.label })
            $labels | Should -Be @('ubuntu-latest', 'windows-latest', 'arch-latest')
            Resolve-PesterCiShards -ChangedFiles @('tests/integration/profile/loading.tests.ps1') |
                Should -Contain $name
            Resolve-PesterCiShards -ChangedFiles @('Microsoft.PowerShell_profile.ps1') |
                Should -Contain $name
        }
    }

    It 'Keeps nested integration files with relative root <RelativeRoot>' -ForEach @(
        @{ RelativeRoot = $false }
        @{ RelativeRoot = $true }
    ) {
        $repoRoot = Join-Path $TestDrive 'nested-repo'
        $relativeFiles = @(
            'tests/integration/profile/loading.tests.ps1'
            'tests/integration/profile/nested/loading.tests.ps1'
            'tests/integration/fragments/fragment-idempotency.tests.ps1'
            'tests/integration/fragments/nested/fragment-idempotency.tests.ps1'
            'tests/integration/fragments/fragment-loading-failures.tests.ps1'
            'tests/integration/fragments/nested/fragment-loading-failures.tests.ps1'
        )
        foreach ($relative in $relativeFiles) {
            $path = Join-Path $repoRoot $relative
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
            Set-Content -LiteralPath $path -Value '# fixture'
        }
        $absoluteRepoRoot = $repoRoot
        Push-Location $repoRoot
        try {
            if ($RelativeRoot) { $repoRoot = '.' }
            $nestedDefinitions = Get-PesterCiShardDefinitions
        }
        finally {
            Pop-Location
            $repoRoot = $absoluteRepoRoot
        }
        $nestedDefinitions['integration-core-profile'].Paths |
            Should -Be @(Join-Path $repoRoot 'tests/integration/profile/nested/loading.tests.ps1')
        @($nestedDefinitions['integration-core-fragments'].Paths).Count | Should -Be 2
        $nestedDefinitions['integration-core-fragments'].Paths |
            Should -Contain (Join-Path $repoRoot 'tests/integration/fragments/nested/fragment-idempotency.tests.ps1')
        $nestedDefinitions['integration-core-fragments'].Paths |
            Should -Contain (Join-Path $repoRoot 'tests/integration/fragments/nested/fragment-loading-failures.tests.ps1')
    }
}
