# ===============================================
# profile-api-tools-hurl.tests.ps1
# Unit tests for Invoke-Hurl function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')

    $script:TestDataDir = New-TestTempDirectory -Prefix 'HurlTest'
    $script:TestHurlFile = Join-Path $script:TestDataDir 'test.hurl'
    Set-Content -Path $script:TestHurlFile -Value 'GET https://api.example.com/test'
}

Describe 'api-tools.ps1 - Invoke-Hurl' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'hurl' -Available $false
        Remove-Item -Path Function:\hurl -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:hurl -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\hurl -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:hurl -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when hurl is not available' {
            Set-TestCommandAvailabilityState -CommandName 'hurl' -Available $false

            $result = Invoke-Hurl -TestFile $script:TestHurlFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls hurl with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'hurl' -Output 'Test executed'

            $result = Invoke-Hurl -TestFile $script:TestHurlFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $script:TestHurlFile
        }

        It 'Includes variable parameters when specified' {
            Setup-CapturingCommandMock -CommandName 'hurl' -Output 'Test executed'

            $result = Invoke-Hurl -TestFile $script:TestHurlFile -Variable 'base_url=https://api.example.com', 'token=abc123'

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--variable'
            $args | Should -Contain 'base_url=https://api.example.com'
            $args | Should -Contain 'token=abc123'
        }

        It 'Includes output parameter when specified' {
            Setup-CapturingCommandMock -CommandName 'hurl' -Output 'Test executed'

            $outputFile = Join-Path (New-TestTempDirectory -Prefix 'HurlOutput') 'output.json'
            $result = Invoke-Hurl -TestFile $script:TestHurlFile -Output $outputFile

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--output'
            $args | Should -Contain $outputFile
        }

        It 'Returns error when test file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'hurl'
            $missingFile = Join-Path (New-TestTempDirectory -Prefix 'HurlMissingParent') 'test.hurl'

            $result = Invoke-Hurl -TestFile $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles pipeline input for TestFile' {
            Setup-CapturingCommandMock -CommandName 'hurl' -Output 'Test executed'

            $result = $script:TestHurlFile | Invoke-Hurl

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $script:TestHurlFile
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'hurl' -Message 'hurl failed'

            { Invoke-Hurl -TestFile $script:TestHurlFile } | Should -Throw '*hurl*'
        }
    }
}
