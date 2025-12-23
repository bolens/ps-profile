

Describe 'Profile Fragment Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if ($null -eq $script:ProfilePath -or [string]::IsNullOrWhiteSpace($script:ProfilePath)) {
                throw "Get-TestPath returned null or empty value for ProfilePath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize profile fragment tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Profile fragment dependencies' {
        It 'all profile fragments exist and are readable' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                if ($file.FullName -and -not [string]::IsNullOrWhiteSpace($file.FullName)) {
                    Test-Path -LiteralPath $file.FullName | Should -Be $true
                }
                { Get-Content $file.FullName -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'profile fragments have valid PowerShell syntax' {
            $fragFiles = Get-ChildItem -Path $script:ProfileDir -Filter *.ps1 -File
            foreach ($file in $fragFiles) {
                $errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
                if ($errors) {
                    $errors.Count | Should -Be 0
                }
            }
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

