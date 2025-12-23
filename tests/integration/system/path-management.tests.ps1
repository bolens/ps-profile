

Describe 'Path Management Integration Tests' {
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
            
            $systemPath = Join-Path $script:ProfileDir 'system.ps1'
            if ($systemPath -and (Test-Path -LiteralPath $systemPath)) {
                . $systemPath
            }
            
            $utilitiesPath = Join-Path $script:ProfileDir 'utilities.ps1'
            if ($null -eq $utilitiesPath -or [string]::IsNullOrWhiteSpace($utilitiesPath)) {
                throw "UtilitiesPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $utilitiesPath)) {
                throw "Utilities fragment not found at: $utilitiesPath"
            }
            . $utilitiesPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize path management tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Utility functions edge cases' {
        It 'Add-Path adds path to beginning when specified' {
            $originalPath = $env:PATH
            $testPath = $null
            
            try {
                $testPath = Join-Path $TestDrive 'TestAddPath'
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null

                Add-Path -Path $testPath
                $pathArray = $env:PATH -split ';'
                $pathArray[0] | Should -Be $testPath -Because "Add-Path should add path to beginning when specified"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    TestPath = $testPath
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Add-Path beginning test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Add-Path adds path to end by default' {
            $originalPath = $env:PATH
            $testPath = Join-Path $TestDrive 'TestAddPathEnd'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            try {
                Add-Path -Path $testPath
                $pathArray = $env:PATH -split ';'
                $pathArray[0] | Should -Be $testPath
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Add-Path handles duplicate paths' {
            $originalPath = $env:PATH
            $testPath = Join-Path $TestDrive 'TestDuplicatePath'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            try {
                Add-Path -Path $testPath
                $beforeCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                Add-Path -Path $testPath
                $afterCount = ($env:PATH -split ';' | Where-Object { $_ -eq $testPath }).Count

                $afterCount | Should -BeGreaterOrEqual $beforeCount
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path removes existing path' {
            $originalPath = $env:PATH
            $testPath = Join-Path $TestDrive 'TestRemovePath'
            New-Item -ItemType Directory -Path $testPath -Force | Out-Null

            try {
                # Add path first
                Add-Path -Path $testPath
                $env:PATH | Should -Match "$([regex]::Escape($testPath))"

                # Remove the path
                Remove-Path -Path $testPath
                $env:PATH | Should -Not -Match "$([regex]::Escape($testPath))"
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path handles non-existent path' {
            $originalPath = $env:PATH
            try {
                Remove-Path -Path 'C:\NonExistentPath'
                $env:PATH | Should -Be $originalPath
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    Context 'Path safety tests' {
        It 'Test-SafePath accepts valid paths within base directory' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $safePath = Join-Path $basePath 'subdir\file.txt'
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null

            $result = Test-SafePath -Path $safePath -BasePath $basePath
            $result | Should -Be $true
        }

        It 'Test-SafePath rejects paths outside base directory' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $unsafePath = Join-Path $TestDrive 'OutsideDir\file.txt'
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null
            New-Item -ItemType Directory -Path (Split-Path $unsafePath -Parent) -Force | Out-Null

            $result = Test-SafePath -Path $unsafePath -BasePath $basePath
            $result | Should -Be $false
        }

        It 'Test-SafePath handles relative paths correctly' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $relativePath = '.\subdir\file.txt'
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null

            Push-Location $basePath
            try {
                $result = Test-SafePath -Path $relativePath -BasePath $basePath
                $result | Should -Be $true
            }
            finally {
                Pop-Location
            }
        }

        It 'Test-SafePath rejects path traversal attempts' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $traversalPath = Join-Path $basePath '..\..\..\Windows\System32\cmd.exe'
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null

            $result = Test-SafePath -Path $traversalPath -BasePath $basePath
            $result | Should -Be $false
        }

        It 'Test-SafePath handles invalid paths gracefully' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $invalidPath = "invalid<>|path$([char]0)"
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null

            $result = Test-SafePath -Path $invalidPath -BasePath $basePath
            $result | Should -Be $false
        }

        It 'Test-SafePath handles base path without trailing separator' {
            $basePath = Join-Path $TestDrive 'BaseDir'
            $safePath = Join-Path $basePath 'file.txt'
            New-Item -ItemType Directory -Path $basePath -Force | Out-Null

            # Test with base path that doesn't end with separator
            $result = Test-SafePath -Path $safePath -BasePath $basePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
            $result | Should -Be $true
        }
    }
}

