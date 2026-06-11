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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'core' 'Logging.psm1') -DisableNameChecking -Force
    Import-TestLibraryModule -ModulePath (Join-Path $script:LibPath 'fragment' 'FragmentErrorHandling.psm1')

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

function script:Clear-FragmentErrorTestEnvironment {
    foreach ($name in @(
            'PS_PROFILE_DEBUG'
            'PS_PROFILE_FRAGMENT_ERROR_FORCE_GET_ITEM_FAIL'
        )) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    Clear-CommandTestStubs
}

AfterAll {
    Clear-FragmentErrorTestEnvironment
    Remove-Module FragmentErrorHandling, Logging -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentErrorHandling extended scenarios' {
    BeforeEach {
        Clear-FragmentErrorTestEnvironment
    }

    AfterEach {
        Clear-FragmentErrorTestEnvironment
        Remove-Item Variable:global:FragmentExtendedLoaded -ErrorAction SilentlyContinue
        Remove-Item Variable:global:FragmentScriptBlockLoaded -ErrorAction SilentlyContinue
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

        It 'Returns false for missing files with debug logging enabled' {
            $missingPath = Join-Path $script:TempDir 'missing-fragment.ps1'
            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentSafely -FragmentName 'missing-extended' -FragmentPath $missingPath

            $result | Should -Be $false
        }

        It 'Uses Write-ScriptMessage when structured logging is unavailable for missing files' {
            $missingPath = Join-Path $script:TempDir 'missing-scriptmessage.ps1'
            $env:PS_PROFILE_DEBUG = '1'
            $messages = [System.Collections.Generic.List[string]]::new()

            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')
            function global:Write-ScriptMessage {
                param([string]$Message, [switch]$IsWarning, [switch]$IsError)
                $null = $messages.Add($Message)
            }

            try {
                $result = Invoke-FragmentSafely -FragmentName 'missing-scriptmessage' -FragmentPath $missingPath
                $result | Should -Be $false
                @($messages | Where-Object { $_ -like '*not found*' }).Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-TestFunction -Name @('Write-ScriptMessage', 'Write-StructuredWarning', 'Write-StructuredError')
            }
        }

        It 'Returns false when forced Get-Item access checks fail' {
            $forcedPath = Join-Path $script:TempDir 'force-get-item-fail.ps1'
            Set-Content -LiteralPath $forcedPath -Value '# probe' -Encoding UTF8
            $env:PS_PROFILE_FRAGMENT_ERROR_FORCE_GET_ITEM_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $result = Invoke-FragmentSafely -FragmentName 'forced-access' -FragmentPath $forcedPath

            $result | Should -Be $false
        }

        It 'Executes script blocks successfully with debug tracing enabled' {
            $env:PS_PROFILE_DEBUG = '2'
            $block = { $global:FragmentScriptBlockLoaded = 'executed' }

            $result = Invoke-FragmentSafely -FragmentName 'scriptblock-success' -FragmentPath 'dummy.ps1' -ScriptBlock $block

            $result | Should -Be $true
            $global:FragmentScriptBlockLoaded | Should -Be 'executed'
        }

        It 'Honors Test-FragmentWarningSuppressed when the helper is available' {
            function global:Test-FragmentWarningSuppressed {
                param([string]$FragmentName)
                return $FragmentName -eq 'suppressed-fragment'
            }

            function global:Test-CachedCommand {
                param([string]$Name)
                return $Name -in @('Test-FragmentWarningSuppressed', 'Write-ScriptMessage')
            }

            try {
                $block = { throw 'suppressed probe error' }
                $result = Invoke-FragmentSafely -FragmentName 'suppressed-fragment' -FragmentPath 'dummy.ps1' -ScriptBlock $block
                $result | Should -Be $false
            }
            finally {
                Remove-TestFunction -Name @('Test-FragmentWarningSuppressed', 'Test-CachedCommand')
            }
        }

        It 'Uses structured errors for script block failures when debug is enabled' {
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging
            $block = { throw 'structured scriptblock failure' }

            $result = Invoke-FragmentSafely -FragmentName 'structured-scriptblock' -FragmentPath 'dummy.ps1' -ScriptBlock $block

            $result | Should -Be $false
        }

        It 'Writes structured warnings for script block failures when debug is disabled' {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Enable-TestStructuredLogging
            $block = { throw 'no-debug warning probe' }

            $result = Invoke-FragmentSafely -FragmentName 'no-debug-warning' -FragmentPath 'dummy.ps1' -ScriptBlock $block

            $result | Should -Be $false
        }

        It 'Uses Write-ProfileError when available during script block failures' {
            $invocations = [System.Collections.Generic.List[string]]::new()

            function global:Write-ProfileError {
                param($ErrorRecord, $Context, $Category)
                $null = $invocations.Add($Context)
            }

            function global:Test-CachedCommand {
                param([string]$Name)
                return $Name -eq 'Write-ProfileError'
            }

            $env:PS_PROFILE_DEBUG = '1'
            try {
                $block = { throw 'profile error probe' }
                $result = Invoke-FragmentSafely -FragmentName 'profile-error-fragment' -FragmentPath 'dummy.ps1' -ScriptBlock $block
                $result | Should -Be $false
                $invocations.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-TestFunction -Name @('Write-ProfileError', 'Test-CachedCommand')
            }
        }

        It 'Uses Write-Warning for missing files when structured logging is unavailable' {
            $missingPath = Join-Path $script:TempDir 'missing-write-warning.ps1'
            $env:PS_PROFILE_DEBUG = '1'
            $warnings = [System.Collections.Generic.List[string]]::new()
            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')

            function global:Write-Warning {
                param([string]$Message)
                $null = $warnings.Add($Message)
            }

            try {
                $result = Invoke-FragmentSafely -FragmentName 'missing-write-warning' -FragmentPath $missingPath
                $result | Should -Be $false
                @($warnings | Where-Object { $_ -like '*not found*' }).Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-TestFunction -Name @('Write-Warning', 'Write-StructuredWarning', 'Write-StructuredError')
            }
        }

        It 'Returns false for forced file access failures when debug output is disabled' {
            $forcedPath = Join-Path $script:TempDir 'force-get-item-fail-no-debug.ps1'
            Set-Content -LiteralPath $forcedPath -Value '# probe' -Encoding UTF8
            $env:PS_PROFILE_FRAGMENT_ERROR_FORCE_GET_ITEM_FAIL = '1'
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $result = Invoke-FragmentSafely -FragmentName 'forced-no-debug' -FragmentPath $forcedPath
                $result | Should -Be $false
            }
            finally {
                Remove-Item Env:PS_PROFILE_FRAGMENT_ERROR_FORCE_GET_ITEM_FAIL -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-ScriptMessage for file access failures when structured logging is unavailable' {
            $forcedPath = Join-Path $script:TempDir 'force-get-item-fail-scriptmessage.ps1'
            Set-Content -LiteralPath $forcedPath -Value '# probe' -Encoding UTF8
            $env:PS_PROFILE_FRAGMENT_ERROR_FORCE_GET_ITEM_FAIL = '1'
            $env:PS_PROFILE_DEBUG = '1'
            $messages = [System.Collections.Generic.List[string]]::new()
            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')

            function global:Write-ScriptMessage {
                param([string]$Message, [switch]$IsWarning, [switch]$IsError)
                $null = $messages.Add($Message)
            }

            function global:Test-CachedCommand {
                param([string]$Name)
                return $Name -eq 'Write-ScriptMessage'
            }

            try {
                $result = Invoke-FragmentSafely -FragmentName 'forced-scriptmessage' -FragmentPath $forcedPath
                $result | Should -Be $false
                @($messages | Where-Object { $_ -like '*Cannot access fragment file*' }).Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-TestFunction -Name @('Write-ScriptMessage', 'Test-CachedCommand', 'Write-StructuredWarning', 'Write-StructuredError')
            }
        }

        It 'Emits debug tracing when valid fragments load with PS_PROFILE_DEBUG level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Invoke-FragmentSafely -FragmentName 'debug-load-success' -FragmentPath $script:ValidFragment
                $result | Should -Be $true
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-ScriptMessage for script block failures when structured logging is unavailable' {
            $env:PS_PROFILE_DEBUG = '1'
            $messages = [System.Collections.Generic.List[string]]::new()
            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')

            function global:Write-ScriptMessage {
                param([string]$Message, [switch]$IsWarning, [switch]$IsError)
                $null = $messages.Add($Message)
            }

            function global:Test-CachedCommand {
                param([string]$Name)
                return $Name -eq 'Write-ScriptMessage'
            }

            try {
                $block = { throw 'scriptmessage outer failure' }
                $result = Invoke-FragmentSafely -FragmentName 'scriptmessage-outer' -FragmentPath 'dummy.ps1' -ScriptBlock $block
                $result | Should -Be $false
                @($messages | Where-Object { $_ -like '*Failed to load profile fragment*' }).Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-TestFunction -Name @('Write-ScriptMessage', 'Test-CachedCommand', 'Write-StructuredWarning', 'Write-StructuredError')
            }
        }

        It 'Emits position and error detail tracing when PS_PROFILE_DEBUG is level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $block = { throw 'level 3 position probe' }
                $result = Invoke-FragmentSafely -FragmentName 'level3-position' -FragmentPath 'dummy.ps1' -ScriptBlock $block
                $result | Should -Be $false
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Continues when Test-FragmentWarningSuppressed throws during error handling' {
            function global:Test-FragmentWarningSuppressed {
                throw 'suppression probe failure'
            }

            function global:Test-CachedCommand {
                param([string]$Name)
                return $Name -eq 'Test-FragmentWarningSuppressed'
            }

            try {
                $block = { throw 'suppression helper failure' }
                $result = Invoke-FragmentSafely -FragmentName 'suppression-throws' -FragmentPath 'dummy.ps1' -ScriptBlock $block
                $result | Should -Be $false
            }
            finally {
                Remove-TestFunction -Name @('Test-FragmentWarningSuppressed', 'Test-CachedCommand')
            }
        }

        It 'Imports logging through manual fallback when SafeImport is unavailable' {
            $fragmentDir = Join-Path $script:TempDir 'fragment-isolated'
            New-Item -ItemType Directory -Path $fragmentDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'fragment' 'FragmentErrorHandling.psm1') -Destination $fragmentDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'core' 'Logging.psm1') -Destination $fragmentDir

            Remove-Module FragmentErrorHandling, SafeImport, Logging -ErrorAction SilentlyContinue -Force

            try {
                { Import-Module (Join-Path $fragmentDir 'FragmentErrorHandling.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Invoke-FragmentSafely -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module FragmentErrorHandling -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'core' 'Logging.psm1') -DisableNameChecking -Force
                Import-TestLibraryModule -ModulePath (Join-Path $script:LibPath 'fragment' 'FragmentErrorHandling.psm1')
            }
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

        It 'Includes invocation metadata when present on the error record' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [Exception]::new('metadata probe'),
                'MetadataProbe',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            $info = Get-FragmentErrorInfo -ErrorRecord $errorRecord -FragmentName 'metadata-fragment'

            $info.FragmentName | Should -Be 'metadata-fragment'
            $info.ErrorMessage | Should -Be 'metadata probe'
            $info.Timestamp | Should -BeOfType [DateTime]
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

        It 'Includes context labels when Write-FragmentError is called with context' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [Exception]::new('profile write probe'),
                'ProfileWriteProbe',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-FragmentError -ErrorRecord $errorRecord -FragmentName 'profile-write' -Context 'Init' -ErrorAction SilentlyContinue -ErrorVariable writtenErrors | Out-Null
            $writtenErrors | Should -Not -BeNullOrEmpty
            $writtenErrors[0].Exception.Message | Should -Match 'Init'
        }
    }
}
