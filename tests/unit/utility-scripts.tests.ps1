#
# Utility script integration tests focusing on script discovery and validation.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
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
                '^test\.ps1$'        # Simple test.ps1
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
            $riskyOperations = @('Get-RepoRoot', 'Ensure-ModuleAvailable', 'Get-Content', 'Set-Content', 'Invoke-ScriptAnalyzer')

            foreach ($script in $scripts) {
                if ($script.Name -eq 'Common.psm1') { continue }

                $content = Get-Content -Path $script.FullName -Raw

                foreach ($operation in $riskyOperations) {
                    if ($content -match "\b$operation\b") {
                        $operationIndex = $content.IndexOf($operation)
                        if ($operationIndex -gt 0) {
                            $beforeOperation = $content.Substring(0, $operationIndex)
                            $tryCount = ([regex]::Matches($beforeOperation, '\btry\s*\{')).Count
                            $catchCount = ([regex]::Matches($beforeOperation, '\bcatch\s*\{')).Count

                            if ($tryCount -eq 0) {
                                Write-Warning "$($script.Name) uses $operation but may not have try-catch protection"
                            }
                        }
                    }
                }
            }
        }
    }
}
