. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'DataFile Module Functions' {
    BeforeAll {
        # Import the DataFile module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'DataFile.psm1') -DisableNameChecking -ErrorAction Stop
        $script:TestTempDir = New-TestTempDirectory -Prefix 'DataFileTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Import-CachedPowerShellDataFile' {
        It 'Throws error for non-existent file' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent.psd1'
            { Import-CachedPowerShellDataFile -Path $nonExistentFile } | Should -Throw
        }

        It 'Imports valid PowerShell data file' {
            $testData = @'
@{
    Name = "TestModule"
    Version = "1.0.0"
    Functions = @("Test-Function1", "Test-Function2")
}
'@
            $testFile = Join-Path $script:TestTempDir 'test.psd1'
            $testData | Set-Content -Path $testFile -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestModule'
            $result.Version | Should -Be '1.0.0'
        }

        It 'Uses cache on second call' {
            $testData = @'
@{
    TestValue = "cached"
}
'@
            $testFile = Join-Path $script:TestTempDir 'cache-test.psd1'
            $testData | Set-Content -Path $testFile -Encoding UTF8

            $result1 = Import-CachedPowerShellDataFile -Path $testFile
            $result2 = Import-CachedPowerShellDataFile -Path $testFile
            $result1.TestValue | Should -Be $result2.TestValue
        }
    }
}
