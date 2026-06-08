<#
tests/unit/utility-run-systematic-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-systematic-tests.ps1 category validation.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SystematicTestsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'test-verification' 'run-systematic-tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-systematic-tests.ps1 execution' {
    It 'Fails fast with available category names when an unknown category is requested' {
        $result = Invoke-TestScriptFile -ScriptPath $script:SystematicTestsScript -ArgumentList @(
            '-Category', 'DefinitelyMissingCategory'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Category ''DefinitelyMissingCategory'' not found'
        $result.Output | Should -Match 'Bootstrap|Performance|Unit'
    }

    It 'Runs a Bootstrap category batch in an isolated repository with a stub Pester runner' {
        $repo = New-TestTempDirectory -Prefix 'SystematicBootstrapStub'
        try {
            $bootstrapDir = Join-Path $repo 'tests' 'integration' 'bootstrap'
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $verificationDir = Join-Path $repo 'scripts' 'utils' 'test-verification'
            $null = New-Item -ItemType Directory -Path $bootstrapDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $verificationDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $bootstrapDir 'sample.tests.ps1') -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:SystematicTestsScript -Destination (Join-Path $verificationDir 'run-systematic-tests.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
                git add README.md
                git commit -m 'init' -q
            }
            finally {
                Pop-Location
            }

            $stubRunner = @'
param(
    [string]$TestFile,
    [string]$OutputPath
)
if ($OutputPath) {
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $xml = '<?xml version="1.0"?><test-results total="1" failures="0" errors="0" skipped="0" />'
    Set-Content -LiteralPath $OutputPath -Value $xml -Encoding UTF8
}
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $scriptPath = Join-Path $verificationDir 'run-systematic-tests.ps1'
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
                '-Category', 'Bootstrap'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Systematic Test Execution'
            $result.Output | Should -Match 'Running Bootstrap Tests'
            $result.Output | Should -Match 'Bootstrap.*Passed|Category.*Bootstrap'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the stub Pester runner reports Bootstrap test failures' {
        $repo = New-TestTempDirectory -Prefix 'SystematicBootstrapFailure'
        try {
            $bootstrapDir = Join-Path $repo 'tests' 'integration' 'bootstrap'
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $verificationDir = Join-Path $repo 'scripts' 'utils' 'test-verification'
            $null = New-Item -ItemType Directory -Path $bootstrapDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $verificationDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $bootstrapDir 'failing.tests.ps1') -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:SystematicTestsScript -Destination (Join-Path $verificationDir 'run-systematic-tests.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
                git add README.md
                git commit -m 'init' -q
            }
            finally {
                Pop-Location
            }

            $stubRunner = @'
param(
    [string]$TestFile,
    [string]$OutputPath
)
if ($OutputPath) {
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $xml = '<?xml version="1.0"?><test-results total="1" failures="1" errors="0" skipped="0" />'
    Set-Content -LiteralPath $OutputPath -Value $xml -Encoding UTF8
}
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $verificationDir 'run-systematic-tests.ps1') -ArgumentList @(
                '-Category', 'Bootstrap'
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Systematic Test Execution'
            $result.Output | Should -Match 'Bootstrap.*failures|Failed: [1-9]'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Runs only priority-1 categories when -Priority 1 is specified in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'SystematicPriorityOne'
        try {
            $priorityOneDirs = @(
                'bootstrap'
                'error-handling'
                'cross-platform'
                'utilities'
            )
            $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $verificationDir = Join-Path $repo 'scripts' 'utils' 'test-verification'
            $performanceDir = Join-Path $repo 'tests' 'performance'
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $verificationDir -Force
            $null = New-Item -ItemType Directory -Path $performanceDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $performanceDir 'perf-only.tests.ps1') -Force

            foreach ($category in $priorityOneDirs) {
                $categoryDir = Join-Path $repo 'tests' 'integration' $category
                $null = New-Item -ItemType Directory -Path $categoryDir -Force
                $null = New-Item -ItemType File -Path (Join-Path $categoryDir 'sample.tests.ps1') -Force
            }

            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:SystematicTestsScript -Destination (Join-Path $verificationDir 'run-systematic-tests.ps1') -Force

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'fixture' -Encoding UTF8
                git add README.md
                git commit -m 'init' -q
            }
            finally {
                Pop-Location
            }

            $stubRunner = @'
param(
    [string]$TestFile,
    [string]$OutputPath
)
if ($OutputPath) {
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $xml = '<?xml version="1.0"?><test-results total="1" failures="0" errors="0" skipped="0" passed="1" />'
    Set-Content -LiteralPath $OutputPath -Value $xml -Encoding UTF8
}
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $verificationDir 'run-systematic-tests.ps1') -ArgumentList @(
                '-Priority', '1'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Priority level: Up to 1'
            $result.Output | Should -Match 'Running Bootstrap Tests'
            $result.Output | Should -Not -Match 'Running Performance Tests'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
