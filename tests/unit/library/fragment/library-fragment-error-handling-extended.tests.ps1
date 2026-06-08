<#
tests/unit/library-fragment-error-handling-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for fragment safe execution and error metadata.
#>

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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Logging.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'fragment' 'FragmentErrorHandling.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentErrorExtended'
    $script:ValidFragment = Join-Path $script:TempDir 'valid.ps1'
    $script:SyntaxFragment = Join-Path $script:TempDir 'syntax-error.ps1'

    Set-Content -LiteralPath $script:ValidFragment -Value @'
$global:FragmentExtendedLoaded = 'yes'
'@ -Encoding UTF8

    Set-Content -LiteralPath $script:SyntaxFragment -Value @'
function Broken-Fragment {
    # missing closing brace
'@ -Encoding UTF8
}

AfterAll {
    Remove-Module FragmentErrorHandling, Logging -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentErrorHandling extended scenarios' {
    AfterEach {
        Remove-Item Variable:global:FragmentExtendedLoaded -ErrorAction SilentlyContinue
    }

    Context 'Invoke-FragmentSafely' {
        It 'Dot-sources valid fragment files successfully' {
            $result = Invoke-FragmentSafely -FragmentName 'valid-extended' -FragmentPath $script:ValidFragment

            $result | Should -Be $true
            $global:FragmentExtendedLoaded | Should -Be 'yes'
        }

        It 'Returns false when fragment files contain syntax errors' {
            $result = Invoke-FragmentSafely -FragmentName 'syntax-extended' -FragmentPath $script:SyntaxFragment

            $result | Should -Be $false
        }
    }

    Context 'Get-FragmentErrorInfo' {
        It 'Uses short exception type names in error metadata' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new('missing fragment dependency'),
                'FragmentDependencyMissing',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )

            $info = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'dependency-fragment'

            $info.ErrorType | Should -Be 'FileNotFoundException'
            $info.FullyQualifiedErrorId | Should -Be 'FragmentDependencyMissing'
        }
    }

    Context 'Write-FragmentError' {
        It 'Writes errors without context labels when Context is omitted' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [Exception]::new('fragment load failed'),
                'FragmentLoadFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-FragmentError -ErrorRecord $errorRecord -FragmentName 'plain-error' -ErrorAction SilentlyContinue -ErrorVariable writtenErrors | Out-Null

            $writtenErrors | Should -Not -BeNullOrEmpty
        }
    }
}
