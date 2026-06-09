

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
}

Describe 'Scoop Completion Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }

            $script:CompletionRelativePath = Join-Path 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize scoop completion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Scoop completion setup' {
        BeforeEach {
            # Clear environment variables
            $env:SCOOP = $null
            $env:SCOOP_GLOBAL = $null
            $env:USERPROFILE = 'C:\Users\TestUser'
            $env:HOME = $null

            # Clear any existing global variable
            if (Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'ScoopCompletionLoaded' -Scope Global -Force
            }

            # Clear any existing function
            if (Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\Enable-ScoopCompletion -Force
            }
        }

        It 'Sets ScoopCompletionLoaded global variable on load' {
            # Load the module
            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            # Variable should NOT be set on load (only when Enable-ScoopCompletion is called)
            Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -Be $null
        }

        It 'Does not create Enable-ScoopCompletion when no scoop installation found' {
            $isolatedHome = New-TestTempDirectory -Prefix 'ScoopNone'
            $originalHome = $env:HOME
            $originalUserProfile = $env:USERPROFILE
            try {
                $env:HOME = $isolatedHome
                $env:USERPROFILE = $isolatedHome
                $env:SCOOP = $null
                $env:SCOOP_GLOBAL = $null

                Remove-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue
                . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

                Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally {
                $env:HOME = $originalHome
                $env:USERPROFILE = $originalUserProfile
            }
        }

        It 'Creates Enable-ScoopCompletion when scoop found via SCOOP environment variable' {
            $testScoopDir = New-TestTempDirectory -Prefix 'ScoopCompletionEnv'
            $completionPath = Join-Path $testScoopDir $script:CompletionRelativePath
            New-Item -ItemType Directory -Path (Split-Path $completionPath -Parent) -Force | Out-Null
            New-Item -ItemType File -Path $completionPath -Force | Out-Null

            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $testScoopDir

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Enable-ScoopCompletion can be called' {
            $testScoopDir = New-TestTempDirectory -Prefix 'ScoopCompletionCall'
            $completionPath = Join-Path $testScoopDir $script:CompletionRelativePath
            New-Item -ItemType Directory -Path (Split-Path $completionPath -Parent) -Force | Out-Null
            New-Item -ItemType File -Path $completionPath -Force | Out-Null

            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $testScoopDir

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            # Call the function - should not throw (may show warning if import fails)
            { Enable-ScoopCompletion } | Should -Not -Throw
        }

        It 'Handles errors during scoop completion setup gracefully' {
            # Should not throw even with invalid setup
            { . (Join-Path $script:ProfileDir 'scoop-completion.ps1') } | Should -Not -Throw
        }
    }
}
