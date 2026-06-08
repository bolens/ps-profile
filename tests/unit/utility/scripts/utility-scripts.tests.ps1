#
# Utility script integration tests focusing on script discovery and validation.
#

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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ScriptsUtilsPath = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
    
    # Import FileSystem module to get Get-PowerShellScripts function
    $fileSystemModule = Join-Path $script:RepoRoot 'scripts' 'lib' 'file' 'FileSystem.psm1'
    if (Test-Path $fileSystemModule) {
        Import-Module $fileSystemModule -Force -DisableNameChecking
    }
}

Describe 'Utility Script Integration Tests' {
    Context 'Script File Existence' {
        It 'All utility scripts exist' {
            $expectedScripts = @(
                'run-lint.ps1',
                'run-format.ps1',
                'run-security-scan.ps1',
                'run-markdownlint.ps1',
                'find-duplicate-functions.ps1',
                'check-module-updates.ps1',
                'spellcheck.ps1'
            )

            foreach ($scriptName in $expectedScripts) {
                $scriptMatch = Get-ChildItem -Path $script:ScriptsUtilsPath -Filter $scriptName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                $scriptMatch | Should -Not -BeNullOrEmpty -Because "$scriptName should exist"
            }
        }
    }

    Context 'Script Syntax Validation' {
        It 'All utility scripts have valid PowerShell syntax' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsUtilsPath
            foreach ($script in $scripts) {
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize(
                    (Get-Content -Path $script.FullName -Raw),
                    [ref]$errors
                )
                $errors | Should -BeNullOrEmpty -Because "$($script.Name) should have valid syntax"
            }
        }
    }

    Context 'ModuleImport Pattern' {
        It 'Scripts use Import-LibModule pattern correctly' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsUtilsPath
            $excludedPatterns = @(
                '\.psm1$',           # Module files
                'test.*\.ps1$',      # Test scripts
                '.*test.*\.ps1$',    # Scripts with "test" in name
                '^test\.ps1$',       # Simple test.ps1
                '^build-fragment-cache\.ps1$',  # Bootstrapper — must direct-import lib before Import-LibModule is available
                '^clear-fragment-cache\.ps1$'   # Bootstrapper — same reason as build-fragment-cache
            )
            
            foreach ($script in $scripts) {
                # Skip excluded patterns
                $shouldExclude = $false
                foreach ($pattern in $excludedPatterns) {
                    if ($script.Name -match $pattern) {
                        $shouldExclude = $true
                        break
                    }
                }
                if ($shouldExclude) { continue }
                
                # Skip if script is in a modules subdirectory (these are module files)
                if ($script.FullName -match '\\modules\\') { continue }

                $content = Get-Content -Path $script.FullName -Raw
                # Scripts should use the new ModuleImport pattern
                $hasNewPattern = $content -match 'Import-LibModule'
                $hasNewPattern | Should -Be $true -Because "$($script.Name) should use Import-LibModule pattern for module imports"
            }
        }
    }

    Context 'Exit Code Usage' {
        It 'Scripts use Exit-WithCode instead of direct exit' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsUtilsPath
            foreach ($script in $scripts) {
                if ($script.Name -eq 'Common.psm1') { continue }

                $content = Get-Content -Path $script.FullName -Raw
                $exitPattern = [regex]::new('\bexit\s+\d+\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
                $matches = $exitPattern.Matches($content)

                foreach ($match in $matches) {
                    $beforeMatch = $content.Substring(0, $match.Index)
                    $lineStart = $beforeMatch.LastIndexOf("`n")
                    $line = if ($lineStart -ge 0) { $content.Substring($lineStart + 1, $match.Index - $lineStart - 1) } else { $content.Substring(0, $match.Index) }

                    if ($line -match '^\s*#' -or $line -match '@"|@"|@''|@''') {
                        continue
                    }

                    $match.Value | Should -BeNullOrEmpty -Because "$($script.Name) should use Exit-WithCode instead of direct exit"
                }
            }
        }
    }

    Context 'Error Handling' {
        It 'Scripts wrap risky operations in try-catch' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsUtilsPath
            # Focused on top-level operations that, if they throw, would abort the script entirely.
            # We verify that Get-RepoRoot calls (the bootstrap import that every script uses)
            # appear inside a try block somewhere in the file.
            $violations = @()

            foreach ($script in $scripts) {
                if ($script.Name -eq 'Common.psm1') { continue }

                $content = Get-Content -Path $script.FullName -Raw
                # Skip module files (psm1) and test scripts
                if ($script.Name -match '\.psm1$|test.*\.ps1$') { continue }
                # Skip scripts in modules/ subdirectory
                if ($script.FullName -match '[\\/]modules[\\/]') { continue }

                # If the script uses Get-RepoRoot but has zero try blocks, it has no error handling
                if ($content -match '\bGet-RepoRoot\b' -and $content -notmatch '\btry\s*\{') {
                    $violations += $script.Name
                }
            }

            $violations | Should -BeNullOrEmpty -Because "scripts using Get-RepoRoot should wrap it in try-catch to avoid unhandled exceptions: $($violations -join ', ')"
        }
    }
}
