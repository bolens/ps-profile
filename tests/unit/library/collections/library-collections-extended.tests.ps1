<#
tests/unit/library-collections-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Collections list independence and typed usage.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:CollectionsPath = Join-Path $script:LibPath 'utilities' 'Collections.psm1'
    Import-TestLibraryModule -ModulePath $script:CollectionsPath
}

AfterAll {
    Remove-Module Collections -ErrorAction SilentlyContinue -Force
}

function global:Reset-CollectionsTestModule {
    Import-TestLibraryModule -ModulePath $script:CollectionsPath -RemoveExisting
}

Describe 'Collections extended scenarios' {
    BeforeEach {
        Clear-CollectionsWrapperStubs
    }
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

    Context 'Debug and structured output hooks' {
        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $VerbosePreference = 'Continue'
                $list = New-ObjectList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                $VerbosePreference = $originalVerbose
            }
        }

        It 'Uses plain warnings when structured logging is disabled for invalid typed lists' {
            $originalFlag = $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = 'true'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = New-TypedList -Type 'NotARealTypeName12345'
                $result | Should -BeNullOrEmpty
                $emptyResult = New-TypedList -Type '   '
                $emptyResult | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses plain warnings when structured logging is disabled for null factory results' {
            $originalFlag = $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_DEBUG = '1'

            function global:Invoke-MakeGenericTypeWrapper { return $null }
            function global:Invoke-TypeConstructorWrapper { return $null }

            try {
                Reset-CollectionsTestModule
                (New-ObjectList) | Should -BeNullOrEmpty
                (New-StringList) | Should -BeNullOrEmpty
                (New-TypedList -Type 'int') | Should -BeNullOrEmpty
            }
            finally {
                Clear-CollectionsWrapperStubs
                Reset-CollectionsTestModule

                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits structured warnings for invalid typed lists when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $result = New-TypedList -Type 'NotARealTypeName12345'
            $result | Should -BeNullOrEmpty
        }

        It 'Emits structured errors for object list exceptions when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            function global:Invoke-MakeGenericTypeWrapper {
                throw [System.InvalidOperationException]::new('forced object list failure')
            }

            try {
                Reset-CollectionsTestModule
                $result = New-ObjectList
                $result | Should -BeNullOrEmpty
            }
            finally {
                Clear-CollectionsWrapperStubs
                Reset-CollectionsTestModule
            }
        }

        It 'Uses plain errors when structured logging is disabled for object list exceptions' {
            $originalFlag = $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                function global:Invoke-MakeGenericTypeWrapper {
                    throw [System.InvalidOperationException]::new('forced object list failure')
                }

                Reset-CollectionsTestModule
                $result = New-ObjectList
                $result | Should -BeNullOrEmpty
            }
            finally {
                Clear-CollectionsWrapperStubs
                Reset-CollectionsTestModule

                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Structured warning paths with bootstrap' {
        AfterEach {
            Clear-CollectionsWrapperStubs
            Reset-CollectionsTestModule
        }

        BeforeAll {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }
        }

        It 'Emits structured warnings when object list MakeGenericType returns null' {
            function global:Invoke-MakeGenericTypeWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $result = New-ObjectList
            $result | Should -BeNullOrEmpty
        }

        It 'Emits structured warnings when object list CreateInstance returns null' {
            function global:Invoke-CreateInstanceWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $result = New-ObjectList
            $result | Should -BeNullOrEmpty
        }

        It 'Emits structured warnings when string list constructor returns null' {
            function global:Invoke-TypeConstructorWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $result = New-StringList
            $result | Should -BeNullOrEmpty
        }

        It 'Emits structured warnings when typed list MakeGenericType returns null' {
            function global:Invoke-MakeGenericTypeWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $result = New-TypedList -Type 'int'
            $result | Should -BeNullOrEmpty
        }

        It 'Emits structured warnings when typed list CreateInstance returns null' {
            function global:Invoke-CreateInstanceWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $result = New-TypedList -Type 'int'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Forced error and null probe hooks' {
        AfterEach {
            @(
                'PS_PROFILE_COLLECTIONS_FORCE_OBJECT_LIST_ERROR',
                'PS_PROFILE_COLLECTIONS_FORCE_MAKE_GENERIC_NULL',
                'PS_PROFILE_COLLECTIONS_FORCE_CREATE_INSTANCE_NULL',
                'PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_ERROR',
                'PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_NULL',
                'PS_PROFILE_COLLECTIONS_FORCE_TYPED_LIST_ERROR',
                'PS_PROFILE_COLLECTIONS_FORCE_TYPE_OBJ_NULL',
                'PS_PROFILE_COLLECTIONS_FORCE_TYPED_MAKE_GENERIC_NULL',
                'PS_PROFILE_COLLECTIONS_FORCE_TYPED_CREATE_INSTANCE_NULL',
                'PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING',
                'PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR',
                'PS_PROFILE_DEBUG'
            ) | ForEach-Object { Remove-Item "Env:$_" -ErrorAction SilentlyContinue }
            Reset-CollectionsTestModule
        }

        It 'Covers object list forced null and error paths with plain logging' {
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            $env:PS_PROFILE_COLLECTIONS_FORCE_MAKE_GENERIC_NULL = '1'
            (New-ObjectList) | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_MAKE_GENERIC_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_CREATE_INSTANCE_NULL = '1'
            (New-ObjectList) | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_CREATE_INSTANCE_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_OBJECT_LIST_ERROR = '1'
            (New-ObjectList) | Should -BeNullOrEmpty
        }

        It 'Covers string list forced null and error paths with plain logging' {
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            $env:PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_NULL = '1'
            (New-StringList) | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_ERROR = '1'
            (New-StringList) | Should -BeNullOrEmpty
        }

        It 'Covers typed list forced null and error paths with plain logging' {
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            $env:PS_PROFILE_COLLECTIONS_FORCE_TYPE_OBJ_NULL = '1'
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_TYPE_OBJ_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_MAKE_GENERIC_NULL = '1'
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_MAKE_GENERIC_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_CREATE_INSTANCE_NULL = '1'
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty

            Remove-Item Env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_CREATE_INSTANCE_NULL -ErrorAction SilentlyContinue
            $env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_LIST_ERROR = '1'
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty
        }

        It 'Covers forced error paths with structured logging when available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $env:PS_PROFILE_COLLECTIONS_FORCE_OBJECT_LIST_ERROR = '1'
            (New-ObjectList) | Should -BeNullOrEmpty

            $env:PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_ERROR = '1'
            (New-StringList) | Should -BeNullOrEmpty

            $env:PS_PROFILE_COLLECTIONS_FORCE_TYPED_LIST_ERROR = '1'
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty
        }
    }

    Context 'Debug level 2 verbose paths' {
        It 'Emits level 2 verbose output for all list factories' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $VerbosePreference = 'Continue'
                (New-ObjectList -Verbose).Count | Should -Be 0
                (New-StringList -Verbose).Count | Should -Be 0
                (New-TypedList -Type 'int' -Verbose).Count | Should -Be 0
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                $VerbosePreference = $originalVerbose
            }
        }
    }

    Context 'String and typed list exception paths' {
        AfterEach {
            Clear-CollectionsWrapperStubs
            Reset-CollectionsTestModule
        }

        It 'Emits structured errors for string and typed list exceptions when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            function global:Invoke-TypeConstructorWrapper {
                throw [System.InvalidOperationException]::new('forced string list failure')
            }

            Reset-CollectionsTestModule
            (New-StringList) | Should -BeNullOrEmpty

            Remove-TestFunction -Name 'Invoke-TypeConstructorWrapper'
            function global:Invoke-MakeGenericTypeWrapper {
                throw [System.InvalidOperationException]::new('forced typed list failure')
            }

            Reset-CollectionsTestModule
            (New-TypedList -Type 'int') | Should -BeNullOrEmpty
        }

        It 'Uses plain errors when structured logging is disabled for string list exceptions' {
            $originalFlag = $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            function global:Invoke-TypeConstructorWrapper {
                throw [System.InvalidOperationException]::new('forced string list failure')
            }

            try {
                Reset-CollectionsTestModule
                (New-StringList) | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Wrapper fallback paths' {
        AfterEach {
            Clear-CollectionsWrapperStubs
            Reset-CollectionsTestModule
        }

        It 'Falls back when MakeGenericType wrapper throws for object lists' {
            function global:Invoke-MakeGenericTypeWrapper {
                throw [System.InvalidOperationException]::new('wrapper failure')
            }

            Reset-CollectionsTestModule
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $list = New-ObjectList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back when CreateInstance wrapper throws for typed lists' {
            function global:Invoke-CreateInstanceWrapper {
                throw [System.InvalidOperationException]::new('create failure')
            }

            Reset-CollectionsTestModule
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $list = New-TypedList -Type 'int' -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back when string list constructor wrapper throws' {
            function global:Invoke-TypeConstructorWrapper {
                throw [System.InvalidOperationException]::new('constructor failure')
            }

            Reset-CollectionsTestModule
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $list = New-StringList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }

        It 'Emits structured errors for string and typed list exceptions when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            function global:Invoke-TypeConstructorWrapper {
                throw [System.InvalidOperationException]::new('forced string list failure')
            }

            try {
                Reset-CollectionsTestModule
                (New-StringList) | Should -BeNullOrEmpty

                Remove-TestFunction -Name 'Invoke-TypeConstructorWrapper'
                function global:Invoke-MakeGenericTypeWrapper {
                    throw [System.InvalidOperationException]::new('forced typed list failure')
                }

                Reset-CollectionsTestModule
                (New-TypedList -Type 'int') | Should -BeNullOrEmpty
            }
            finally {
                Clear-CollectionsWrapperStubs
                Reset-CollectionsTestModule
            }
        }

        It 'Uses plain errors when structured logging is disabled for string list exceptions' {
            $originalFlag = $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            function global:Invoke-TypeConstructorWrapper {
                throw [System.InvalidOperationException]::new('forced string list failure')
            }

            try {
                Reset-CollectionsTestModule
                (New-StringList) | Should -BeNullOrEmpty
            }
            finally {
                Clear-CollectionsWrapperStubs
                Reset-CollectionsTestModule

                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Falls back when CreateInstance wrapper returns null for object lists' {
            function global:Invoke-CreateInstanceWrapper {
                return $null
            }

            Reset-CollectionsTestModule
            $env:PS_PROFILE_DEBUG = '3'
            try {
                $list = New-ObjectList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
        }
    }
}
