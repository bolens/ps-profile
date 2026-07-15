#Requires -Version 7.0
Describe 'PesterCiShardFilter' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../../../scripts/utils/code-quality/modules/PesterCiShardFilter.psm1' | Resolve-Path
        Import-Module $modulePath -Force -DisableNameChecking
    }

    It 'Returns no shards for docs-only changes' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('docs/api/README.md', 'README.md')
        $shards.Count | Should -Be 0
    }

    It 'Maps conversion module changes to conversion shards' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('profile.d/conversion-modules/data/core/csv.ps1')
        $shards | Should -Contain 'conversion-document'
        $shards | Should -Contain 'conversion-media'
        $shards | Should -Contain 'unit-profile-conversion'
        $shards | Should -Not -Contain 'unit-library'
    }

    It 'Maps library test changes to unit-library and coverage-smoke' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('tests/unit/library/common/library-common.tests.ps1')
        $shards | Should -Be @('coverage-smoke', 'unit-library')
    }

    It 'Enables full suite for CI contract changes' {
        $shards = Resolve-PesterCiShards -ChangedFiles @('.github/workflows/test-pester.yml')
        $shards.Count | Should -Be (Get-PesterCiAllShards).Count
    }

    It 'Builds Ubuntu-first matrix with Windows includes' {
        $matrix = Get-PesterCiShardMatrix -Shards @('unit-library', 'conversion-media', 'performance')
        $matrix | Where-Object { $_.os -eq 'ubuntu-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'ubuntu-latest' -and $_.shard -eq 'performance' } | Should -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'performance' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'conversion-media' } | Should -BeNullOrEmpty
    }
}
