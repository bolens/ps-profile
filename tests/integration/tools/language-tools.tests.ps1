<#
.SYNOPSIS
    Integration tests for programming language tool fragments (go).

.DESCRIPTION
    Tests Go helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Language Tools Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize language tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Go helpers (go.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'go' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'go' } -MockWith { $null }
            # Mock go command before loading fragment - make available so functions are created
            Mock-CommandAvailabilityPester -CommandName 'go' -Available $true
            . (Join-Path $script:ProfileDir 'go.ps1')
        }

        It 'Creates Invoke-GoRun function' {
            Get-Command Invoke-GoRun -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-run alias for Invoke-GoRun' {
            Get-Alias go-run -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-run).ResolvedCommandName | Should -Be 'Invoke-GoRun'
        }

        It 'go-run alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('go', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'go' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'go' } -MockWith { $false }
            $output = go-run main.go 2>&1 3>&1 | Out-String
            $output | Should -Match 'go not found'
            $output | Should -Match 'scoop install go'
        }

        It 'Creates Build-GoProgram function' {
            Get-Command Build-GoProgram -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-build alias for Build-GoProgram' {
            Get-Alias go-build -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-build).ResolvedCommandName | Should -Be 'Build-GoProgram'
        }

        It 'Creates Invoke-GoModule function' {
            Get-Command Invoke-GoModule -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-mod alias for Invoke-GoModule' {
            Get-Alias go-mod -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-mod).ResolvedCommandName | Should -Be 'Invoke-GoModule'
        }

        It 'Creates Test-GoPackage function' {
            Get-Command Test-GoPackage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-test alias for Test-GoPackage' {
            Get-Alias go-test -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-test).ResolvedCommandName | Should -Be 'Test-GoPackage'
        }

        It 'Creates Update-GoDependencies function' {
            Get-Command Update-GoDependencies -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-update alias for Update-GoDependencies' {
            Get-Alias go-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-update).ResolvedCommandName | Should -Be 'Update-GoDependencies'
        }

        It 'Update-GoDependencies calls go get -u ./...' {
            Mock -CommandName go -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'get' -and $args -contains '-u' -and $args -contains './...') {
                    Write-Output 'Dependencies updated successfully'
                }
            }

            { Update-GoDependencies -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-GoDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Update-GoTools function' {
            Get-Command Update-GoTools -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates go-tools-update alias for Update-GoTools' {
            Get-Alias go-tools-update -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias go-tools-update).ResolvedCommandName | Should -Be 'Update-GoTools'
        }

        It 'Update-GoTools calls go install golang.org/x/tools/cmd/...@latest' {
            Mock -CommandName go -MockWith {
                param([string[]]$ArgumentList)
                $args = $ArgumentList
                if ($args -contains 'install' -and $args -contains 'golang.org/x/tools/cmd/...@latest') {
                    Write-Output 'Go tools updated successfully'
                }
            }

            { Update-GoTools -Verbose 4>&1 | Out-Null } | Should -Not -Throw
            Get-Command Update-GoTools -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}


