BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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

        # Load the starship fragment directly with guard clearing
        $starshipPath = Join-Path $profileDir 'starship.ps1'
        if ($null -eq $starshipPath -or [string]::IsNullOrWhiteSpace($starshipPath)) {
            throw "StarshipPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $starshipPath)) {
            throw "Starship fragment not found at: $starshipPath"
        }
        . $starshipPath
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize smartprompt tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

Describe "SmartPrompt Detection Tests" {
    Context "SmartPrompt UV Detection" {
        BeforeEach {
            # Clear environment variables
            Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            
            # Initialize smart prompt
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show uv when PS_PROFILE_SHOW_UV is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pyproject.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'uv'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows uv when PS_PROFILE_SHOW_UV is enabled and pyproject.toml exists" {
            $env:PS_PROFILE_SHOW_UV = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pyproject.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'uv' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains 'python' -and $Arguments -contains 'list') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return 'Python 3.11.5'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                # Should contain uv indicator (may be "uv" or "uv:py3.11.5" depending on version detection)
                $outputString | Should -Match 'uv'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            }
        }

        It "Shows uv when .python-version exists" {
            $env:PS_PROFILE_SHOW_UV = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path ".python-version" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'uv'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            }
        }

        It "Shows uv when .venv directory exists" {
            $env:PS_PROFILE_SHOW_UV = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType Directory -Path ".venv" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'uv'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            }
        }

        It "Does not show uv when uv command is not available" {
            $env:PS_PROFILE_SHOW_UV = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pyproject.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'uv'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            }
        }

        It "Handles uv python list errors gracefully" {
            $env:PS_PROFILE_SHOW_UV = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptUV'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pyproject.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'uv' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'uv' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains 'python') {
                        Set-Variable -Name LASTEXITCODE -Value 1 -Scope Global -Force
                        throw 'Command failed'
                    }
                }

                Register-TestWriteHostCapture

                { prompt | Out-Null } | Should -Not -Throw
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt NPM Detection" {
        BeforeEach {
            # Clear environment variables
            Remove-Item Env:\PS_PROFILE_SHOW_UV -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            
            # Initialize smart prompt
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show npm when PS_PROFILE_SHOW_NPM is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "package.json" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'npm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows npm when PS_PROFILE_SHOW_NPM is enabled and package.json exists" {
            $env:PS_PROFILE_SHOW_NPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "package.json" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
                Set-TestCommandAvailabilityState -CommandName 'node' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'node' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains '--version') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return 'v20.10.0'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                # Should contain npm indicator (may be "npm" or "npm:node20.10.0" depending on version detection)
                $outputString | Should -Match 'npm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            }
        }

        It "Does not show npm when npm command is not available" {
            $env:PS_PROFILE_SHOW_NPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "package.json" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'npm' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'npm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            }
        }

        It "Shows npm without version when node command fails" {
            $env:PS_PROFILE_SHOW_NPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "package.json" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'node' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains '--version') {
                        Set-Variable -Name LASTEXITCODE -Value 1 -Scope Global -Force
                        throw 'Command failed'
                    }
                }

                Register-TestWriteHostCapture

                { prompt | Out-Null } | Should -Not -Throw

                # Should still show npm even if node version fails
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'npm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            }
        }

        It "Searches parent directories for package.json" {
            $env:PS_PROFILE_SHOW_NPM = '1'
            $parentDir = New-TestTempDirectory -Prefix 'SmartPromptNPM'
            $testDir = Join-Path $parentDir "subdir"
            try {
                New-Item -ItemType Directory -Path $testDir -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $parentDir "package.json") -Force | Out-Null
                
                Push-Location $testDir
                
                Set-TestCommandAvailabilityState -CommandName 'npm' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'npm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $parentDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_NPM -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt Rust Detection" {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_SHOW_RUST -ErrorAction SilentlyContinue
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show rust when PS_PROFILE_SHOW_RUST is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptRust'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "Cargo.toml" -Force | Out-Null
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'rust'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows rust when PS_PROFILE_SHOW_RUST is enabled and Cargo.toml exists" {
            $env:PS_PROFILE_SHOW_RUST = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptRust'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "Cargo.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'rustc' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'rustc' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains '--version') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return 'rustc 1.75.0'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'rust'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_RUST -ErrorAction SilentlyContinue
            }
        }

        It "Shows rust without version when rustc is not available" {
            $env:PS_PROFILE_SHOW_RUST = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptRust'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "Cargo.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'rustc' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'rust'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_RUST -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt Go Detection" {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_SHOW_GO -ErrorAction SilentlyContinue
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show go when PS_PROFILE_SHOW_GO is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptGo'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "go.mod" -Force | Out-Null
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'go'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows go when PS_PROFILE_SHOW_GO is enabled and go.mod exists" {
            $env:PS_PROFILE_SHOW_GO = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptGo'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "go.mod" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'go' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'go' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains 'version') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return 'go version go1.21.5'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'go'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_GO -ErrorAction SilentlyContinue
            }
        }

        It "Shows go without version when go command is not available" {
            $env:PS_PROFILE_SHOW_GO = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptGo'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "go.mod" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'go' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'go'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_GO -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt Docker Detection" {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_SHOW_DOCKER -ErrorAction SilentlyContinue
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show docker when PS_PROFILE_SHOW_DOCKER is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptDocker'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "Dockerfile" -Force | Out-Null
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'docker'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows docker when PS_PROFILE_SHOW_DOCKER is enabled and Dockerfile exists" {
            $env:PS_PROFILE_SHOW_DOCKER = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptDocker'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "Dockerfile" -Force | Out-Null
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'docker'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_DOCKER -ErrorAction SilentlyContinue
            }
        }

        It "Shows docker when docker-compose.yml exists" {
            $env:PS_PROFILE_SHOW_DOCKER = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptDocker'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "docker-compose.yml" -Force | Out-Null
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'docker'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_DOCKER -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt Poetry Detection" {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_SHOW_POETRY -ErrorAction SilentlyContinue
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show poetry when PS_PROFILE_SHOW_POETRY is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPoetry'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "poetry.lock" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'poetry'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows poetry when PS_PROFILE_SHOW_POETRY is enabled and poetry.lock exists" {
            $env:PS_PROFILE_SHOW_POETRY = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPoetry'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "poetry.lock" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'poetry' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains 'env' -and $Arguments -contains 'info') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return 'Python: 3.11.5'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'poetry'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_POETRY -ErrorAction SilentlyContinue
            }
        }

        It "Shows poetry when pyproject.toml exists" {
            $env:PS_PROFILE_SHOW_POETRY = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPoetry'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pyproject.toml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'poetry'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_POETRY -ErrorAction SilentlyContinue
            }
        }

        It "Does not show poetry when poetry command is not available" {
            $env:PS_PROFILE_SHOW_POETRY = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPoetry'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "poetry.lock" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'poetry'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_POETRY -ErrorAction SilentlyContinue
            }
        }
    }

    Context "SmartPrompt pnpm/yarn Detection" {
        BeforeEach {
            Remove-Item Env:\PS_PROFILE_SHOW_PNPM -ErrorAction SilentlyContinue
            Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
            Initialize-SmartPrompt
        }

        It "Does not show pnpm when PS_PROFILE_SHOW_PNPM is not set" {
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pnpm-lock.yaml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Not -Match 'pnpm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Shows pnpm when PS_PROFILE_SHOW_PNPM is enabled and pnpm-lock.yaml exists" {
            $env:PS_PROFILE_SHOW_PNPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pnpm-lock.yaml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'pnpm' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains '--version') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return '8.15.0'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'pnpm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_PNPM -ErrorAction SilentlyContinue
            }
        }

        It "Shows yarn when yarn.lock exists" {
            $env:PS_PROFILE_SHOW_PNPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "yarn.lock" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $true
                
                Setup-CapturingCommandMock -CommandName 'yarn' -OnInvoke {
                    param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                    if ($Arguments -contains '--version') {
                        Set-Variable -Name LASTEXITCODE -Value 0 -Scope Global -Force
                        return '3.6.4'
                    }
                }
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'yarn'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_PNPM -ErrorAction SilentlyContinue
            }
        }

        It "Shows pnpm without version when pnpm command is not available" {
            $env:PS_PROFILE_SHOW_PNPM = '1'
            $testDir = New-TestTempDirectory -Prefix 'SmartPromptPNPM'
            try {
                Push-Location $testDir
                New-Item -ItemType File -Path "pnpm-lock.yaml" -Force | Out-Null
                
                Set-TestCommandAvailabilityState -CommandName 'pnpm' -Available $false
                
                Register-TestWriteHostCapture
                
                prompt | Out-Null
                
                $outputString = Get-TestWriteHostOutputString
                $outputString | Should -Match 'pnpm'
            }
            finally {
                Pop-Location
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item Env:\PS_PROFILE_SHOW_PNPM -ErrorAction SilentlyContinue
            }
        }
    }
}
