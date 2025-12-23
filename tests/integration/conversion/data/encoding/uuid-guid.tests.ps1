

<#
.SYNOPSIS
    Integration tests for UUID and GUID format conversion utilities.

.DESCRIPTION
    This test suite validates UUID and GUID conversion functions including:
    - UUID ↔ Hex conversions
    - UUID ↔ Base64 conversions
    - UUID ↔ Base32 conversions
    - GUID ↔ Hex conversions
    - GUID ↔ Base64 conversions
    - GUID ↔ Registry Format conversions
    - GUID ↔ UUID conversions
    - UUID/GUID generation
    - Roundtrip conversions

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    UUID and GUID are essentially the same format, with GUID having Windows registry format support.
#>

Describe 'UUID and GUID Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'UUID Conversions' {
        $testUuid = '550e8400-e29b-41d4-a716-446655440000'
        $testUuidHex = '550E8400E29B41D4A716446655440000'

        It 'ConvertFrom-UuidToHex converts UUID to hex' {
            Get-Command ConvertFrom-UuidToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testUuid | ConvertFrom-UuidToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testUuidHex
        }

        It 'ConvertTo-UuidFromHex converts hex to UUID' {
            Get-Command ConvertTo-UuidFromHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testUuidHex | ConvertTo-UuidFromHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testUuid
        }

        It 'UUID to hex and back roundtrip' {
            $original = $testUuid
            $hex = $original | ConvertFrom-UuidToHex
            $roundtrip = $hex | ConvertTo-UuidFromHex
            $roundtrip | Should -Be $original
        }

        It 'ConvertFrom-UuidToBase64 converts UUID to Base64' {
            Get-Command ConvertFrom-UuidToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testUuid | ConvertFrom-UuidToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'ConvertTo-UuidFromBase64 converts Base64 to UUID' {
            Get-Command ConvertTo-UuidFromBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $base64 = $testUuid | ConvertFrom-UuidToBase64
            $result = $base64 | ConvertTo-UuidFromBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testUuid
        }

        It 'UUID to Base64 and back roundtrip' {
            $original = $testUuid
            $base64 = $original | ConvertFrom-UuidToBase64
            $roundtrip = $base64 | ConvertTo-UuidFromBase64
            $roundtrip | Should -Be $original
        }

        It 'ConvertFrom-UuidToBase32 converts UUID to Base32' {
            Get-Command ConvertFrom-UuidToBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if Base32 conversion not available
            if (-not (Get-Command _ConvertFrom-HexToBase32 -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Base32 conversion not available"
                return
            }
            
            $result = $testUuid | ConvertFrom-UuidToBase32
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Z2-7]+$'
        }

        It 'ConvertTo-UuidFromBase32 converts Base32 to UUID' {
            Get-Command ConvertTo-UuidFromBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if Base32 conversion not available
            if (-not (Get-Command _ConvertFrom-Base32ToHex -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "Base32 conversion not available"
                return
            }
            
            $base32 = $testUuid | ConvertFrom-UuidToBase32
            $result = $base32 | ConvertTo-UuidFromBase32
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testUuid
        }

        It 'New-Uuid generates a new UUID' {
            Get-Command New-Uuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = New-Uuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
        }

        It 'New-Uuid -AsHex generates UUID in hex format' {
            $result = New-Uuid -AsHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[0-9A-Fa-f]{32}$'
        }

        It 'New-Uuid -AsBase64 generates UUID in Base64 format' {
            $result = New-Uuid -AsBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'New-Uuid generates unique UUIDs' {
            $uuid1 = New-Uuid
            $uuid2 = New-Uuid
            $uuid1 | Should -Not -Be $uuid2
        }
    }

    Context 'GUID Conversions' {
        $testGuid = '550e8400-e29b-41d4-a716-446655440000'
        $testGuidHex = '550E8400E29B41D4A716446655440000'
        $testGuidRegistry = '{550e8400-e29b-41d4-a716-446655440000}'

        It 'ConvertFrom-GuidToHex converts GUID to hex' {
            Get-Command ConvertFrom-GuidToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuid | ConvertFrom-GuidToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidHex
        }

        It 'ConvertFrom-GuidToHex handles registry format' {
            $result = $testGuidRegistry | ConvertFrom-GuidToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidHex
        }

        It 'ConvertTo-GuidFromHex converts hex to GUID' {
            Get-Command ConvertTo-GuidFromHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuidHex | ConvertTo-GuidFromHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'ConvertTo-GuidFromHex -RegistryFormat returns registry format' {
            $result = $testGuidHex | ConvertTo-GuidFromHex -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidRegistry
        }

        It 'GUID to hex and back roundtrip' {
            $original = $testGuid
            $hex = $original | ConvertFrom-GuidToHex
            $roundtrip = $hex | ConvertTo-GuidFromHex
            $roundtrip | Should -Be $original
        }

        It 'ConvertFrom-GuidToRegistryFormat converts GUID to registry format' {
            Get-Command ConvertFrom-GuidToRegistryFormat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuid | ConvertFrom-GuidToRegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidRegistry
        }

        It 'ConvertTo-GuidFromRegistryFormat converts registry format to GUID' {
            Get-Command ConvertTo-GuidFromRegistryFormat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuidRegistry | ConvertTo-GuidFromRegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'GUID to registry format and back roundtrip' {
            $original = $testGuid
            $registry = $original | ConvertFrom-GuidToRegistryFormat
            $roundtrip = $registry | ConvertTo-GuidFromRegistryFormat
            $roundtrip | Should -Be $original
        }

        It 'ConvertFrom-GuidToBase64 converts GUID to Base64' {
            Get-Command ConvertFrom-GuidToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuid | ConvertFrom-GuidToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'ConvertTo-GuidFromBase64 converts Base64 to GUID' {
            Get-Command ConvertTo-GuidFromBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $base64 = $testGuid | ConvertFrom-GuidToBase64
            $result = $base64 | ConvertTo-GuidFromBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'ConvertTo-GuidFromBase64 -RegistryFormat returns registry format' {
            $base64 = $testGuid | ConvertFrom-GuidToBase64
            $result = $base64 | ConvertTo-GuidFromBase64 -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidRegistry
        }

        It 'GUID to Base64 and back roundtrip' {
            $original = $testGuid
            $base64 = $original | ConvertFrom-GuidToBase64
            $roundtrip = $base64 | ConvertTo-GuidFromBase64
            $roundtrip | Should -Be $original
        }

        It 'ConvertFrom-GuidToUuid converts GUID to UUID' {
            Get-Command ConvertFrom-GuidToUuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuid | ConvertFrom-GuidToUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'ConvertFrom-GuidToUuid handles registry format' {
            $result = $testGuidRegistry | ConvertFrom-GuidToUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'ConvertTo-GuidFromUuid converts UUID to GUID' {
            Get-Command ConvertTo-GuidFromUuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = $testGuid | ConvertTo-GuidFromUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuid
        }

        It 'ConvertTo-GuidFromUuid -RegistryFormat returns registry format' {
            $result = $testGuid | ConvertTo-GuidFromUuid -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $testGuidRegistry
        }

        It 'GUID to UUID and back roundtrip' {
            $original = $testGuid
            $uuid = $original | ConvertFrom-GuidToUuid
            $roundtrip = $uuid | ConvertTo-GuidFromUuid
            $roundtrip | Should -Be $original
        }

        It 'New-Guid generates a new GUID' {
            Get-Command New-Guid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $result = New-Guid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
        }

        It 'New-Guid -RegistryFormat generates GUID in registry format' {
            $result = New-Guid -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}$'
        }

        It 'New-Guid -AsHex generates GUID in hex format' {
            $result = New-Guid -AsHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[0-9A-Fa-f]{32}$'
        }

        It 'New-Guid -AsBase64 generates GUID in Base64 format' {
            $result = New-Guid -AsBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'New-Guid generates unique GUIDs' {
            $guid1 = New-Guid
            $guid2 = New-Guid
            $guid1 | Should -Not -Be $guid2
        }
    }

    Context 'UUID and GUID Interoperability' {
        $testUuid = '550e8400-e29b-41d4-a716-446655440000'
        $testGuid = '550e8400-e29b-41d4-a716-446655440000'

        It 'UUID can be converted to GUID and back' {
            $guid = $testUuid | ConvertTo-GuidFromUuid
            $roundtrip = $guid | ConvertFrom-GuidToUuid
            $roundtrip | Should -Be $testUuid
        }

        It 'GUID can be converted to UUID and back' {
            $uuid = $testGuid | ConvertFrom-GuidToUuid
            $roundtrip = $uuid | ConvertTo-GuidFromUuid
            $roundtrip | Should -Be $testGuid
        }

        It 'New-Uuid and New-Guid generate compatible formats' {
            $uuid = New-Uuid
            $guid = New-Guid
            # Both should be valid UUID/GUID format
            $uuid | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
            $guid | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
        }
    }

    Context 'Error Handling' {
        It 'ConvertFrom-UuidToHex handles invalid UUID format' {
            { 'invalid-uuid' | ConvertFrom-UuidToHex } | Should -Throw
        }

        It 'ConvertTo-UuidFromHex handles invalid hex length' {
            { '123' | ConvertTo-UuidFromHex } | Should -Throw
        }

        It 'ConvertFrom-GuidToHex handles invalid GUID format' {
            { 'invalid-guid' | ConvertFrom-GuidToHex } | Should -Throw
        }

        It 'ConvertTo-GuidFromBase64 handles invalid Base64' {
            { 'invalid-base64!!!' | ConvertTo-GuidFromBase64 } | Should -Throw
        }
    }
}

