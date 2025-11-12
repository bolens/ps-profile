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
            $originalFiles = (Get-ChildItem -Path $script:DocsPath -Filter *.md -ErrorAction SilentlyContinue).Count

            & (Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1')

            $newFiles = (Get-ChildItem -Path $script:DocsPath -Filter *.md -ErrorAction SilentlyContinue).Count
            ($newFiles -ge $originalFiles) | Should -Be $true

            $readmePath = Join-Path $script:DocsPath 'README.md'
            Test-Path $readmePath | Should -Be $true
            $readmeContent = Get-Content $readmePath -Raw
            $expectedPatterns = @(
                '## Functions by Fragment',
                '\[.*\]\(.*\.md\)',
                'Total Functions:',
                'Generated:'
            )
            foreach ($pattern in $expectedPatterns) {
                $readmeContent | Should -Match $pattern
            }
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
                $errors = $result | Where-Object { $_.Severity -eq 'Error' }
                $errors | Should -BeNullOrEmpty
            }
        }
    }
}
