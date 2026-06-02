# ===============================================
# profile-git-enhanced-gui.tests.ps1
# Unit tests for Invoke-GitTower and Invoke-GitKraken functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - Invoke-GitTower' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'git-tower' -Available $false
        Remove-Item -Path 'Function:\git-tower' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:git-tower' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when git-tower is not available' {
            $result = Invoke-GitTower -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches git-tower with default path' {
            Setup-AvailableCommandMock -CommandName 'git-tower'

            Invoke-GitTower -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'git-tower'
            $capture.ArgumentList | Should -Not -BeNullOrEmpty
        }

        It 'Launches git-tower with custom repository path' {
            Setup-AvailableCommandMock -CommandName 'git-tower'

            Invoke-GitTower -RepositoryPath 'C:\Projects\MyRepo' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain 'C:\Projects\MyRepo'
        }

        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'git-tower'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Invoke-GitTower -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}

Describe 'git-enhanced.ps1 - Invoke-GitKraken' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'gitkraken' -Available $false
        Remove-Item -Path 'Function:\gitkraken' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:gitkraken' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when gitkraken is not available' {
            $result = Invoke-GitKraken -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches gitkraken with default path' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'

            Invoke-GitKraken -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'gitkraken'
            $capture.ArgumentList | Should -Not -BeNullOrEmpty
        }

        It 'Launches gitkraken with custom repository path' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'

            Invoke-GitKraken -RepositoryPath 'C:\Projects\MyRepo' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain 'C:\Projects\MyRepo'
        }

        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'gitkraken'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Invoke-GitKraken -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
