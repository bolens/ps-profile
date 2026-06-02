# ===============================================
# profile-api-tools-httpie.tests.ps1
# Unit tests for Invoke-Httpie function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
}

Describe 'api-tools.ps1 - Invoke-Httpie' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'http' -Available $false
        Remove-Item -Path Function:\http -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:http -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when httpie is not available' {
            Set-TestCommandAvailabilityState -CommandName 'http' -Available $false

            $result = Invoke-Httpie -Url 'https://api.example.com/test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls http with GET method by default' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $testUrl
            $args | Should -Not -Contain 'GET'
        }

        It 'Calls http with specified method' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Method POST -Url $testUrl

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'POST'
            $args | Should -Contain $testUrl
        }

        It 'Includes body parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $testUrl = 'https://api.example.com/test'
            $testBody = '{"name":"test"}'
            $result = Invoke-Httpie -Method POST -Url $testUrl -Body $testBody

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $testBody
        }

        It 'Includes header parameters when specified' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl -Header 'Authorization: Bearer token', 'Content-Type: application/json'

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'Authorization: Bearer token'
            $args | Should -Contain 'Content-Type: application/json'
        }

        It 'Includes output parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $outputFile = Join-Path (New-TestTempDirectory -Prefix 'HttpieOutput') 'output.json'
            $testUrl = 'https://api.example.com/test'
            $result = Invoke-Httpie -Url $testUrl -Output $outputFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--output'
            $args | Should -Contain $outputFile
        }

        It 'Returns error when URL is null or whitespace' {
            Setup-AvailableCommandMock -CommandName 'http'

            $result = Invoke-Httpie -Url '   ' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles pipeline input for Url' {
            Setup-CapturingCommandMock -CommandName 'http' -Output 'Response'

            $testUrl = 'https://api.example.com/test'
            $result = $testUrl | Invoke-Httpie

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $testUrl
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'http' -Message 'http failed'

            { Invoke-Httpie -Url 'https://api.example.com/test' } | Should -Throw '*http*'
        }
    }
}
