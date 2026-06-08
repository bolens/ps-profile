# ===============================================
# profile-database-clients-mongodb.tests.ps1
# Unit tests for Start-MongoDbCompass function
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
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Start-MongoDbCompass' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'mongodb-compass' -Available $false
        Remove-Item -Path Function:\mongodb-compass -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:mongodb-compass -Force -ErrorAction SilentlyContinue

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when mongodb-compass is not available' {
            Set-TestCommandAvailabilityState -CommandName 'mongodb-compass' -Available $false

            $result = Start-MongoDbCompass -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Starts mongodb-compass without connection string' {
            Set-TestCommandAvailabilityState -CommandName 'mongodb-compass'

            $result = Start-MongoDbCompass

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'mongodb-compass'
            $capture.PassThru | Should -Be $true
        }

        It 'Starts mongodb-compass with connection string' {
            Set-TestCommandAvailabilityState -CommandName 'mongodb-compass'

            $connectionString = 'mongodb://localhost:27017'
            $result = Start-MongoDbCompass -ConnectionString $connectionString

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $connectionString
        }

        It 'Handles process start errors' {
            Set-TestCommandAvailabilityState -CommandName 'mongodb-compass'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Start-MongoDbCompass -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
