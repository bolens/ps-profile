# ===============================================
# profile-api-tools-bruno.tests.ps1
# Unit tests for Invoke-Bruno function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')

    $script:TestCollectionPath = New-TestTempDirectory -Prefix 'BrunoCollection'
}

Describe 'api-tools.ps1 - Invoke-Bruno' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'bruno' -Available $false
        Remove-Item -Path Function:\bruno -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:bruno -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\bruno -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:bruno -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when bruno is not available' {
            Set-TestCommandAvailabilityState -CommandName 'bruno' -Available $false

            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls bruno with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'bruno' -Output 'Collection executed'

            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'run'
            $args | Should -Contain $script:TestCollectionPath
        }

        It 'Includes environment parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'bruno' -Output 'Collection executed'

            $result = Invoke-Bruno -CollectionPath $script:TestCollectionPath -Environment 'production'

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--env'
            $args | Should -Contain 'production'
        }

        It 'Uses current directory when CollectionPath is not specified' {
            Setup-CapturingCommandMock -CommandName 'bruno' -Output 'Collection executed'

            $currentPath = (Get-Location).Path
            $result = Invoke-Bruno

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $currentPath
        }

        It 'Returns error when collection path does not exist' {
            Setup-AvailableCommandMock -CommandName 'bruno'
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'BrunoMissingParent') 'nonexistent-collection'

            $result = Invoke-Bruno -CollectionPath $missingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles pipeline input for CollectionPath' {
            Setup-CapturingCommandMock -CommandName 'bruno' -Output 'Collection executed'

            $result = $script:TestCollectionPath | Invoke-Bruno

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $script:TestCollectionPath
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'bruno' -Message 'bruno failed'

            { Invoke-Bruno -CollectionPath $script:TestCollectionPath } | Should -Throw '*bruno*'
        }
    }
}
