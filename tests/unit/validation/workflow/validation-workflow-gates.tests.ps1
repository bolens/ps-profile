<#
.SYNOPSIS
    Structural tests for blocking GitHub Actions validation gates.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:WorkflowRoot = Join-Path $script:RepoRoot '.github' 'workflows'
}

Describe 'Blocking workflow gates' {
    It 'Fails the commit-message job after publishing feedback' {
        $workflow = Get-Content -LiteralPath (Join-Path $script:WorkflowRoot 'commit-message-check.yml') -Raw

        $workflow | Should -Match '(?ms)- name: Fail validation\s+if:.*steps\.validate\.outputs\.status.*\s+run: exit 1'
    }

    It 'Does not suppress moderate-or-higher pnpm audit findings' {
        $workflow = Get-Content -LiteralPath (Join-Path $script:WorkflowRoot 'dependency-vulnerability-scan.yml') -Raw

        $workflow | Should -Match 'pnpm audit --audit-level=moderate'
        $workflow | Should -Not -Match '(?m)pnpm audit.*\|\| true'
        $workflow | Should -Not -Match '(?ms)id: pnpm-audit.*?continue-on-error:\s*true'
    }

    It 'Runs dependency failure feedback after a failed validation step' {
        $workflow = Get-Content -LiteralPath (Join-Path $script:WorkflowRoot 'dependency-validation.yml') -Raw

        $workflow | Should -Match "if: failure\(\) && github\.event_name == 'pull_request'"
    }

    It 'Awaits GitHub API comment requests' {
        $workflowFiles = Get-ChildItem -LiteralPath $script:WorkflowRoot -File |
            Where-Object Extension -In @('.yml', '.yaml')

        foreach ($workflowFile in $workflowFiles) {
            $workflow = Get-Content -LiteralPath $workflowFile.FullName -Raw
            $workflow | Should -Not -Match '(?m)^(?!\s*await\s+)\s*github\.rest\..*createComment\(' -Because "$($workflowFile.Name) must await comment delivery"
        }
    }
}
