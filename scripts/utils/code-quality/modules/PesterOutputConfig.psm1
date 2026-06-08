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
.PARAMETER Config
    Pester configuration object to update.

.PARAMETER OutputFormat
    Named verbosity level such as Normal, Detailed, Minimal, or None.

.PARAMETER CI
    Uses CI-friendly normal verbosity when no explicit switches are set.

.PARAMETER Quiet
    Suppresses Pester output entirely.

.PARAMETER Verbose
    Enables detailed Pester output.

.EXAMPLE
    Set-PesterOutputVerbosity -Config $config -Quiet

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

.DESCRIPTION
    Enables NUnit test result output and Cobertura coverage formatting for CI runs.

.PARAMETER Config
    Pester configuration object to update.

.PARAMETER OutputPath
    Optional explicit test result output path.

.PARAMETER Coverage
    Switches coverage output to Cobertura when enabled.

.PARAMETER RepoRoot
    Repository root used for default test result output paths.

.EXAMPLE
    Set-PesterCIOptimizations -Config $config -RepoRoot $repoRoot -Coverage
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

.DESCRIPTION
    Enables NUnit XML test result output and resolves the destination file path.

.PARAMETER Config
    Pester configuration object to update.

.PARAMETER OutputPath
    Base output directory for generated test result files.

.PARAMETER TestResultPath
    Explicit test result file path override.

.EXAMPLE
    Set-PesterTestResults -Config $config -OutputPath ./reports
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

