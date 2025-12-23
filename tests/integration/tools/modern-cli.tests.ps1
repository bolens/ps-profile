

Describe "Modern CLI Tools" {
    BeforeAll {
        try {
            # Load bootstrap first to get Test-HasCommand
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
            # Mock external bat command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'bat' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            try {
                { bat --help } | Should -Not -Throw -Because "bat function should execute without errors"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Command  = 'bat'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "bat function execution test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It "Function is defined" {
            try {
                Get-Command bat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "bat function should be defined"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Command  = 'bat'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "bat function definition test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }

    Context "fd function" {
        BeforeEach {
            # Mock external fd command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'fd' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { fd --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command fd -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "http function" {
        BeforeEach {
            # Mock external http command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'http' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { http --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command http -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "zoxide function" {
        BeforeEach {
            # Mock external zoxide command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'zoxide' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { zoxide --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command zoxide -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "delta function" {
        BeforeEach {
            # Mock external delta command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'delta' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { delta --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command delta -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "tldr function" {
        BeforeEach {
            # Mock external tldr command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'tldr' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { tldr --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command tldr -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "procs function" {
        BeforeEach {
            # Mock external procs command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'procs' -Available $false -CommandType 'Application' -Scope It
        }

        It "Executes without error when function exists" {
            { procs --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command procs -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "dust function" {
        BeforeEach {
            # Mock external dust command to avoid hanging
            Mock-CommandAvailabilityPester -CommandName 'dust' -Available $false -CommandType 'Application' -Scope 'It'
        }

        It "Executes without error when function exists" {
            { dust --help } | Should -Not -Throw
        }

        It "Function is defined" {
            Get-Command dust -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
