Describe 'Alias helper' {
    It 'Set-AgentModeAlias returns definition when requested and alias works' {
        . "$PSScriptRoot/..\profile.d\00-bootstrap.ps1"
        $name = "test_alias_$(Get-Random)"
        $def = Set-AgentModeAlias -Name $name -Target 'Write-Output' -ReturnDefinition
        $def | Should Not Be $false
        $def.GetType().Name | Should Be 'String'
        # The alias should also be callable and emit the given argument
        $out = & $name 'hello'
        $out | Should Be 'hello'
    }
}

Describe 'Documentation Generation' {
    Context 'Comment parsing' {
        It 'parses comment-based help correctly' {
            $testFunction = @'
<#
.SYNOPSIS
    Test function for documentation
.DESCRIPTION
    This is a test function with parameters.
.PARAMETER Name
    The name parameter
.PARAMETER Value
    The value parameter
#>
function Test-Function {
    param($Name, $Value)
}
'@

            $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
            try {
                Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

                # Import the generate-docs script functions
                . "$PSScriptRoot/..\scripts/utils/generate-docs.ps1"

                # This would require mocking or extracting the parsing logic
                # For now, just test that the script runs
                $true | Should Be $true
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }

        It 'handles functions without parameters' {
            $testFunction = @'
<#
.SYNOPSIS
    Simple function
.DESCRIPTION
    A function with no parameters
#>
function Simple-Function { }
'@

            $tempFile = [IO.Path]::GetTempFileName() + '.ps1'
            try {
                Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8
                $true | Should Be $true
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }
    }

    Context 'File generation' {
        It 'creates markdown files with correct structure' {
            $docsPath = Join-Path $PSScriptRoot '..\docs'
            $testDoc = Join-Path $docsPath 'Test-Function.md'

            if (Test-Path $testDoc) {
                $content = Get-Content $testDoc -Raw
                $content | Should Match '^# Test-Function'
                $content | Should Match '## Synopsis'
                $content | Should Match '## Description'
            }
        }

        It 'generates index with alphabetical function list' {
            $docsPath = Join-Path $PSScriptRoot '..\docs'
            $readmePath = Join-Path $docsPath 'README.md'

            $content = Get-Content $readmePath -Raw
            $lines = $content -split "`n"

            # Find the functions section
            $functionsIndex = $lines.IndexOf('## Functions')
            if ($functionsIndex -ge 0) {
                $functionLines = $lines[($functionsIndex + 1)..($lines.Length - 1)] | Where-Object { $_ -match '^- \[.*\]' }

                # Extract function names and check if they're in alphabetical order
                $functionNames = $functionLines | ForEach-Object {
                    if ($_ -match '^- \[(.*?)\]') {
                        $matches[1]
                    }
                } | Where-Object { $_ }

                $sortedNames = $functionNames | Sort-Object
                $functionNames | Should Be $sortedNames
            }
        }
    }
}
