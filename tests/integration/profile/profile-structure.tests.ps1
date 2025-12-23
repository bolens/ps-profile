

Describe 'Profile Structure Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize profile structure tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Fragment ordering' {
        It 'fragments load in correct order' {
            $fragDir = $script:ProfileDir
            $files = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name
            $fileNames = $files | Select-Object -ExpandProperty Name

            $fileNames[0] | Should -Match '^00-'

            $sorted = $fileNames | Sort-Object
            $fileNames | Should -Be $sorted
        }
    }
}

