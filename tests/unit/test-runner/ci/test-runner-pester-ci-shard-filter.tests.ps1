#Requires -Version 7.0
Describe 'PesterCiShardFilter' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../../../scripts/utils/code-quality/modules/PesterCiShardFilter.psm1' | Resolve-Path
        Import-Module $modulePath -Force -DisableNameChecking
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

    It 'Builds Ubuntu-first matrix with Windows includes and Windows-only performance' {
        $matrix = Get-PesterCiShardMatrix -Shards @(
            'unit-library'
            'conversion-media'
            'performance-lang-core'
            'performance-profile-a'
        )
        $matrix | Where-Object { $_.os -eq 'ubuntu-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'unit-library' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'ubuntu-latest' -and $_.shard -like 'performance*' } | Should -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'performance-lang-core' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'performance-profile-a' } | Should -Not -BeNullOrEmpty
        $matrix | Where-Object { $_.os -eq 'windows-latest' -and $_.shard -eq 'conversion-media' } | Should -BeNullOrEmpty
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
}
