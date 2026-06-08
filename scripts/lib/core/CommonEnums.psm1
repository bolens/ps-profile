<#
scripts/lib/core/CommonEnums.psm1

.SYNOPSIS
    Common enum definitions shared across scripts/lib modules.

.DESCRIPTION
    Defines enumerations required by Validation, FileSystem, Module management,
    test runner, and related modules. Must be imported before any module that
    uses these enum types in function signatures.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 3.0+
    Load Order: import this module before modules that reference these enums.
.PARAMETER Name
    Name parameter.
.PARAMETER Definition
    Definition parameter.
.EXAMPLE
    Add-CommonEnumType

#>

function Add-CommonEnumType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Definition
    )

    if (-not ([System.Management.Automation.PSTypeName]$Name).Type) {
        Add-Type -TypeDefinition $Definition
    }
}

Add-CommonEnumType -Name 'FileSystemPathType' -Definition @'
public enum FileSystemPathType {
    Any       = 0,
    File      = 1,
    Directory = 2
}
'@

Add-CommonEnumType -Name 'LogLevel' -Definition @'
public enum LogLevel {
    Debug   = 0,
    Info    = 1,
    Warning = 2,
    Error   = 3
}
'@

Add-CommonEnumType -Name 'ExitCode' -Definition @'
public enum ExitCode {
    Success           = 0,
    ValidationFailure = 1,
    SetupError        = 2,
    OtherError        = 3,
    TestFailure       = 4,
    TestTimeout       = 5,
    CoverageFailure   = 6,
    NoTestsFound      = 7,
    WatchModeCanceled = 8
}
'@

Add-CommonEnumType -Name 'ModuleScope' -Definition @'
public enum ModuleScope {
    CurrentUser = 0,
    AllUsers    = 1
}
'@

Add-CommonEnumType -Name 'PesterVerbosity' -Definition @'
public enum PesterVerbosity {
    None     = 0,
    Minimal  = 1,
    Normal   = 2,
    Detailed = 3
}
'@

Add-CommonEnumType -Name 'CodeCoverageOutputFormat' -Definition @'
public enum CodeCoverageOutputFormat {
    JaCoCo          = 0,
    CoverageGutters = 1,
    Cobertura       = 2
}
'@

Add-CommonEnumType -Name 'UpdateFrequency' -Definition @'
public enum UpdateFrequency {
    Daily   = 0,
    Weekly  = 1,
    Monthly = 2
}
'@

Add-CommonEnumType -Name 'TestSuite' -Definition @'
public enum TestSuite {
    All         = 0,
    Unit        = 1,
    Integration = 2,
    Performance = 3
}
'@

Add-CommonEnumType -Name 'TestPhase' -Definition @'
public enum TestPhase {
    All    = 0,
    Phase1 = 1,
    Phase2 = 2,
    Phase3 = 3,
    Phase4 = 4,
    Phase5 = 5,
    Phase6 = 6
}
'@

Add-CommonEnumType -Name 'OutputFormat' -Definition @'
public enum OutputFormat {
    Table = 0,
    Json  = 1,
    Csv   = 2
}
'@

Add-CommonEnumType -Name 'ReportFormat' -Definition @'
public enum ReportFormat {
    Summary   = 0,
    Detailed  = 1,
    Executive = 2,
    Technical = 3
}
'@

Add-CommonEnumType -Name 'VerbosityLevel' -Definition @'
public enum VerbosityLevel {
    None     = 0,
    Minimal  = 1,
    Normal   = 2,
    Detailed = 3
}
'@

Add-CommonEnumType -Name 'PathType' -Definition @'
public enum PathType {
    Container = 0,
    Leaf      = 1,
    Any       = 2
}
'@

Add-CommonEnumType -Name 'FragmentTier' -Definition @'
public enum FragmentTier {
    core       = 0,
    essential  = 1,
    standard   = 2,
    optional   = 3
}
'@

Add-CommonEnumType -Name 'TestReportFormat' -Definition @'
public enum TestReportFormat {
    JSON     = 0,
    HTML     = 1,
    Markdown = 2
}
'@

Add-CommonEnumType -Name 'DatabaseAction' -Definition @'
public enum DatabaseAction {
    health     = 0,
    optimize   = 1,
    backup     = 2,
    repair     = 3,
    statistics = 4
}
'@

Add-CommonEnumType -Name 'DatabaseStatus' -Definition @'
public enum DatabaseStatus {
    Missing   = 0,
    Corrupted = 1,
    Healthy   = 2
}
'@

Add-CommonEnumType -Name 'SeverityLevel' -Definition @'
public enum SeverityLevel {
    Error         = 0,
    Warning       = 1,
    Information   = 2
}
'@

Add-CommonEnumType -Name 'FragmentCacheType' -Definition @'
public enum FragmentCacheType {
    content = 0,
    ast     = 1,
    all     = 2
}
'@

Export-ModuleMember -Function 'Add-CommonEnumType'
