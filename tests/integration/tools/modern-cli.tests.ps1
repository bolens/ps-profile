
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

Describe "Modern CLI Tools" {
    BeforeAll {
        try {
            # Load bootstrap first to get Test-CachedCommand
            $global:__psprofile_fragment_loaded = @{}
            $profileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $profileDir -or [string]::IsNullOrWhiteSpace($profileDir)) {
                throw "Get-TestPath returned null or empty value for profileDir"
            }
            if (-not (Test-Path -LiteralPath $profileDir)) {
                throw "Profile directory not found at: $profileDir"
            }
            
            $bootstrapPath = Join-Path $profileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath

            # Load the modern CLI tools fragment with guard clearing
            $modernCliPath = Join-Path $profileDir 'modern-cli.ps1'
            if ($null -eq $modernCliPath -or [string]::IsNullOrWhiteSpace($modernCliPath)) {
                throw "ModernCliPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $modernCliPath)) {
                throw "Modern CLI fragment not found at: $modernCliPath"
            }
            . $modernCliPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize modern CLI tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context "bat function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'bat' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command bat -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'bat is not installed on PATH'
                return
            }
            { bat --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'bat'
        }
    }

    Context "fd function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'fd' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command fd -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'fd is not installed on PATH'
                return
            }
            { fd --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'fd'
        }
    }

    Context "http function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'http' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command http -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'httpie is not installed on PATH'
                return
            }
            { http --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'http'
        }
    }

    Context "zoxide function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'zoxide' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command zoxide -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'zoxide is not installed on PATH'
                return
            }
            { zoxide --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'zoxide'
        }
    }

    Context "delta function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'delta' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command delta -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'delta is not installed on PATH'
                return
            }
            { delta --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'delta'
        }
    }

    Context "tldr function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'tldr' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command tldr -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'tldr is not installed on PATH'
                return
            }
            { tldr --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'tldr'
        }
    }

    Context "procs function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'procs' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command procs -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'procs is not installed on PATH'
                return
            }
            { procs --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'procs'
        }
    }

    Context "dust function" {
        BeforeEach {
            Set-TestCommandAvailabilityState -CommandName 'dust' -Available $false        }

        It "Executes without error when wrapper or binary exists" {
            if (-not (Get-Command dust -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'dust is not installed on PATH'
                return
            }
            { dust --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Assert-ModernCliWrapperDefined -Name 'dust'
        }
    }
    
    Context "Enhanced Functions" {
        BeforeEach {
            if (Get-Command Initialize-TestSession -ErrorAction SilentlyContinue) {
                Initialize-TestSession | Out-Null
            }
            elseif ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }

            Set-TestCommandAvailabilityState -CommandName 'fd' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'rg' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'zoxide' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'bat' -Available $false
        }
        
        It "Find-WithFd function is defined" {
            Get-Command Find-WithFd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Grep-WithRipgrep function is defined" {
            Get-Command Grep-WithRipgrep -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Navigate-WithZoxide function is defined" {
            Get-Command Navigate-WithZoxide -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "View-WithBat function is defined" {
            Get-Command View-WithBat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Find-WithFd emits missing-tool warning when fd is unavailable" {
            $fdOutput = Find-WithFd -Pattern 'test' 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $fdOutput -Pattern 'fd not found'
            Assert-TestOutputContainsInstallCommand -Output $fdOutput -ToolName 'fd'
        }

        It "Grep-WithRipgrep emits missing-tool warning when rg is unavailable" {
            $rgOutput = Grep-WithRipgrep -Pattern 'test' 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $rgOutput -Pattern 'rg not found'
        }

        It "Navigate-WithZoxide emits missing-tool warning when zoxide is unavailable" {
            $zOutput = Navigate-WithZoxide -Query 'test' 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $zOutput -Pattern 'zoxide not found'
        }

        It "View-WithBat emits missing-tool warning when bat is unavailable" {
            $batOutput = View-WithBat -Path (Get-TestArtifactPath -FileName 'test.txt') 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $batOutput -Pattern 'bat not found'
        }
        
        It "Aliases are registered" {
            Get-Alias -Name 'ffd' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Alias -Name 'grg' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Alias -Name 'z' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Alias -Name 'vbat' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
