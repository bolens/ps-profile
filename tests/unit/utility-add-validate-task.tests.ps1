<#
tests/unit/utility-add-validate-task.tests.ps1

.SYNOPSIS
    Behavioral unit tests for add-validate-task.ps1 WhatIf execution.
#>

function global:New-AddValidateTaskFixtureRepository {
    $repo = New-TestTempDirectory -Prefix 'AddValidateTaskRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $taskParitySource = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'task-parity'
    $taskParityDest = Join-Path $scriptsDir 'utils' 'task-parity'
    Copy-Item -LiteralPath $taskParitySource -Destination $taskParityDest -Recurse -Force

    Set-Content -LiteralPath (Join-Path $repo 'package.json') -Value '{"name":"fixture","scripts":{}}' -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force | Out-Null

    return $repo
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:AddValidateTaskScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'task-parity' 'add-validate-task.ps1'
    $ConfirmPreference = 'None'
}

Describe 'add-validate-task.ps1 execution' {
    It 'WhatIf previews adding the validate task without modifying task runner files' {
        $repo = New-AddValidateTaskFixtureRepository
        $packageJson = Join-Path $repo 'package.json'
        $before = Get-Content -LiteralPath $packageJson -Raw

        try {
            Push-Location $repo
            try {
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'utils' 'task-parity' 'add-validate-task.ps1') -ArgumentList @('-WhatIf')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'validate|What if|WhatIf'
            Get-Content -LiteralPath $packageJson -Raw | Should -Be $before
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
