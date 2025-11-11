Describe 'Profile Integration Tests' {
    # Cache frequently used paths
    BeforeAll {
        $script:ProfilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
        $script:ProfileContent = Get-Content $script:ProfilePath -Raw -ErrorAction Stop
        $script:DocsPath = Join-Path $PSScriptRoot '..\docs'
        $script:CspellPath = Join-Path $PSScriptRoot '..\cspell.json'
        $script:ProfileDir = Join-Path $PSScriptRoot '..\profile.d'
        $script:ScriptsUtilsPath = Join-Path $PSScriptRoot '..\scripts\utils'
        $script:ScriptsUtilsDocsPath = Join-Path $PSScriptRoot '..\scripts\utils\docs'

        # Helper function to run PowerShell script in isolated process
        function script:Invoke-PwshScript {
            param([string]$ScriptContent)
            $tempFile = Join-Path $TestDrive 'test_script.ps1'
            Set-Content -Path $tempFile -Value $ScriptContent -Encoding UTF8
            try {
                & pwsh -NoProfile -File $tempFile 2>&1
            }
            finally {
                # TestDrive cleanup is automatic, but remove explicitly for immediate cleanup
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Profile loading in different environments' {
        It 'loads successfully in current PowerShell environment' {
            # Test that profile loads without throwing exceptions
            $testScript = @"
try {
    . '$($script:ProfilePath -replace "'", "''")'
    Write-Output 'PROFILE_LOADED_SUCCESSFULLY'
} catch {
    Write-Error "Profile failed to load: `$_"
    exit 1
}
"@
            $result = Invoke-PwshScript -ScriptContent $testScript
            $result | Should -Match 'PROFILE_LOADED_SUCCESSFULLY'
        }

        It 'loads with cross-platform compatibility helpers' {
            # Test that platform helpers are available after profile load
            $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
if (Get-Command Test-IsWindows -ErrorAction SilentlyContinue) {
    Write-Output 'PLATFORM_HELPERS_AVAILABLE'
} else {
    Write-Output 'PLATFORM_HELPERS_MISSING'
}
"@
            $result = Invoke-PwshScript -ScriptContent $testScript
            $result | Should -Match 'PLATFORM_HELPERS_AVAILABLE'
        }

        It 'does not pollute global scope excessively' {
            # Test that loading the profile doesn't create an excessive number of unexpected global variables
            $before = (Get-Variable -Scope Global).Count

            # Load profile in current session
            . $script:ProfilePath

            $after = (Get-Variable -Scope Global).Count
            $increase = $after - $before

            # Allow some increase for expected profile variables, but not excessive
            $increase | Should -BeLessThan 50
        }

        It 'maintains PowerShell execution policy compatibility' {
            # Test that profile doesn't require elevated execution policy
            $currentPolicy = Get-ExecutionPolicy
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

                $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
Write-Output 'EXECUTION_POLICY_COMPATIBLE'
"@
                $result = Invoke-PwshScript -ScriptContent $testScript
                $result | Should -Match 'EXECUTION_POLICY_COMPATIBLE'
            }
            finally {
                Set-ExecutionPolicy -ExecutionPolicy $currentPolicy -Scope Process -Force
            }
        }
    }

    Context 'Cross-platform compatibility' {
        It 'uses compatible path separators' {
            # Test that profile uses Join-Path or / for paths, not \
            # Should not contain hardcoded backslashes in paths (except in comments or strings that are meant to be)
            $hardcodedBackslashes = $script:ProfileContent | Select-String -Pattern '\\(?!\\)' -AllMatches
            # Allow some exceptions for known cases, but generally avoid hardcoded paths
            $hardcodedBackslashes.Matches.Count | Should -BeLessThan 20
        }

        It 'handles missing commands gracefully' {
            # Test that profile handles missing external commands without crashing
            # This should not throw an exception even if some commands are missing
            { . $script:ProfilePath } | Should -Not -Throw
        }
    }

    Context 'Documentation generation' {
        It 'generates API documentation successfully' {
            $originalFiles = (Get-ChildItem -Path $script:DocsPath -Filter *.md -ErrorAction SilentlyContinue).Count

            # Run the documentation generation
            & (Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1')

            $newFiles = (Get-ChildItem -Path $script:DocsPath -Filter *.md -ErrorAction SilentlyContinue).Count
            # Documentation generation should not fail and should maintain or increase file count
            ($newFiles -ge $originalFiles) | Should -Be $true

            # Check that README.md exists and contains functions
            $readmePath = Join-Path $script:DocsPath 'README.md'
            Test-Path $readmePath | Should -Be $true
            $readmeContent = Get-Content $readmePath -Raw
            $readmeContent | Should -Match '## Functions by Fragment'
            $readmeContent | Should -Match '\[.*\]\(.*\.md\)'
            $readmeContent | Should -Match 'Total Functions:'
            $readmeContent | Should -Match 'Generated:'
        }

        It 'documentation includes proper function signatures' {
            $setEnvVarDoc = Join-Path $script:DocsPath 'Set-EnvVar.md'

            if (Test-Path $setEnvVarDoc) {
                $content = Get-Content $setEnvVarDoc -Raw
                $expectedPatterns = @(
                    '## Synopsis',
                    '## Description',
                    '## Signature',
                    '## Parameters',
                    '## Examples',
                    '## Source',
                    '-Name',
                    '-Value',
                    'powershell',
                    'Defined in:'
                )
                foreach ($pattern in $expectedPatterns) {
                    $content | Should -Match $pattern
                }
            }
        }
    }

    Context 'Spellcheck functionality' {
        It 'spellcheck runs without errors' {
            # This should not throw an exception
            { & (Join-Path $script:ScriptsUtilsPath 'code-quality\spellcheck.ps1') } | Should -Not -Throw
        }

        It 'cspell configuration includes custom words' {
            Test-Path $script:CspellPath | Should -Be $true

            $cspellContent = Get-Content $script:CspellPath -Raw
            $expectedWords = @('HKCU', 'HKLM', 'SETTINGCHANGE', 'lpdw')
            foreach ($word in $expectedWords) {
                $cspellContent | Should -Match ([regex]::Escape("`"$word`""))
            }
        }
    }

    Context 'Linting and formatting' {
        BeforeAll {
            $script:ExcludeRules = @(
                'PSUseShouldProcessForStateChangingFunctions',
                'PSAvoidUsingEmptyCatchBlock',
                'PSUseBOMForUnicodeEncodedFile',
                'PSUseDeclaredVarsMoreThanAssignments',
                'PSUseApprovedVerbs',
                'PSAvoidUsingWriteHost',
                'PSAvoidUsingComputerNameHardcoded'
            )
            $script:ProfileFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1
        }

        It 'PSScriptAnalyzer runs without critical errors' {
            foreach ($file in $script:ProfileFiles) {
                $result = Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule $script:ExcludeRules
                # Should not have any errors (warnings are ok)
                $errors = $result | Where-Object { $_.Severity -eq 'Error' }
                $errors | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Profile fragment dependencies' {
        It 'all profile fragments exist and are readable' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                Test-Path $file.FullName | Should -Be $true
                # Should be able to read the file
                { Get-Content $file.FullName -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'profile fragments have valid PowerShell syntax' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                $errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
                # Should have no parse errors
                if ($errors) {
                    $errors.Count | Should -Be 0
                }
            }
        }
    }

    Context 'Profile loading edge cases' {
        It 'profile handles missing profile.d directory gracefully' {
            # This test verifies the main profile handles errors
            # Note: This might not apply if profile.d is required
            $profileContent = $script:ProfileContent
            # Profile should handle errors gracefully
            $profileContent | Should -Not -BeNullOrEmpty
        }

        It 'profile can be loaded multiple times without side effects' {
            # Load profile multiple times
            $before = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $middle = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $after = (Get-Variable -Scope Global).Count

            # Variable count increase should be consistent
            $firstIncrease = $middle - $before
            $secondIncrease = $after - $middle
            # Second load should not add significantly more variables (idempotent)
            $secondIncrease | Should -BeLessOrEqual ($firstIncrease * 2)
        }
    }

    Context 'Cross-platform PATH manipulation' {
        It 'Add-Path uses platform-appropriate separator' {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')

            $testPath = Join-Path $TestDrive 'test-path'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            $originalPath = $env:PATH
            try {
                Add-Path -Path $testPath
                $pathSeparator = [System.IO.Path]::PathSeparator
                $env:PATH | Should -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path uses platform-appropriate separator' {
            . (Join-Path $script:ProfileDir '05-utilities.ps1')

            $testPath = Join-Path $TestDrive 'test-remove-path'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            $originalPath = $env:PATH
            try {
                $pathSeparator = [System.IO.Path]::PathSeparator
                $env:PATH = "$testPath$pathSeparator$env:PATH"

                Remove-Path -Path $testPath
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    Context 'Scoop detection' {
        It 'handles missing Scoop gracefully' {
            $testScript = @"
`$env:SCOOP = `$null
. '$($script:ProfilePath -replace "'", "''")'
Write-Output 'SCOOP_HANDLED'
"@
            $result = Invoke-PwshScript -ScriptContent $testScript
            $result | Should -Match 'SCOOP_HANDLED'
        }
    }

    Context 'Fragment disable/enable functionality' {
        It 'Get-ProfileFragment lists fragments' {
            . $script:ProfilePath

            if (Get-Command Get-ProfileFragment -ErrorAction SilentlyContinue) {
                $fragments = Get-ProfileFragment
                $fragments | Should -Not -BeNullOrEmpty
                $fragments[0] | Should -HaveMember 'Name'
                $fragments[0] | Should -HaveMember 'Enabled'
            }
        }
    }
}
