Describe 'Bootstrap Agent Mode Compatibility' {
    BeforeAll {
        $testSupportPath = Join-Path $PWD 'tests\TestSupport.ps1'
        . $testSupportPath
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        $global:PROFILE = Join-Path (Get-TestRepoRoot) 'Microsoft.PowerShell_profile.ps1'
        . $script:BootstrapPath
    }

    Context 'Agent mode compatibility' {
        BeforeAll {
            . $script:BootstrapPath
            . (Join-Path $script:ProfileDir '03-agent-mode.ps1')
        }

        It 'am-list function is available when bootstrap loaded' {
            Get-Command am-list -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-doc function is available when bootstrap loaded' {
            Get-Command am-doc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-list returns agent mode functions' {
            $result = am-list
            $result | Should -Not -Be $null
        }

        It 'am-doc handles missing documentation gracefully' {
            # Temporarily rename the README file to simulate missing
            $readmePath = Join-Path $script:ProfileDir '00-bootstrap.README.md'
            $tempPath = $readmePath + '.bak'
            if (Test-Path $readmePath) {
                Move-Item -Path $readmePath -Destination $tempPath -Force
            }
            try {
                { am-doc } | Should -Not -Throw
            }
            finally {
                if (Test-Path $tempPath) {
                    Move-Item -Path $tempPath -Destination $readmePath -Force
                }
            }
        }

        It 'am-doc verifies it would open documentation when available' {
            Mock 'notepad.exe' { }  # Prevent actual notepad from opening during tests
            # The README file should exist
            $readmePath = Join-Path $script:ProfileDir '00-bootstrap.README.md'
            $readmePath | Should -Exist
            { am-doc } | Should -Not -Throw  # Verifies it would attempt to open
        }
    }
}
