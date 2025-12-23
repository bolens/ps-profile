
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $true }
                
                # Mock uv python list to return a version
                Mock -CommandName uv -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'python' -and $ArgumentList -contains 'list') {
                        $global:LASTEXITCODE = 0
                        Write-Output "Python 3.11.5"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'uv' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'uv' } -MockWith { $true }
                
                # Mock uv python list to fail
                Mock -CommandName uv -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'python') {
                        $global:LASTEXITCODE = 1
                        throw "Command failed"
                    }
                }
                
                Mock -CommandName Write-Host -MockWith { }
                
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
                
                Mock-CommandAvailabilityPester -CommandName 'npm' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'npm' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'npm' -Available $true -Scope It
                Mock-CommandAvailabilityPester -CommandName 'node' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'npm' } -MockWith { $true }
                
                # Mock node --version to return a version
                Mock -CommandName node -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains '--version') {
                        $global:LASTEXITCODE = 0
                        Write-Output "v20.10.0"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'npm' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'npm' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'npm' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'npm' } -MockWith { $true }
                
                # Mock node --version to fail
                Mock -CommandName node -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains '--version') {
                        $global:LASTEXITCODE = 1
                        throw "Command failed"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                { prompt | Out-Null } | Should -Not -Throw
                
                # Should still show npm even if node version fails
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'npm' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'npm' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'rustc' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'rustc' } -MockWith { $true }
                
                Mock -CommandName rustc -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains '--version') {
                        $global:LASTEXITCODE = 0
                        Write-Output "rustc 1.75.0"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'rustc' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'rustc' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'go' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'go' } -MockWith { $true }
                
                Mock -CommandName go -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'version') {
                        $global:LASTEXITCODE = 0
                        Write-Output "go version go1.21.5"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'go' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'go' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'poetry' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'poetry' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'poetry' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'poetry' } -MockWith { $true }
                
                Mock -CommandName poetry -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'env' -and $ArgumentList -contains 'info') {
                        $global:LASTEXITCODE = 0
                        Write-Output "Python: 3.11.5"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'poetry' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'poetry' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'poetry' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'poetry' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'pnpm' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'pnpm' } -MockWith { $true }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'pnpm' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'pnpm' } -MockWith { $true }
                
                Mock -CommandName pnpm -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains '--version') {
                        $global:LASTEXITCODE = 0
                        Write-Output "8.15.0"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'yarn' -Available $true -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'yarn' } -MockWith { $true }
                
                Mock -CommandName yarn -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains '--version') {
                        $global:LASTEXITCODE = 0
                        Write-Output "3.6.4"
                    }
                }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
                
                Mock-CommandAvailabilityPester -CommandName 'pnpm' -Available $false -Scope It
                Mock -CommandName Test-CachedCommand -ParameterFilter { $Name -eq 'pnpm' } -MockWith { $false }
                
                $script:capturedOutput = @()
                Mock -CommandName Write-Host -MockWith {
                    param([object]$Object)
                    $script:capturedOutput += $Object
                }
                
                prompt | Out-Null
                
                $outputString = $script:capturedOutput -join ''
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
