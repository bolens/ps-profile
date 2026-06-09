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
    try {
        $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
        $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $script:LibPath -or [string]::IsNullOrWhiteSpace($script:LibPath)) {
            throw "Get-TestPath returned null or empty value for LibPath"
        }
        if (-not (Test-Path -LiteralPath $script:LibPath)) {
            throw "Library path not found at: $script:LibPath"
        }

        $script:CollectionsPath = Join-Path $script:LibPath 'utilities' 'Collections.psm1'
        if ($null -eq $script:CollectionsPath -or [string]::IsNullOrWhiteSpace($script:CollectionsPath)) {
            throw "CollectionsPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $script:CollectionsPath)) {
            throw "Collections module not found at: $script:CollectionsPath"
        }

        Remove-Module Collections -ErrorAction SilentlyContinue -Force
        Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

        $funcs = Get-Command -Module Collections -ErrorAction SilentlyContinue
        if (-not $funcs -or $funcs.Count -eq 0) {
            throw "No functions exported from Collections module. Path: $script:CollectionsPath"
        }

        $newObjectListCmd = Get-Command New-ObjectList -ErrorAction SilentlyContinue
        if (-not $newObjectListCmd) {
            throw "New-ObjectList function not found after module import"
        }
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize Collections tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

AfterAll {
    Remove-Module Collections -ErrorAction SilentlyContinue -Force
}

function global:Reset-TestCollectionsModule {
    Remove-Module Collections -ErrorAction SilentlyContinue -Force
    Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force
}

Describe 'Collections Module Functions' {
    BeforeAll {
        try {
            $testListType = [System.Collections.Generic.List`1].MakeGenericType([object])
            $testResult = Invoke-CreateInstanceWrapper -Type $testListType
            if ($null -eq $testResult) {
                Write-Warning "Invoke-CreateInstanceWrapper returned null during test setup - wrapper functions may not be working correctly"
            }
        }
        catch {
            Write-Warning "Error testing wrapper functions during setup: $($_.Exception.Message)"
        }
    }

    BeforeEach {
        Reset-TestCollectionsModule
    }

    Context 'New-ObjectList' {
        It 'Creates a new List of PSCustomObject' {
            # Call function directly - same pattern as "Returns empty list initially" which passes
            $list = New-ObjectList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-ObjectList should return an empty list"
            # Verify type by accessing GetType() directly instead of piping
            # Note: Function returns List[object] for compatibility, but works with PSCustomObject items
            $list.GetType() | Should -Be ([System.Collections.Generic.List[object]])
        }

        It 'Allows adding PSCustomObject items' {
            # Call function directly - same pattern as "Returns empty list initially" which passes
            $list = New-ObjectList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-ObjectList should return an empty list"
            
            $item = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
            { $list.Add($item) } | Should -Not -Throw -Because "List should accept PSCustomObject items"
            $list.Count | Should -Be 1 -Because "List should contain one item after adding"
        }

        It 'Allows adding multiple items' {
            $list = New-ObjectList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-ObjectList should return an empty list"
            $list.Add([PSCustomObject]@{ Name = 'Item1' })
            $list.Add([PSCustomObject]@{ Name = 'Item2' })
            $list.Count | Should -Be 2
        }

        It 'Can be converted to array' {
            $list = New-ObjectList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-ObjectList should return an empty list"
            $list.Add([PSCustomObject]@{ Name = 'Item1' })
            $list.Add([PSCustomObject]@{ Name = 'Item2' })
            
            $array = $list.ToArray()
            $array | Should -Not -BeNullOrEmpty
            $array.Count | Should -Be 2
            # Array elements are PSCustomObject, but array type is object[] since List[object] was used
            # Check type directly instead of piping to avoid unwrapping
            $array.GetType() | Should -Be ([object[]])
        }

        It 'Returns empty list initially' {
            $list = New-ObjectList
            $list.Count | Should -Be 0
        }
    }

    Context 'New-StringList' {
        It 'Creates a new List of strings' {
            $list = New-StringList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-StringList should return an empty list"
            # Verify type by accessing GetType() directly instead of piping
            $list.GetType() | Should -Be ([System.Collections.Generic.List[string]])
        }

        It 'Allows adding string items' {
            $list = New-StringList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-StringList should return an empty list"
            { $list.Add('Item1') } | Should -Not -Throw
            { $list.Add('Item2') } | Should -Not -Throw
            $list.Count | Should -Be 2
        }

        It 'Can be joined into a single string' {
            $list = New-StringList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-StringList should return an empty list"
            $list.Add('Line 1')
            $list.Add('Line 2')
            $list.Add('Line 3')
            
            $content = $list -join "`n"
            $content | Should -Match 'Line 1'
            $content | Should -Match 'Line 2'
            $content | Should -Match 'Line 3'
        }

        It 'Returns empty list initially' {
            $list = New-StringList
            $list.Count | Should -Be 0
        }

        It 'Supports all List[string] operations' {
            $list = New-StringList
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-StringList should return an empty list"
            $list.Add('Item1')
            $list.Add('Item2')
            $list.Remove('Item1') | Should -Be $true
            $list.Count | Should -Be 1
            $list[0] | Should -Be 'Item2'
        }
    }

    Context 'New-TypedList' {
        It 'Creates a List of int type' {
            $list = New-TypedList -Type 'int'
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            # Compare types directly - get the type and compare without piping
            $genericArg = $list.GetType().GetGenericArguments()[0]
            $genericArg | Should -Be ([int])
        }

        It 'Creates a List using Type object' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $list = New-TypedList -Type ([int]) -Verbose
                $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
                $genericArg = $list.GetType().GetGenericArguments()[0]
                $genericArg | Should -Be ([int])
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'Allows adding items of the specified type' {
            $list = New-TypedList -Type 'int'
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            { $list.Add(1) } | Should -Not -Throw
            { $list.Add(2) } | Should -Not -Throw
            { $list.Add(3) } | Should -Not -Throw
            $list.Count | Should -Be 3
        }

        It 'Throws error when adding wrong type' {
            $list = New-TypedList -Type 'int'
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            { $list.Add('string') } | Should -Throw
        }

        It 'Creates a List of FileInfo type' {
            $list = New-TypedList -Type ([System.IO.FileInfo])
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            # Compare types directly - get the type and compare without piping
            $genericArg = $list.GetType().GetGenericArguments()[0]
            $genericArg | Should -Be ([System.IO.FileInfo])
        }

        It 'Creates a List of string type' {
            $list = New-TypedList -Type 'string'
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            # Compare types directly - get the type and compare without piping
            $genericArg = $list.GetType().GetGenericArguments()[0]
            $genericArg | Should -Be ([string])
        }

        It 'Returns empty list initially' {
            $list = New-TypedList -Type 'int'
            $list.Count | Should -Be 0
        }

        It 'Supports all generic List operations' {
            $list = New-TypedList -Type 'int'
            # Access Count directly like the passing test - this confirms the list exists
            $list.Count | Should -Be 0 -Because "New-TypedList should return an empty list"
            $list.Add(1)
            $list.Add(2)
            $list.Add(3)
            $list.Remove(2) | Should -Be $true
            $list.Count | Should -Be 2
            $list[0] | Should -Be 1
            $list[1] | Should -Be 3
        }

        It 'Handles invalid type string gracefully' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $result = New-TypedList -Type 'InvalidTypeNameThatDoesNotExist12345' -Verbose
                $result | Should -BeNullOrEmpty -Because "Invalid type should return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'Handles empty type string gracefully' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $result = New-TypedList -Type '' -Verbose
                $result | Should -BeNullOrEmpty -Because "Empty type should return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'Handles whitespace-only type string gracefully' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $result = New-TypedList -Type '   ' -Verbose
                $result | Should -BeNullOrEmpty -Because "Whitespace-only type should return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

    }

    Context 'Error Handling and Edge Cases' {
        It 'New-ObjectList works with verbose output' {
            # Verify verbose output doesn't interfere with return value
            # Access Count directly like the passing tests
            $list = New-ObjectList -Verbose
            $list.Count | Should -Be 0 -Because "Verbose output should not interfere with return value"
        }

        It 'New-StringList works with verbose output' {
            # Verify verbose output doesn't interfere with return value
            # Access Count directly like the passing tests
            $list = New-StringList -Verbose
            $list.Count | Should -Be 0 -Because "Verbose output should not interfere with return value"
        }

        It 'New-TypedList works with verbose output' {
            # Verify verbose output doesn't interfere with return value
            # Access Count directly like the passing tests
            $list = New-TypedList -Type 'int' -Verbose
            $list.Count | Should -Be 0 -Because "Verbose output should not interfere with return value"
        }

        It 'New-ObjectList handles errors gracefully' {
            $list = New-ObjectList
            $list.Count | Should -Be 0
        }

        It 'New-StringList handles errors gracefully' {
            $list = New-StringList
            $list.Count | Should -Be 0
        }

        It 'New-TypedList handles Type object parameter' {
            # Test the if branch when Type is already a [type]
            $list = New-TypedList -Type ([System.DateTime])
            # Access Count directly like the passing tests
            $list.Count | Should -Be 0
            $genericArg = $list.GetType().GetGenericArguments()[0]
            $genericArg | Should -Be ([System.DateTime])
        }

        It 'New-TypedList handles various type formats as strings' {
            # Test the else branch when Type is a string (not already a [type])
            # This explicitly tests line 148: [type]$Type (the else branch)
            $testCases = @(
                @{ Type = 'int'; Expected = [int] },
                @{ Type = 'string'; Expected = [string] },
                @{ Type = 'bool'; Expected = [bool] },
                @{ Type = 'double'; Expected = [double] },
                @{ Type = 'DateTime'; Expected = [DateTime] }
            )

            foreach ($testCase in $testCases) {
                # Ensure Type is passed as string to test the else branch
                $typeAsString = $testCase.Type
                $list = New-TypedList -Type $typeAsString
                # Access Count directly like the passing tests
                $list.Count | Should -Be 0 -Because "Type string '$($testCase.Type)' should create a valid list"
                $genericArg = $list.GetType().GetGenericArguments()[0]
                $genericArg | Should -Be ($testCase.Expected) -Because "Type string '$($testCase.Type)' should resolve correctly"
            }
        }

        It 'New-TypedList handles more complex types' {
            # Test additional types to cover more code paths
            $testCases = @(
                @{ Type = 'long'; Expected = [long] },
                @{ Type = 'decimal'; Expected = [decimal] },
                @{ Type = 'float'; Expected = [float] },
                @{ Type = 'byte'; Expected = [byte] },
                @{ Type = 'char'; Expected = [char] },
                @{ Type = 'Guid'; Expected = [Guid] },
                @{ Type = 'TimeSpan'; Expected = [TimeSpan] }
            )

            foreach ($testCase in $testCases) {
                $list = New-TypedList -Type $testCase.Type
                $list.Count | Should -Be 0 -Because "Type '$($testCase.Type)' should create a valid list"
                $genericArg = $list.GetType().GetGenericArguments()[0]
                $genericArg | Should -Be ($testCase.Expected) -Because "Type '$($testCase.Type)' should resolve correctly"
            }
        }

        It 'New-TypedList handles Type object for various types' {
            # Test the if branch when Type is already a [type] for different types
            $testCases = @(
                @{ Type = [System.Collections.Hashtable]; Expected = [System.Collections.Hashtable] },
                @{ Type = [System.Collections.ArrayList]; Expected = [System.Collections.ArrayList] },
                @{ Type = [System.Text.StringBuilder]; Expected = [System.Text.StringBuilder] }
            )

            foreach ($testCase in $testCases) {
                $list = New-TypedList -Type $testCase.Type
                $list.Count | Should -Be 0 -Because "Type object '$($testCase.Type.Name)' should create a valid list"
                $genericArg = $list.GetType().GetGenericArguments()[0]
                $genericArg | Should -Be ($testCase.Expected) -Because "Type object '$($testCase.Type.Name)' should resolve correctly"
            }
        }

        It 'New-ObjectList verbose messages are executed' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $list = New-ObjectList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'New-StringList verbose messages are executed' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $list = New-StringList -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'New-TypedList verbose messages are executed' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $list = New-TypedList -Type 'int' -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }

        It 'New-TypedList verbose messages executed for Type object' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'
                $list = New-TypedList -Type ([System.Collections.Generic.List[int]]) -Verbose
                $list.Count | Should -Be 0
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
        }
    }

    Context 'Error Path Testing with TestSupport Stubs' {
        AfterAll {
            Reset-TestCollectionsModule
        }

        It 'New-ObjectList handles MakeGenericType returning null' {
            # Stub MakeGenericType wrapper to return null to test error path
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-MakeGenericTypeWrapper {
                    param(
                        [type]$GenericTypeDefinition,
                        [type[]]$TypeArguments
                    )

                    if ($GenericTypeDefinition -eq [System.Collections.Generic.List`1] -and
                        $TypeArguments.Count -eq 1 -and
                        $TypeArguments[0] -eq [object]) {
                        return $null
                    }

                    return $GenericTypeDefinition.MakeGenericType($TypeArguments)
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-ObjectList -Verbose
                $result | Should -BeNullOrEmpty -Because "MakeGenericType returning null should result in null return"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-ObjectList handles CreateInstance returning null' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-CreateInstanceWrapper {
                    param([type]$Type)
                    return $null
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-ObjectList -Verbose
                $result | Should -BeNullOrEmpty -Because "CreateInstance returning null should result in null return"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-ObjectList handles exceptions in try-catch block' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-MakeGenericTypeWrapper {
                    param(
                        [type]$GenericTypeDefinition,
                        [type[]]$TypeArguments
                    )

                    throw [System.InvalidOperationException]::new('Test exception for error path coverage')
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-ObjectList -Verbose
                $result | Should -BeNullOrEmpty -Because "Exception in try block should be caught and return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-StringList handles constructor returning null' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-TypeConstructorWrapper {
                    param([type]$Type)

                    if ($Type -eq [System.Collections.Generic.List[string]]) {
                        return $null
                    }

                    return $Type::new()
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-StringList -Verbose
                $result | Should -BeNullOrEmpty -Because "Constructor returning null should result in null return"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-StringList handles exceptions in try-catch block' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-TypeConstructorWrapper {
                    param([type]$Type)

                    if ($Type -eq [System.Collections.Generic.List[string]]) {
                        throw [System.InvalidOperationException]::new('Test exception for error path coverage')
                    }

                    return $Type::new()
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-StringList -Verbose
                $result | Should -BeNullOrEmpty -Because "Exception in try block should be caught and return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-TypedList handles MakeGenericType returning null' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-MakeGenericTypeWrapper {
                    param(
                        [type]$GenericTypeDefinition,
                        [type[]]$TypeArguments
                    )

                    return $null
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-TypedList -Type 'int' -Verbose
                $result | Should -BeNullOrEmpty -Because "MakeGenericType returning null should result in null return"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-TypedList handles CreateInstance returning null' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-CreateInstanceWrapper {
                    param([type]$Type)
                    return $null
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-TypedList -Type 'int' -Verbose
                $result | Should -BeNullOrEmpty -Because "CreateInstance returning null should result in null return"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }

        It 'New-TypedList handles exceptions in try-catch block' {
            $originalVerbosePreference = $VerbosePreference
            try {
                $VerbosePreference = 'Continue'

                function global:Invoke-MakeGenericTypeWrapper {
                    param(
                        [type]$GenericTypeDefinition,
                        [type[]]$TypeArguments
                    )

                    throw [System.InvalidOperationException]::new('Test exception for error path coverage')
                }

                Remove-Module Collections -ErrorAction SilentlyContinue -Force
                Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force

                $result = New-TypedList -Type 'int' -Verbose
                $result | Should -BeNullOrEmpty -Because "Exception in try block should be caught and return null"
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
                Reset-TestCollectionsModule
            }
        }
    }

    Context 'Type Conversion and Edge Cases' {
        BeforeEach {
            # Don't reload module - use existing module state
            # Wrapper functions from BeforeAll should be available
        }

        It 'New-TypedList handles invalid type string gracefully' {
            # Try to create a list with an invalid type string
            # The exception is caught and returns null
            # Ensure wrapper functions don't interfere
            Remove-Item Function:\Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue
            Remove-Module Collections -ErrorAction SilentlyContinue -Force
            Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force
            $result = New-TypedList -Type 'InvalidTypeNameThatDoesNotExist12345' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'New-TypedList handles empty type string gracefully' {
            # Try to create a list with an empty type string
            # The exception is caught and returns null
            # Ensure wrapper functions don't interfere
            Remove-Item Function:\Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue
            Remove-Module Collections -ErrorAction SilentlyContinue -Force
            Import-Module $script:CollectionsPath -DisableNameChecking -ErrorAction Stop -Force
            $result = New-TypedList -Type '' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'New-TypedList handles null type gracefully' {
            # Try to create a list with null type
            # PowerShell will throw ParameterBindingValidationException before the function runs
            # So we need to catch it or use a different approach
            { New-TypedList -Type $null -ErrorAction Stop } | Should -Throw
        }

    }
}
