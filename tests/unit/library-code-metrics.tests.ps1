. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }
        
        # Import dependencies first (CodeMetrics module will import these, but we need them available for tests)
        $fileSystemPath = Join-Path $script:LibPath 'file' 'FileSystem.psm1'
        $astParsingPath = Join-Path $script:LibPath 'code-analysis' 'AstParsing.psm1'
        $fileContentPath = Join-Path $script:LibPath 'file' 'FileContent.psm1'
        $collectionsPath = Join-Path $script:LibPath 'utilities' 'Collections.psm1'
        
        if ($fileSystemPath -and (Test-Path -LiteralPath $fileSystemPath)) {
            Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
            Import-Module $fileSystemPath -DisableNameChecking -ErrorAction Stop -Force -Global
        }
        if ($astParsingPath -and (Test-Path -LiteralPath $astParsingPath)) {
            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
            Import-Module $astParsingPath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        if ($fileContentPath -and (Test-Path -LiteralPath $fileContentPath)) {
            Remove-Module FileContent -ErrorAction SilentlyContinue -Force
            Import-Module $fileContentPath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        if ($collectionsPath -and (Test-Path -LiteralPath $collectionsPath)) {
            Remove-Module Collections -ErrorAction SilentlyContinue -Force
            Import-Module $collectionsPath -DisableNameChecking -ErrorAction SilentlyContinue -Force -Global
        }
        
        # Import the module under test
        $script:CodeMetricsPath = Join-Path $script:LibPath 'metrics' 'CodeMetrics.psm1'
        if ($null -eq $script:CodeMetricsPath -or [string]::IsNullOrWhiteSpace($script:CodeMetricsPath)) {
            throw "CodeMetricsPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:CodeMetricsPath)) {
            throw "CodeMetrics module not found at: $script:CodeMetricsPath"
        }
        Import-Module $script:CodeMetricsPath -DisableNameChecking -ErrorAction Stop -Force
        
        # Create test directory and files
        $script:TestDir = Join-Path $env:TEMP "test-code-metrics-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
        
        # Create test PowerShell script
        $script:TestScript = Join-Path $script:TestDir 'test-script.ps1'
        $testContent = @'
function Test-Function1 {
    param([string]$Param1)
    Write-Host "Test 1"
    if ($Param1) {
        Write-Host "Has param"
    }
}

function Test-Function2 {
    Write-Host "Test 2"
}
'@
        Set-Content -Path $script:TestScript -Value $testContent -Encoding UTF8
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize CodeMetrics tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module CodeMetrics -ErrorAction SilentlyContinue -Force
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
    Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
    Remove-Module FileContent -ErrorAction SilentlyContinue -Force
    Remove-Module Collections -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and -not [string]::IsNullOrWhiteSpace($script:TestDir) -and (Test-Path -LiteralPath $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeMetrics Module Functions' {
    Context 'ConvertTo-FileMetricsArray' {
        It 'Converts null to empty array' {
            $result = @(ConvertTo-FileMetricsArray -InputList $null)
            $result | Should -Not -BeNull
            $result -is [System.Array] | Should -Be $true
            $result.Count | Should -Be 0
        }

        It 'Converts list to array' {
            $list = [System.Collections.Generic.List[object]]::new()
            $list.Add([PSCustomObject]@{ Name = 'Item1' })
            $list.Add([PSCustomObject]@{ Name = 'Item2' })
            
            $result = ConvertTo-FileMetricsArray -InputList $list
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result -is [System.Array] | Should -Be $true
        }

        It 'Returns array as-is' {
            $array = @('item1', 'item2')
            $result = ConvertTo-FileMetricsArray -InputList $array
            $result | Should -Be $array
        }

        It 'Wraps single object in array' {
            $obj = [PSCustomObject]@{ Name = 'Item' }
            $result = ConvertTo-FileMetricsArray -InputList $obj
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }
    }

    Context 'Get-CodeMetrics' {
        It 'Collects metrics for single file' {
            $result = Get-CodeMetrics -Path $script:TestScript
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Returns total lines count' {
            $result = Get-CodeMetrics -Path $script:TestScript
            $result.TotalLines | Should -BeGreaterThan 0
        }

        It 'Returns total functions count' {
            $result = Get-CodeMetrics -Path $script:TestScript
            $result.TotalFunctions | Should -BeGreaterOrEqual 0
        }

        It 'Returns file metrics array' {
            $result = Get-CodeMetrics -Path $script:TestScript
            $result.FileMetrics | Should -Not -BeNullOrEmpty
            $result.FileMetrics -is [System.Array] | Should -Be $true
            if ($null -ne $result.FileMetrics) {
                $result.FileMetrics.Count | Should -BeGreaterOrEqual 1
            }
        }

        It 'Analyzes directory when path is directory' {
            $result = Get-CodeMetrics -Path $script:TestDir
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Recurses subdirectories when Recurse specified' {
            $subDir = Join-Path $script:TestDir 'subdir'
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null
            $subScript = Join-Path $subDir 'sub-script.ps1'
            Set-Content -Path $subScript -Value 'function Test-Sub { }' -Encoding UTF8
            
            $result = Get-CodeMetrics -Path $script:TestDir -Recurse
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles files that cannot be parsed' {
            $invalidScript = Join-Path $script:TestDir 'invalid.ps1'
            Set-Content -Path $invalidScript -Value '{ invalid syntax }' -Encoding UTF8
            
            # Should not throw, but may have reduced metrics
            { Get-CodeMetrics -Path $invalidScript } | Should -Not -Throw
        }

        It 'Throws error when Get-PowerShellScripts not available' {
            # Temporarily remove FileSystem module
            Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
            
            { Get-CodeMetrics -Path $script:TestScript } | Should -Throw "*Get-PowerShellScripts*"
            
            # Re-import FileSystem
            $fileSystemPath = Join-Path $script:LibPath 'file' 'FileSystem.psm1'
            if ($fileSystemPath -and (Test-Path -LiteralPath $fileSystemPath)) {
                Import-Module $fileSystemPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
        }
    }
}

