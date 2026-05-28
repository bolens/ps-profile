<#
scripts/lib/core/CommonEnums.psm1

.SYNOPSIS
    Common enum definitions shared across scripts/lib modules.

.DESCRIPTION
    Defines enumerations required by Validation, FileSystem, and related modules.
    Must be imported before any module that uses [FileSystemPathType] in function
    signatures (Validation.psm1, FileSystem.psm1).

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
    Load Order: import this module before Validation or FileSystem.
#>

if (-not ([System.Management.Automation.PSTypeName]'FileSystemPathType').Type) {
    Add-Type -TypeDefinition @'
public enum FileSystemPathType {
    Any       = 0,
    File      = 1,
    Directory = 2
}
'@
}

if (-not ([System.Management.Automation.PSTypeName]'LogLevel').Type) {
    Add-Type -TypeDefinition @'
public enum LogLevel {
    Debug   = 0,
    Info    = 1,
    Warning = 2,
    Error   = 3
}
'@
}

if (-not ([System.Management.Automation.PSTypeName]'ExitCode').Type) {
    Add-Type -TypeDefinition @'
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
}

Export-ModuleMember
