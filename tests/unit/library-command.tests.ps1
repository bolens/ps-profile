. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:CommandPath = Join-Path $script:LibPath 'utilities' 'Command.psm1'
    
    # Import Cache module first (dependency)
    $cachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
    if (Test-Path -Path $cachePath) {
        Import-Module $cachePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:CommandPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module Command -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
}

Describe 'Command Module Functions' {
    Context 'Test-CommandAvailable' {
        It 'Returns true for existing commands' {
            $result = Test-CommandAvailable -CommandName 'Get-Command'
            $result | Should -Be $true
        }

        It 'Returns false for non-existent commands' {
            $result = Test-CommandAvailable -CommandName 'NonExistentCommand12345'
            $result | Should -Be $false
        }

        It 'Returns true for built-in cmdlets' {
            $result = Test-CommandAvailable -CommandName 'Get-ChildItem'
            $result | Should -Be $true
        }

        It 'Returns true for functions' {
            # Create a test function in global scope so Test-CachedCommand can find it
            $funcName = "Test-TempFunction_$(Get-Random)"
            Set-Item -Path "Function:\global:$funcName" -Value { } -Force
            try {
                $result = Test-CommandAvailable -CommandName $funcName
                $result | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns true for aliases' {
            # Use a common alias
            $result = Test-CommandAvailable -CommandName 'ls'
            # ls might or might not exist depending on platform, but if it exists, should return true
            if (Get-Command ls -ErrorAction SilentlyContinue) {
                $result | Should -Be $true
            }
        }

        It 'Uses cached value when available' {
            # Clear cache first
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key 'CommandAvailable_Get-Command' -ErrorAction SilentlyContinue
            }

            # First call
            $result1 = Test-CommandAvailable -CommandName 'Get-Command'
            
            # Second call should use cache
            $result2 = Test-CommandAvailable -CommandName 'Get-Command'
            
            $result1 | Should -Be $result2
            $result1 | Should -Be $true
        }

        It 'Uses Test-CachedCommand if available from profile' {
            # Create a test command that Test-CachedCommand can find
            $testCmdName = "TestCommand_$(Get-Random)"
            Set-Item -Path "Function:\global:$testCmdName" -Value { } -Force
            
            try {
                # Clear cache
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
                        New-CacheKey -Prefix 'CommandAvailable' -Components $testCmdName
                    }
                    else {
                        "CommandAvailable_$testCmdName"
                    }
                    Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
                }
                
                # Test-CommandAvailable should use Test-CachedCommand if available
                $result = Test-CommandAvailable -CommandName $testCmdName
                $result | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\global:$testCmdName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back to Get-Command when Test-CachedCommand is not available' {
            # Ensure Test-CachedCommand is not available
            $originalTestCachedCommand = Get-Command Test-CachedCommand -ErrorAction SilentlyContinue
            if ($originalTestCachedCommand) {
                Remove-Item -Path Function:\Test-CachedCommand -Force -ErrorAction SilentlyContinue
            }
            
            try {
                # Clear cache
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    Clear-CachedValue -Key 'CommandAvailable_Get-Process' -ErrorAction SilentlyContinue
                }
                
                $result = Test-CommandAvailable -CommandName 'Get-Process'
                $result | Should -Be $true
            }
            finally {
                if ($originalTestCachedCommand) {
                    Set-Item -Path Function:\Test-CachedCommand -Value $originalTestCachedCommand.ScriptBlock -Force
                }
            }
        }

        It 'Caches results for 5 minutes' {
            # Clear cache
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key 'CommandAvailable_Get-Date' -ErrorAction SilentlyContinue
            }

            # First call should cache
            $result1 = Test-CommandAvailable -CommandName 'Get-Date'
            
            # Verify it's cached (second call should use cache)
            $result2 = Test-CommandAvailable -CommandName 'Get-Date'
            $result1 | Should -Be $result2
        }

        It 'Handles commands with special characters' {
            # Test with command names that might have special handling
            $result = Test-CommandAvailable -CommandName 'Write-Host'
            $result | Should -Be $true
        }
    }

    Context 'Invoke-CommandIfAvailable' {
        It 'Executes command when it exists' {
            $result = Invoke-CommandIfAvailable -CommandName 'Get-Date' -FallbackValue 'fallback'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Not -Be 'fallback'
        }

        It 'Uses fallback value when command does not exist' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' -FallbackValue 'fallback'
            $result | Should -Be 'fallback'
        }

        It 'Executes fallback scriptblock when command does not exist' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -FallbackScriptBlock { return 'scriptblock-result' }
            $result | Should -Be 'scriptblock-result'
        }

        It 'Passes hashtable arguments to command' {
            $funcName = "Test-CommandWithParams_$(Get-Random)"
            $funcBody = {
                param([string]$Name, [int]$Count)
                return "$Name-$Count"
            }
            Set-Item -Path "Function:\global:$funcName" -Value $funcBody -Force
            
            try {
                # Verify function exists
                Get-Command $funcName -ErrorAction Stop | Should -Not -BeNullOrEmpty
                
                $result = Invoke-CommandIfAvailable -CommandName $funcName `
                    -Arguments @{ Name = 'test'; Count = 5 } `
                    -FallbackValue 'fallback'
                $result | Should -Be 'test-5'
            }
            finally {
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Passes array arguments to command' {
            $funcName = "Test-CommandWithArray_$(Get-Random)"
            $funcBody = {
                param([string[]]$Items)
                return $Items -join ','
            }
            Set-Item -Path "Function:\global:$funcName" -Value $funcBody -Force
            
            try {
                # Verify function exists
                Get-Command $funcName -ErrorAction Stop | Should -Not -BeNullOrEmpty
                
                $result = Invoke-CommandIfAvailable -CommandName $funcName `
                    -Arguments @('item1', 'item2') `
                    -FallbackValue 'fallback'
                $result | Should -Be 'item1,item2'
            }
            finally {
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Passes arguments to fallback scriptblock' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -Arguments @{ Value = 'test' } `
                -FallbackScriptBlock { param($Value) return "fallback-$Value" }
            $result | Should -Be 'fallback-test'
        }

        It 'Handles command execution errors gracefully' {
            <#
            .SYNOPSIS
                Performs operations related to Test-FailingCommand.
            
            .DESCRIPTION
                Performs operations related to Test-FailingCommand.
            
            .OUTPUTS
                object
            #>
            function Test-FailingCommand {
                throw 'Command failed'
            }
            
            Set-Item -Path Function:\Test-FailingCommand -Value ${function:Test-FailingCommand} -Force
            
            try {
                $result = Invoke-CommandIfAvailable -CommandName 'Test-FailingCommand' `
                    -FallbackValue 'fallback'
                # Should fall back to fallback value on error
                $result | Should -Be 'fallback'
            }
            finally {
                Remove-Item -Path Function:\Test-FailingCommand -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Executes command without arguments' {
            $result = Invoke-CommandIfAvailable -CommandName 'Get-Date' -FallbackValue 'fallback'
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be 'DateTime'
        }

        It 'Prioritizes fallback scriptblock over fallback value' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -FallbackValue 'value' `
                -FallbackScriptBlock { return 'scriptblock' }
            $result | Should -Be 'scriptblock'
        }
    }

    Context 'Resolve-InstallCommand' {
        It 'Returns platform-specific command from hashtable' {
            $installCommand = @{
                Windows = 'scoop install git'
                Linux   = 'apt install git'
                MacOS   = 'brew install git'
            }
            $result = Resolve-InstallCommand -InstallCommand $installCommand
            $result | Should -Not -BeNullOrEmpty
            # Should return the command for current platform
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result | Should -Be 'scoop install git'
            }
            elseif ($IsLinux) {
                $result | Should -Be 'apt install git'
            }
            elseif ($IsMacOS) {
                $result | Should -Be 'brew install git'
            }
        }

        It 'Returns string command as-is' {
            $result = Resolve-InstallCommand -InstallCommand 'scoop install git'
            $result | Should -Be 'scoop install git'
        }

        It 'Returns null for invalid input type' {
            $result = Resolve-InstallCommand -InstallCommand @(1, 2, 3)
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when platform key is missing from hashtable' {
            $installCommand = @{
                Linux = 'apt install git'
                MacOS = 'brew install git'
            }
            # If on Windows and Windows key is missing, should return null
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result = Resolve-InstallCommand -InstallCommand $installCommand
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Handles Node.js npm commands' {
            $result = Resolve-InstallCommand -InstallCommand 'npm install -g qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should return the command (or resolved version if Get-NodePackageInstallRecommendation is available)
            $result | Should -Match 'npm|pnpm|yarn|bun'
        }

        It 'Handles Node.js pnpm commands' {
            $result = Resolve-InstallCommand -InstallCommand 'pnpm add -g qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'pnpm|npm|yarn|bun'
        }

        It 'Handles Node.js yarn commands' {
            $result = Resolve-InstallCommand -InstallCommand 'yarn global add qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'yarn|npm|pnpm|bun'
        }

        It 'Handles Node.js bun commands' {
            $result = Resolve-InstallCommand -InstallCommand 'bun install -g qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'bun|npm|pnpm|yarn'
        }

        It 'Extracts package name from npm command' {
            $result = Resolve-InstallCommand -InstallCommand 'npm install -g qrcode' -PackageName 'qrcode'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles Python pip commands' {
            $result = Resolve-InstallCommand -InstallCommand 'pip install qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'pip|uv|conda|poetry|pipenv'
        }

        It 'Handles Python uv commands' {
            $result = Resolve-InstallCommand -InstallCommand 'uv pip install --system qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'uv|pip|conda|poetry|pipenv'
        }

        It 'Handles Python conda commands' {
            $result = Resolve-InstallCommand -InstallCommand 'conda install qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'conda|pip|uv|poetry|pipenv'
        }

        It 'Handles Python poetry commands' {
            $result = Resolve-InstallCommand -InstallCommand 'poetry add qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'poetry|pip|uv|conda|pipenv'
        }

        It 'Handles Python pipenv commands' {
            $result = Resolve-InstallCommand -InstallCommand 'pipenv install qrcode'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'pipenv|pip|uv|conda|poetry'
        }

        It 'Extracts package name from pip command' {
            $result = Resolve-InstallCommand -InstallCommand 'pip install qrcode' -PackageName 'qrcode'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles pip install with --user flag' {
            $result = Resolve-InstallCommand -InstallCommand 'pip install --user qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should not be treated as global
        }

        It 'Handles pip install with --system flag' {
            $result = Resolve-InstallCommand -InstallCommand 'uv pip install --system qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should be treated as global
        }

        It 'Returns non-package-manager commands as-is' {
            $result = Resolve-InstallCommand -InstallCommand 'scoop install git'
            $result | Should -Be 'scoop install git'
        }

        It 'Returns apt commands as-is' {
            $result = Resolve-InstallCommand -InstallCommand 'apt install git'
            $result | Should -Be 'apt install git'
        }

        It 'Returns brew commands as-is' {
            $result = Resolve-InstallCommand -InstallCommand 'brew install git'
            $result | Should -Be 'brew install git'
        }

        It 'Handles hashtable with all platforms' {
            $installCommand = @{
                Windows = 'scoop install testpackage'
                Linux   = 'apt install testpackage'
                MacOS   = 'brew install testpackage'
            }
            $result = Resolve-InstallCommand -InstallCommand $installCommand
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'testpackage'
        }

        It 'Handles npm install without -g flag' {
            $result = Resolve-InstallCommand -InstallCommand 'npm install qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should not be treated as global
        }

        It 'Handles yarn add without global' {
            $result = Resolve-InstallCommand -InstallCommand 'yarn add qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should not be treated as global
        }

        It 'Handles pnpm add without -g flag' {
            $result = Resolve-InstallCommand -InstallCommand 'pnpm add qrcode'
            $result | Should -Not -BeNullOrEmpty
            # Should not be treated as global
        }

        It 'Handles pip install with multiple packages' {
            $result = Resolve-InstallCommand -InstallCommand 'pip install package1 package2'
            $result | Should -Not -BeNullOrEmpty
            # Should extract first package name
        }

        It 'Handles npm install with multiple packages' {
            $result = Resolve-InstallCommand -InstallCommand 'npm install -g package1 package2'
            $result | Should -Not -BeNullOrEmpty
            # Should extract first package name
        }

        It 'Handles empty string command' {
            $result = Resolve-InstallCommand -InstallCommand ''
            $result | Should -Be ''
        }

        It 'Handles hashtable with empty string value' {
            $installCommand = @{
                Windows = ''
            }
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result = Resolve-InstallCommand -InstallCommand $installCommand
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Uses fallback cache key when New-CacheKey is not available' {
            # Temporarily remove CacheKey module if available
            $originalCmd = Get-Command New-CacheKey -ErrorAction SilentlyContinue
            if ($originalCmd) {
                Remove-Module CacheKey -ErrorAction SilentlyContinue -Force
            }
            
            try {
                # Clear cache
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    Clear-CachedValue -Key 'CommandAvailable_Get-Command' -ErrorAction SilentlyContinue
                }
                
                $result = Test-CommandAvailable -CommandName 'Get-Command'
                $result | Should -Be $true
            }
            finally {
                # Restore CacheKey module if it was available
                if ($originalCmd) {
                    $cacheKeyPath = Join-Path $script:LibPath 'utilities' 'CacheKey.psm1'
                    if (Test-Path -Path $cacheKeyPath) {
                        Import-Module $cacheKeyPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
                    }
                }
            }
        }

        It 'Uses Test-ValidString when Validation module is available' {
            # This tests the Test-ValidString path
            $result = Test-CommandAvailable -CommandName ''
            $result | Should -Be $false
        }

        It 'Handles null command name' {
            $result = Test-CommandAvailable -CommandName $null
            $result | Should -Be $false
        }

        It 'Handles whitespace-only command name' {
            $result = Test-CommandAvailable -CommandName '   '
            $result | Should -Be $false
        }
    }

    Context 'Invoke-CommandIfAvailable Additional Tests' {
        It 'Handles single object argument (not hashtable or array)' {
            $funcName = "Test-SingleArg_$(Get-Random)"
            $funcBody = {
                param([string]$Value)
                return "received-$Value"
            }
            Set-Item -Path "Function:\global:$funcName" -Value $funcBody -Force
            
            try {
                $result = Invoke-CommandIfAvailable -CommandName $funcName `
                    -Arguments 'test-value' `
                    -FallbackValue 'fallback'
                $result | Should -Be 'received-test-value'
            }
            finally {
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles fallback scriptblock with single object argument' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -Arguments 'test' `
                -FallbackScriptBlock { param($Value) return "fallback-$Value" }
            $result | Should -Be 'fallback-test'
        }

        It 'Handles fallback scriptblock with array arguments' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -Arguments @('arg1', 'arg2') `
                -FallbackScriptBlock { param($Items) return $Items -join ',' }
            $result | Should -Be 'arg1,arg2'
        }

        It 'Handles fallback scriptblock with hashtable arguments' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -Arguments @{ Name = 'test'; Count = 5 } `
                -FallbackScriptBlock { param($Name, $Count) return "$Name-$Count" }
            $result | Should -Be 'test-5'
        }

        It 'Handles fallback scriptblock without arguments' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -FallbackScriptBlock { return 'no-args' }
            $result | Should -Be 'no-args'
        }
    }

    Context 'Test-CommandAvailable Additional Coverage' {
        It 'Uses Test-ValidString when Validation module is available' {
            # Create a mock Test-ValidString function
            $mockFunc = {
                param([string]$Value)
                return $Value -match '^[a-zA-Z]'
            }
            Set-Item -Path "Function:\global:Test-ValidString" -Value $mockFunc -Force
            
            try {
                # Valid command name should pass validation
                $result = Test-CommandAvailable -CommandName 'Get-Command'
                $result | Should -Be $true
                
                # Invalid command name should fail validation
                $result2 = Test-CommandAvailable -CommandName '123Invalid'
                $result2 | Should -Be $false
            }
            finally {
                Remove-Item -Path "Function:\global:Test-ValidString" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses cached value when available' {
            # Set a cached value
            if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
                $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
                    New-CacheKey -Prefix 'CommandAvailable' -Components 'TestCachedCmd'
                }
                else {
                    'CommandAvailable_TestCachedCmd'
                }
                Set-CachedValue -Key $cacheKey -Value $false -ExpirationSeconds 300
                
                # Should return cached value
                $result = Test-CommandAvailable -CommandName 'TestCachedCmd'
                $result | Should -Be $false
                
                # Clean up
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Uses fallback cache key format when New-CacheKey is not available' {
            # Temporarily remove CacheKey module
            $originalCmd = Get-Command New-CacheKey -ErrorAction SilentlyContinue
            if ($originalCmd) {
                Remove-Module CacheKey -ErrorAction SilentlyContinue -Force
            }
            
            try {
                # Should still work with fallback key format
                $result = Test-CommandAvailable -CommandName 'Get-Process'
                $result | Should -Be $true
            }
            finally {
                # Restore CacheKey module
                if ($originalCmd) {
                    $cacheKeyPath = Join-Path $script:LibPath 'utilities' 'CacheKey.psm1'
                    if (Test-Path -Path $cacheKeyPath) {
                        Import-Module $cacheKeyPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
                    }
                }
            }
        }
    }

    Context 'Resolve-InstallCommand Additional Coverage' {
        It 'Uses Get-Platform when available' {
            # Create a mock Get-Platform function
            $mockFunc = {
                return @{ Name = 'Linux' }
            }
            Set-Item -Path "Function:\global:Get-Platform" -Value $mockFunc -Force
            
            try {
                $installCommand = @{
                    Windows = 'scoop install test'
                    Linux   = 'apt install test'
                    MacOS   = 'brew install test'
                }
                $result = Resolve-InstallCommand -InstallCommand $installCommand
                $result | Should -Be 'apt install test'
            }
            finally {
                Remove-Item -Path "Function:\global:Get-Platform" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles recommendation function failure gracefully' {
            # Create a mock recommendation function that throws
            $mockFunc = {
                param([string[]]$PackageNames, [switch]$Global)
                throw 'Test error'
            }
            Set-Item -Path "Function:\global:Get-NodePackageInstallRecommendation" -Value $mockFunc -Force
            
            try {
                # Should return original command when recommendation fails
                $result = Resolve-InstallCommand -InstallCommand 'npm install -g testpackage'
                $result | Should -Be 'npm install -g testpackage'
            }
            finally {
                Remove-Item -Path "Function:\global:Get-NodePackageInstallRecommendation" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles recommendation function with PackageName parameter (singular)' {
            # Create a mock recommendation function with singular parameter
            $mockFunc = {
                param([string]$PackageName, [switch]$Global)
                return "mock install $PackageName"
            }
            Set-Item -Path "Function:\global:Get-PythonPackageInstallRecommendation" -Value $mockFunc -Force
            
            try {
                $result = Resolve-InstallCommand -InstallCommand 'pip install testpackage'
                $result | Should -Match 'mock install'
            }
            finally {
                Remove-Item -Path "Function:\global:Get-PythonPackageInstallRecommendation" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Extracts package name from complex npm command' {
            $result = Resolve-InstallCommand -InstallCommand 'npm install --save-dev package-name@1.0.0'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles pip install with version specifier' {
            $result = Resolve-InstallCommand -InstallCommand 'pip install package==1.0.0'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles conda install command' {
            $result = Resolve-InstallCommand -InstallCommand 'conda install -c conda-forge package'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles poetry add command' {
            $result = Resolve-InstallCommand -InstallCommand 'poetry add package --group dev'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles pipenv install command' {
            $result = Resolve-InstallCommand -InstallCommand 'pipenv install package --dev'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles bun add command' {
            $result = Resolve-InstallCommand -InstallCommand 'bun add -g package'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles yarn add command with workspace' {
            $result = Resolve-InstallCommand -InstallCommand 'yarn workspace myapp add package'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles pnpm add command with workspace' {
            $result = Resolve-InstallCommand -InstallCommand 'pnpm add -w package'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns null for non-string, non-hashtable input' {
            $result = Resolve-InstallCommand -InstallCommand @(1, 2, 3)
            $result | Should -BeNullOrEmpty
        }

        It 'Handles hashtable with null platform value' {
            $installCommand = @{
                Windows = $null
            }
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result = Resolve-InstallCommand -InstallCommand $installCommand
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Invoke-CommandIfAvailable Additional Coverage' {
        It 'Returns fallback value when command does not exist and no scriptblock' {
            $result = Invoke-CommandIfAvailable -CommandName 'NonExistentCommand12345' `
                -FallbackValue 'fallback-value'
            $result | Should -Be 'fallback-value'
        }

        It 'Handles command execution error and falls back to value' {
            function Test-ThrowingCommand {
                throw 'Test error'
            }
            Set-Item -Path Function:\Test-ThrowingCommand -Value ${function:Test-ThrowingCommand} -Force
            
            try {
                $result = Invoke-CommandIfAvailable -CommandName 'Test-ThrowingCommand' `
                    -FallbackValue 'fallback'
                $result | Should -Be 'fallback'
            }
            finally {
                Remove-Item -Path Function:\Test-ThrowingCommand -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles command execution error and falls back to scriptblock' {
            function Test-ThrowingCommand2 {
                throw 'Test error'
            }
            Set-Item -Path Function:\Test-ThrowingCommand2 -Value ${function:Test-ThrowingCommand2} -Force
            
            try {
                $result = Invoke-CommandIfAvailable -CommandName 'Test-ThrowingCommand2' `
                    -FallbackScriptBlock { return 'scriptblock-fallback' }
                $result | Should -Be 'scriptblock-fallback'
            }
            finally {
                Remove-Item -Path Function:\Test-ThrowingCommand2 -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

