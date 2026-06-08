<#
tests/unit/library-collections-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Collections list independence and typed usage.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'Collections.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Collections -ErrorAction SilentlyContinue -Force
}

Describe 'Collections extended scenarios' {
    Context 'List factory independence' {
        It 'Returns distinct object lists on each call' {
            $first = New-ObjectList
            $second = New-ObjectList

            $first.Add([PSCustomObject]@{ Name = 'OnlyFirst' })
            $first.Count | Should -Be 1
            $second.Count | Should -Be 0
        }

        It 'Returns distinct string lists on each call' {
            $first = New-StringList
            $second = New-StringList

            $first.Add('alpha')
            $first.Count | Should -Be 1
            $second.Count | Should -Be 0
        }
    }

    Context 'Typed list operations' {
        It 'Stores boolean values in a bool typed list' {
            $list = New-TypedList -Type 'bool'
            $list.Add($true)
            $list.Add($false)

            $list.Count | Should -Be 2
            $list[0] | Should -Be $true
            $list[1] | Should -Be $false
        }

        It 'Clears string lists while preserving list type' {
            $list = New-StringList
            $list.Add('keep-me')
            $list.Clear()

            $list.Count | Should -Be 0
            $list.GetType() | Should -Be ([System.Collections.Generic.List[string]])
        }

        It 'Converts an empty object list to a zero-length array' {
            $array = (New-ObjectList).ToArray()

            @($array).Count | Should -Be 0
            $array.GetType() | Should -Be ([object[]])
        }
    }
}
