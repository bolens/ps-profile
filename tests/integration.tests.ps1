Describe 'Profile Integration Tests' {
    Context 'Profile loading in different environments' {
        It 'loads successfully in current PowerShell environment' {
            # Test that profile loads without throwing exceptions
            $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
            $testScript = @"
try {
    . '$profilePath'
    Write-Output 'PROFILE_LOADED_SUCCESSFULLY'
} catch {
    Write-Error "Profile failed to load: `$_"
    exit 1
}
"@

            $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
            Set-Content -Path $tempFile -Value $testScript -Encoding UTF8

            try {
                $result = & pwsh -NoProfile -File $tempFile 2>&1
                $result | Should Match 'PROFILE_LOADED_SUCCESSFULLY'
            }
            finally {
                # Ensure cleanup happens even if test fails
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                }
            }
            # Add delay to prevent resource exhaustion from multiple pwsh processes
            Start-Sleep -Milliseconds 200
        }

        It 'does not pollute global scope excessively' {
            # Test that loading the profile doesn't create an excessive number of unexpected global variables
            $before = Get-Variable -Scope Global | Measure-Object | Select-Object -ExpandProperty Count

            # Load profile in current session
            . (Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1')

            $after = Get-Variable -Scope Global | Measure-Object | Select-Object -ExpandProperty Count
            $increase = $after - $before

            # Allow some increase for expected profile variables, but not excessive
            $increase | Should BeLessThan 50
        }

        It 'maintains PowerShell execution policy compatibility' {
            # Test that profile doesn't require elevated execution policy
            $currentPolicy = Get-ExecutionPolicy
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

                $profilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
                $testScript = @"
. '$profilePath'
Write-Output 'EXECUTION_POLICY_COMPATIBLE'
"@

                $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
                Set-Content -Path $tempFile -Value $testScript -Encoding UTF8

                $result = & pwsh -NoProfile -File $tempFile 2>&1
                $result | Should Match 'EXECUTION_POLICY_COMPATIBLE'
            }
            finally {
                Set-ExecutionPolicy -ExecutionPolicy $currentPolicy -Scope Process -Force
                # Ensure cleanup happens even if test fails
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                }
            }
            # Add delay to prevent resource exhaustion
            Start-Sleep -Milliseconds 200
        }
    }

    Context 'Cross-platform compatibility' {
        It 'uses compatible path separators' {
            # Test that profile uses Join-Path or / for paths, not \
            $profileContent = Get-Content (Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1') -Raw

            # Should not contain hardcoded backslashes in paths (except in comments or strings that are meant to be)
            $hardcodedBackslashes = $profileContent | Select-String -Pattern '\\(?!\\)' -AllMatches
            # Allow some exceptions for known cases, but generally avoid hardcoded paths
            $hardcodedBackslashes.Matches.Count | Should BeLessThan 20
        }

        It 'handles missing commands gracefully' {
            # Test that profile handles missing external commands without crashing
            # This should not throw an exception even if some commands are missing
            { . (Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1') } | Should Not Throw
        }
    }

    Context 'Documentation generation' {
        It 'generates API documentation successfully' {
            $docsPath = Join-Path $PSScriptRoot '..\docs'
            $originalFiles = Get-ChildItem -Path $docsPath -Filter *.md | Measure-Object | Select-Object -ExpandProperty Count

            # Run the documentation generation
            & "$PSScriptRoot/..\scripts/utils/generate-docs.ps1"

            $newFiles = Get-ChildItem -Path $docsPath -Filter *.md | Measure-Object | Select-Object -ExpandProperty Count
            # Documentation generation should not fail and should maintain or increase file count
            ($newFiles -ge $originalFiles) | Should Be $true

            # Check that README.md exists and contains functions
            $readmePath = Join-Path $docsPath 'README.md'
            Test-Path $readmePath | Should Be $true
            $readmeContent = Get-Content $readmePath -Raw
            $readmeContent | Should Match '## Functions by Fragment'
            $readmeContent | Should Match '\[.*\]\(.*\.md\)'
            $readmeContent | Should Match 'Total Functions:'
            $readmeContent | Should Match 'Generated:'
        }

        It 'documentation includes proper function signatures' {
            $docsPath = Join-Path $PSScriptRoot '..\docs'
            $setEnvVarDoc = Join-Path $docsPath 'Set-EnvVar.md'

            if (Test-Path $setEnvVarDoc) {
                $content = Get-Content $setEnvVarDoc -Raw
                $content | Should Match '## Synopsis'
                $content | Should Match '## Description'
                $content | Should Match '## Signature'
                $content | Should Match '## Parameters'
                $content | Should Match '## Examples'
                $content | Should Match '## Source'
                $content | Should Match '-Name'
                $content | Should Match '-Value'
                $content | Should Match 'powershell'
                $content | Should Match 'Defined in:'
            }
        }
    }

    Context 'Spellcheck functionality' {
        It 'spellcheck runs without errors' {
            # This should not throw an exception
            { & "$PSScriptRoot/..\scripts/utils/spellcheck.ps1" } | Should Not Throw
        }

        It 'cspell configuration includes custom words' {
            $cspellPath = Join-Path $PSScriptRoot '..\cspell.json'
            Test-Path $cspellPath | Should Be $true

            $cspellContent = Get-Content $cspellPath -Raw
            $cspellContent | Should Match '"HKCU"'
            $cspellContent | Should Match '"HKLM"'
            $cspellContent | Should Match '"SETTINGCHANGE"'
            $cspellContent | Should Match '"lpdw"'
        }
    }

    Context 'Linting and formatting' {
        It 'PSScriptAnalyzer runs without critical errors' {
            $profileFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot '..\profile.d') -Filter *.ps1
            foreach ($file in $profileFiles) {
                $result = Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule PSUseShouldProcessForStateChangingFunctions, PSAvoidUsingEmptyCatchBlock, PSUseBOMForUnicodeEncodedFile, PSUseDeclaredVarsMoreThanAssignments, PSUseApprovedVerbs, PSAvoidUsingWriteHost
                # Should not have any errors (warnings are ok)
                $errors = $result | Where-Object { $_.Severity -eq 'Error' }
                $errors | Should BeNullOrEmpty
            }
        }
    }
}
