# ===============================================
# profile-api-tools-insomnia.tests.ps1
# Unit tests for Invoke-Insomnia function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')

    $script:TestCollectionPath = New-TestTempDirectory -Prefix 'InsomniaCollection'
}

Describe 'api-tools.ps1 - Invoke-Insomnia' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'insomnia' -Available $false
        Remove-Item -Path Function:\insomnia -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:insomnia -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\insomnia -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:insomnia -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when insomnia is not available' {
            Set-TestCommandAvailabilityState -CommandName 'insomnia' -Available $false

            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls insomnia with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'insomnia' -Output 'Collection executed'

            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'run'
            $args | Should -Contain $script:TestCollectionPath
        }

        It 'Includes environment parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'insomnia' -Output 'Collection executed'

            $result = Invoke-Insomnia -CollectionPath $script:TestCollectionPath -Environment 'production'

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--env'
            $args | Should -Contain 'production'
        }

        It 'Uses current directory when CollectionPath is not specified' {
            Setup-CapturingCommandMock -CommandName 'insomnia' -Output 'Collection executed'

            $currentPath = (Get-Location).Path
            $result = Invoke-Insomnia

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $currentPath
        }

        It 'Returns error when collection path does not exist' {
            Setup-AvailableCommandMock -CommandName 'insomnia'
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'InsomniaMissingParent') 'nonexistent-collection'

            $result = Invoke-Insomnia -CollectionPath $missingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles pipeline input for CollectionPath' {
            Setup-CapturingCommandMock -CommandName 'insomnia' -Output 'Collection executed'

            $result = $script:TestCollectionPath | Invoke-Insomnia

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $script:TestCollectionPath
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'insomnia' -Message 'insomnia failed'

            { Invoke-Insomnia -CollectionPath $script:TestCollectionPath } | Should -Throw '*insomnia*'
        }
    }
}
