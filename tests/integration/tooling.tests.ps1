. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Tooling Integration Tests' {
    BeforeAll {
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
        $script:DocsPath = Get-TestPath -RelativePath 'docs' -StartPath $PSScriptRoot -EnsureExists
        $script:CspellPath = Get-TestPath -RelativePath 'cspell.json' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ScriptsUtilsPath = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
        $script:ScriptsUtilsDocsPath = Get-TestPath -RelativePath 'scripts\utils\docs' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Documentation generation' {
        It 'generates API documentation successfully' {
            $apiDocsPath = Join-Path $script:DocsPath 'api'
            $functionsPath = Join-Path $apiDocsPath 'functions'
            $aliasesPath = Join-Path $apiDocsPath 'aliases'

            & (Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1')

            # Verify new directory structure exists
            Test-Path $apiDocsPath | Should -Be $true
            Test-Path $functionsPath | Should -Be $true
            Test-Path $aliasesPath | Should -Be $true

            # Verify files were generated in correct locations
            $functionFiles = (Get-ChildItem -Path $functionsPath -Filter *.md -ErrorAction SilentlyContinue).Count
            $aliasFiles = (Get-ChildItem -Path $aliasesPath -Filter *.md -ErrorAction SilentlyContinue).Count
            ($functionFiles -gt 0) | Should -Be $true -Because 'function documentation files should be generated'
            ($aliasFiles -ge 0) | Should -Be $true -Because 'alias documentation files should be generated (may be 0 if no aliases)'

            $readmePath = Join-Path $apiDocsPath 'README.md'
            Test-Path $readmePath | Should -Be $true
            $readmeContent = Get-Content $readmePath -Raw
            $expectedPatterns = @(
                '## Functions',
                '## Aliases',
                '\[.*\]\(functions/.*\.md\)',
                '\[.*\]\(aliases/.*\.md\)'
            )
            foreach ($pattern in $expectedPatterns) {
                $readmeContent | Should -Match $pattern
            }
        }

        It 'documentation includes proper function signatures' {
            $apiDocsPath = Join-Path $script:DocsPath 'api'
            $functionsPath = Join-Path $apiDocsPath 'functions'
            $setEnvVarDoc = Join-Path $functionsPath 'Set-EnvVar.md'

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
            $spellcheckPath = Join-Path $script:ScriptsUtilsPath 'code-quality\spellcheck.ps1'
            if (Test-Path $spellcheckPath) {
                # Spellcheck script handles missing cspell gracefully, so it should not throw
                { & $spellcheckPath 2>&1 | Out-Null } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because "spellcheck.ps1 not found at $spellcheckPath"
            }
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
                $errors = $result | Where-Object { $_.Severity -eq 'Error' }
                $errors | Should -BeNullOrEmpty
            }
        }
    }
}
