<#
scripts/utils/code-quality/modules/TestCategorization.psm1

.SYNOPSIS
    Test categorization utilities.

.DESCRIPTION
    Provides functions for determining test categories based on test properties.
#>

<#
.SYNOPSIS
    Determines the category of a test based on its properties.

.DESCRIPTION
    Analyzes test name, file path, and tags to determine
    the appropriate category for the test.

.PARAMETER Test
    The test object to categorize.

.OUTPUTS
    Test category string
#>
function Get-TestCategory {
    param(
        [Parameter(Mandatory)]
        $Test
    )

    # Check tags first
    if ($Test.Tags -and $Test.Tags -contains 'Integration') {
        return 'Integration'
    }
    if ($Test.Tags -and $Test.Tags -contains 'Unit') {
        return 'Unit'
    }
    if ($Test.Tags -and $Test.Tags -contains 'Performance') {
        return 'Performance'
    }

    # Check file path
    $fileName = Split-Path $Test.File -Leaf
    if ($fileName -like '*integration*') {
        return 'Integration'
    }
    if ($fileName -like '*performance*') {
        return 'Performance'
    }
    if ($fileName -like '*unit*') {
        return 'Unit'
    }

    # Check test name
    if ($Test.Name -like '*integration*' -or $Test.Name -like '*Integration*') {
        return 'Integration'
    }
    if ($Test.Name -like '*performance*' -or $Test.Name -like '*Performance*') {
        return 'Performance'
    }

    return 'Unit' # Default category
}

Export-ModuleMember -Function Get-TestCategory

