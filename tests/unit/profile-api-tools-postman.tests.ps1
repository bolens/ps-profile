# ===============================================
# profile-api-tools-postman.tests.ps1
# Unit tests for Invoke-Postman function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')

    $script:TestDataDir = New-TestTempDirectory -Prefix 'PostmanCollection'
    $script:TestCollectionFile = Join-Path $script:TestDataDir 'collection.json'
    $script:TestEnvironmentFile = Join-Path $script:TestDataDir 'environment.json'
    Set-Content -Path $script:TestCollectionFile -Value '{"info":{"name":"Test Collection"}}'
    Set-Content -Path $script:TestEnvironmentFile -Value '{"name":"test"}'
}

Describe 'api-tools.ps1 - Invoke-Postman' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'newman' -Available $false
        Remove-Item -Path Function:\newman -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:newman -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\postman -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:postman -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when newman is not available' {
            Set-TestCommandAvailabilityState -CommandName 'newman' -Available $false

            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls newman with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'run'
            $args | Should -Contain $script:TestCollectionFile
        }

        It 'Includes environment parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Environment $script:TestEnvironmentFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--environment'
            $args | Should -Contain $script:TestEnvironmentFile
        }

        It 'Includes reporters when specified' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Reporters 'html', 'json'

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--reporter'
            $args | Should -Contain 'html'
            $args | Should -Contain 'json'
        }

        It 'Includes output file when specified with single reporter' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $outputFile = Join-Path (New-TestTempDirectory -Prefix 'PostmanReport') 'report.html'
            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Reporters 'html' -OutputFile $outputFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $outputFile
        }

        It 'Accepts URL for collection path' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $collectionUrl = 'https://api.postman.com/collections/12345'
            $result = Invoke-Postman -CollectionPath $collectionUrl

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $collectionUrl
        }

        It 'Returns error when collection path does not exist and is not a URL' {
            Setup-AvailableCommandMock -CommandName 'newman'
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'PostmanMissingParent') 'collection.json'

            $result = Invoke-Postman -CollectionPath $missingPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when environment file does not exist' {
            Setup-AvailableCommandMock -CommandName 'newman'
            $missingEnv = Join-Path (New-TestTempDirectory -Prefix 'PostmanMissingEnv') 'environment.json'

            $result = Invoke-Postman -CollectionPath $script:TestCollectionFile -Environment $missingEnv -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles pipeline input for CollectionPath' {
            Setup-CapturingCommandMock -CommandName 'newman' -Output 'Collection executed'

            $result = $script:TestCollectionFile | Invoke-Postman

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $script:TestCollectionFile
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'newman' -Message 'newman failed'

            { Invoke-Postman -CollectionPath $script:TestCollectionFile } | Should -Throw '*newman*'
        }
    }
}
