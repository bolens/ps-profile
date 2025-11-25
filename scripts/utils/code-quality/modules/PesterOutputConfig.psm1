<#
scripts/utils/code-quality/modules/PesterOutputConfig.psm1

.SYNOPSIS
    Pester output configuration utilities.

.DESCRIPTION
    Provides functions for configuring Pester output verbosity, CI optimizations, and test results.
#>

<#
.SYNOPSIS
    Configures Pester output verbosity.

.DESCRIPTION
    Sets the appropriate output verbosity based on the provided parameters,
    with priority given to Quiet/Verbose switches over OutputFormat.
#>
function Set-PesterOutputVerbosity {
    param(
        [PesterConfiguration]$Config,
        [string]$OutputFormat,
        [switch]$CI,
        [switch]$Quiet,
        [switch]$Verbose
    )

    if ($Quiet) {
        $Config.Output.Verbosity = 'None'
    }
    elseif ($Verbose) {
        $Config.Output.Verbosity = 'Detailed'
    }
    elseif ($CI) {
        $Config.Output.Verbosity = 'Normal'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($OutputFormat)) {
        switch ($OutputFormat) {
            'Normal' { $Config.Output.Verbosity = 'Normal' }
            'Detailed' { $Config.Output.Verbosity = 'Detailed' }
            'Minimal' { $Config.Output.Verbosity = 'None' }  # Pester 5.7.1 doesn't have 'Minimal', use 'None'
            'None' { $Config.Output.Verbosity = 'None' }
            default { $Config.Output.Verbosity = $OutputFormat }
        }
    }

    return $Config
}

<#
.SYNOPSIS
    Applies CI-specific optimizations to Pester configuration.
#>
function Set-PesterCIOptimizations {
    param(
        [PesterConfiguration]$Config,
        [string]$OutputPath,
        [switch]$Coverage,
        [string]$RepoRoot
    )

    $Config.Output.Verbosity = 'Normal'
    $Config.TestResult.Enabled = $true

    if (-not $OutputPath -and $RepoRoot) {
        $Config.TestResult.OutputPath = Join-Path $RepoRoot 'test-results.xml'
        $Config.TestResult.OutputFormat = 'NUnitXml'
    }

    if ($Coverage) {
        $Config.CodeCoverage.OutputFormat = 'Cobertura'
    }

    return $Config
}

<#
.SYNOPSIS
    Configures test result output for Pester.
#>
function Set-PesterTestResults {
    param(
        [PesterConfiguration]$Config,
        [string]$OutputPath,
        [string]$TestResultPath
    )

    if ($OutputPath) {
        $Config.TestResult.Enabled = $true
        $Config.TestResult.OutputPath = $OutputPath

        # Determine output format based on file extension
        $extension = [System.IO.Path]::GetExtension($OutputPath).ToLower()
        switch ($extension) {
            '.xml' { $Config.TestResult.OutputFormat = 'NUnitXml' }
            '.json' { $Config.TestResult.OutputFormat = 'Json' }
            '.nunit' { $Config.TestResult.OutputFormat = 'NUnitXml' }
            default { $Config.TestResult.OutputFormat = 'NUnitXml' }
        }
    }

    if ($TestResultPath) {
        $Config.TestResult.Enabled = $true
        $testResultFileName = if ($OutputPath) {
            [System.IO.Path]::GetFileName($OutputPath)
        }
        else {
            'test-results.xml'
        }
        $Config.TestResult.OutputPath = Join-Path $TestResultPath $testResultFileName
        if (-not $OutputPath) {
            $Config.TestResult.OutputFormat = 'NUnitXml'
        }
    }

    return $Config
}

Export-ModuleMember -Function @(
    'Set-PesterOutputVerbosity',
    'Set-PesterCIOptimizations',
    'Set-PesterTestResults'
)

