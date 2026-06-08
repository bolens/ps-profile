# ===============================================
# TerminalTestStubs.ps1
# Non-Pester stubs for terminal integration tests
# ===============================================

$script:OriginalWriteHostCommand = $null
$script:OriginalGetHistoryCommand = $null
$script:OriginalClearHistoryCommand = $null
$script:OriginalGetModuleCommand = $null
$script:OriginalReadHostCommand = $null
$script:TestProfileFunctionOriginals = @{}

function Register-TestWriteHostCapture {
    Clear-TestWriteHostCapture

    if (-not $script:OriginalWriteHostCommand) {
        $existing = Get-Command Write-Host -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:OriginalWriteHostCommand = $existing.ScriptBlock
        }
    }

    if (-not (Get-Variable -Name 'TestWriteHostCaptures' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestWriteHostCaptures = [System.Collections.Generic.List[string]]::new()
    }

    $captureBlock = {
        param(
            [object]$Object,
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Remaining
        )

        $text = if ($null -eq $Object) { '' } else { [string]$Object }
        $null = $global:TestWriteHostCaptures.Add($text)
    }

    Set-Item -Path 'Function:\global:Write-Host' -Value $captureBlock -Force -ErrorAction SilentlyContinue
}

function Clear-TestWriteHostCapture {
    if (Get-Variable -Name 'TestWriteHostCaptures' -Scope Global -ErrorAction SilentlyContinue) {
        $global:TestWriteHostCaptures.Clear()
    }
}

function Get-TestWriteHostOutputString {
    if (-not (Get-Variable -Name 'TestWriteHostCaptures' -Scope Global -ErrorAction SilentlyContinue) `
            -or $global:TestWriteHostCaptures.Count -eq 0) {
        return ''
    }

    return ($global:TestWriteHostCaptures -join '')
}

function Get-TestWriteHostCaptureCount {
    if (-not (Get-Variable -Name 'TestWriteHostCaptures' -Scope Global -ErrorAction SilentlyContinue)) {
        return 0
    }

    return $global:TestWriteHostCaptures.Count
}

function Restore-TestWriteHostCapture {
    Clear-TestWriteHostCapture

    if ($script:OriginalWriteHostCommand) {
        Set-Item -Path 'Function:\global:Write-Host' -Value $script:OriginalWriteHostCommand -Force -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item -Path 'Function:\global:Write-Host' -Force -ErrorAction SilentlyContinue
    }
}

function Register-TestGetHistoryStub {
    [CmdletBinding()]
    param(
        [object]$ReturnValue = @()
    )

    Clear-TestGetHistoryStub
    $global:TestGetHistoryInvocationCount = 0
    $global:TestGetHistoryReturnValue = $ReturnValue

    if (-not $script:OriginalGetHistoryCommand) {
        $existing = Get-Command Get-History -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:OriginalGetHistoryCommand = $existing.ScriptBlock
        }
    }

    $stub = {
        $global:TestGetHistoryInvocationCount++
        return $global:TestGetHistoryReturnValue
    }

    Set-Item -Path 'Function:\global:Get-History' -Value $stub -Force -ErrorAction SilentlyContinue
}

function Clear-TestGetHistoryStub {
    $global:TestGetHistoryInvocationCount = 0
    $global:TestGetHistoryReturnValue = $null
}

function Assert-TestGetHistoryInvoked {
    [CmdletBinding()]
    param(
        [int]$Times = 1
    )

    $count = if (Get-Variable -Name 'TestGetHistoryInvocationCount' -Scope Global -ErrorAction SilentlyContinue) {
        [int]$global:TestGetHistoryInvocationCount
    }
    else {
        0
    }

    $count | Should -Be $Times
}

function Restore-TestGetHistoryStub {
    Clear-TestGetHistoryStub

    if ($script:OriginalGetHistoryCommand) {
        Set-Item -Path 'Function:\global:Get-History' -Value $script:OriginalGetHistoryCommand -Force -ErrorAction SilentlyContinue
    }
    else {
        # Remove both scopes so the built-in Get-History cmdlet is visible again.
        Remove-Item -Path 'Function:\Get-History' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:Get-History' -Force -ErrorAction SilentlyContinue
    }
}

function Register-TestClearHistoryStub {
    Clear-TestClearHistoryStub
    $global:TestClearHistoryInvocationCount = 0

    if (-not $script:OriginalClearHistoryCommand) {
        $existing = Get-Command Clear-History -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:OriginalClearHistoryCommand = $existing.ScriptBlock
        }
    }

    $stub = {
        $global:TestClearHistoryInvocationCount++
    }

    Set-Item -Path 'Function:\global:Clear-History' -Value $stub -Force -ErrorAction SilentlyContinue
}

function Clear-TestClearHistoryStub {
    $global:TestClearHistoryInvocationCount = 0
}

function Assert-TestClearHistoryInvoked {
    [CmdletBinding()]
    param(
        [int]$Times = 1
    )

    $count = if (Get-Variable -Name 'TestClearHistoryInvocationCount' -Scope Global -ErrorAction SilentlyContinue) {
        [int]$global:TestClearHistoryInvocationCount
    }
    else {
        0
    }

    $count | Should -Be $Times
}

function Restore-TestClearHistoryStub {
    Clear-TestClearHistoryStub

    if ($script:OriginalClearHistoryCommand) {
        Set-Item -Path 'Function:\global:Clear-History' -Value $script:OriginalClearHistoryCommand -Force -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item -Path 'Function:\Clear-History' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:Clear-History' -Force -ErrorAction SilentlyContinue
    }
}

function Set-TestReadHostResponse {
    [CmdletBinding()]
    param(
        [string]$Response = 'n'
    )

    if (-not $script:OriginalReadHostCommand) {
        $existing = Get-Command Read-Host -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:OriginalReadHostCommand = $existing.ScriptBlock
        }
    }

    $escaped = $Response.Replace("'", "''")
    $stub = [scriptblock]::Create("return '$escaped'")
    Set-Item -Path 'Function:\global:Read-Host' -Value $stub -Force -ErrorAction SilentlyContinue
}

function Restore-TestReadHostStub {
    if ($script:OriginalReadHostCommand) {
        Set-Item -Path 'Function:\global:Read-Host' -Value $script:OriginalReadHostCommand -Force -ErrorAction SilentlyContinue
    }
    else {
        $escaped = 'input'
        $throwStub = [scriptblock]::Create(@"
            param([Parameter(ValueFromRemainingArguments = `$true)][object[]]`$Remaining)
            `$prompt = if (`$Remaining.Count -gt 0) { [string]`$Remaining[0] } else { '$escaped' }
            throw "Read-Host is disabled during automated test execution. Prompt: '`$prompt'. Use Set-TestReadHostResponse in tests that require interactive behavior."
"@)
        Set-Item -Path 'Function:\global:Read-Host' -Value $throwStub -Force -ErrorAction SilentlyContinue
    }
}

function Register-TestGetModuleStub {
    [CmdletBinding()]
    param(
        [object]$ReturnValue
    )

    if (-not $script:OriginalGetModuleCommand) {
        $existing = Get-Command Get-Module -ErrorAction SilentlyContinue
        if ($existing -and $existing.CommandType -eq 'Function') {
            $script:OriginalGetModuleCommand = $existing.ScriptBlock
        }
    }

    $global:TestGetModuleStubValue = $ReturnValue
    $stub = {
        return $global:TestGetModuleStubValue
    }

    Set-Item -Path 'Function:\global:Get-Module' -Value $stub -Force -ErrorAction SilentlyContinue
}

function Restore-TestGetModuleStub {
    $global:TestGetModuleStubValue = $null

    if ($script:OriginalGetModuleCommand) {
        Set-Item -Path 'Function:\global:Get-Module' -Value $script:OriginalGetModuleCommand -Force -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item -Path 'Function:\global:Get-Module' -Force -ErrorAction SilentlyContinue
    }
}

function Register-TestProfileFunctionStub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Body
    )

    if (-not $script:TestProfileFunctionOriginals.ContainsKey($Name)) {
        $existing = Get-Command $Name -CommandType Function -ErrorAction SilentlyContinue
        if ($existing) {
            $script:TestProfileFunctionOriginals[$Name] = $existing.ScriptBlock
        }
    }

    Set-Item -Path "Function:\global:$Name" -Value $Body -Force -ErrorAction SilentlyContinue
}

function Restore-TestProfileFunctionStubs {
    foreach ($entry in $script:TestProfileFunctionOriginals.GetEnumerator()) {
        Set-Item -Path "Function:\global:$($entry.Key)" -Value $entry.Value -Force -ErrorAction SilentlyContinue
    }

    $script:TestProfileFunctionOriginals = @{}
}

function Restore-TestTerminalStubs {
    Restore-TestWriteHostCapture
    Restore-TestGetHistoryStub
    Restore-TestClearHistoryStub
    Restore-TestReadHostStub
    Restore-TestGetModuleStub
    Restore-TestProfileFunctionStubs
}
