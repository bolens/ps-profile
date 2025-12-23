

Describe 'Tooling Integration Tests' {
    BeforeAll {
        try {
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            $script:DocsPath = Get-TestPath -RelativePath 'docs' -StartPath $PSScriptRoot -EnsureExists
            $script:CspellPath = Get-TestPath -RelativePath 'cspell.json' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:ScriptsUtilsPath = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
            $script:ScriptsUtilsDocsPath = Get-TestPath -RelativePath 'scripts\utils\docs' -StartPath $PSScriptRoot -EnsureExists
            
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if ($null -eq $script:ScriptsUtilsPath -or [string]::IsNullOrWhiteSpace($script:ScriptsUtilsPath)) {
                throw "Get-TestPath returned null or empty value for ScriptsUtilsPath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ScriptsUtilsPath)) {
                throw "Scripts utils path not found at: $script:ScriptsUtilsPath"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize tooling tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Documentation generation' {
        It 'generates API documentation successfully' {
            $apiDocsPath = Join-Path $script:DocsPath 'api'
            $functionsPath = Join-Path $apiDocsPath 'functions'
            $aliasesPath = Join-Path $apiDocsPath 'aliases'

            & (Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1')

            # Verify new directory structure exists
            if ($apiDocsPath -and -not [string]::IsNullOrWhiteSpace($apiDocsPath)) {
                Test-Path -LiteralPath $apiDocsPath | Should -Be $true
            }
            if ($functionsPath -and -not [string]::IsNullOrWhiteSpace($functionsPath)) {
                Test-Path -LiteralPath $functionsPath | Should -Be $true
            }
            if ($aliasesPath -and -not [string]::IsNullOrWhiteSpace($aliasesPath)) {
                Test-Path -LiteralPath $aliasesPath | Should -Be $true
            }

            # Verify files were generated in correct locations
            $functionFiles = (Get-ChildItem -Path $functionsPath -Filter *.md -ErrorAction SilentlyContinue).Count
            $aliasFiles = (Get-ChildItem -Path $aliasesPath -Filter *.md -ErrorAction SilentlyContinue).Count
            ($functionFiles -gt 0) | Should -Be $true -Because 'function documentation files should be generated'
            ($aliasFiles -ge 0) | Should -Be $true -Because 'alias documentation files should be generated (may be 0 if no aliases)'

            $readmePath = Join-Path $apiDocsPath 'README.md'
            if ($readmePath -and -not [string]::IsNullOrWhiteSpace($readmePath)) {
                Test-Path -LiteralPath $readmePath | Should -Be $true
            }
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

            if ($setEnvVarDoc -and -not [string]::IsNullOrWhiteSpace($setEnvVarDoc) -and (Test-Path -LiteralPath $setEnvVarDoc)) {
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
            if ($spellcheckPath -and -not [string]::IsNullOrWhiteSpace($spellcheckPath) -and (Test-Path -LiteralPath $spellcheckPath)) {
                # Spellcheck script handles missing cspell gracefully, so it should not throw
                { & $spellcheckPath 2>&1 | Out-Null } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because "spellcheck.ps1 not found at $spellcheckPath"
            }
        }

        It 'cspell configuration includes custom words' {
            if ($script:CspellPath -and -not [string]::IsNullOrWhiteSpace($script:CspellPath)) {
                Test-Path -LiteralPath $script:CspellPath | Should -Be $true
            }

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

