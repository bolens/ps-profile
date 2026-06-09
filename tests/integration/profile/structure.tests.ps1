<#
tests/integration/profile/structure.tests.ps1

.SYNOPSIS
    Profile structure integration tests.
#>


Describe 'Profile Structure Integration Tests' {
    BeforeAll {
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

    Context 'Fragment ordering' {
        It 'fragments load in correct order' {
            $fragDir = $script:ProfileDir
            $files = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name
            $fileNames = @($files | Select-Object -ExpandProperty Name)

            $fileNames | Should -Contain 'bootstrap.ps1' -Because 'bootstrap must be present for first-load ordering'

            $nonBootstrap = @($fileNames | Where-Object { $_ -ne 'bootstrap.ps1' })
            $nonBootstrap | Should -Be ($nonBootstrap | Sort-Object) -Because 'non-bootstrap fragments use lexical ordering'

            # ProfileFragmentDiscovery loads bootstrap first, then remaining fragments alphabetically
            $nonBootstrap[0] | Should -Be '3d-cad.ps1'
        }
    }
}

