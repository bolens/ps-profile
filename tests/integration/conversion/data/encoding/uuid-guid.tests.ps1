

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
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir

        $script:TestUuid = '550e8400-e29b-41d4-a716-446655440000'
        $script:TestUuidHex = '550E8400E29B41D4A716446655440000'
        $script:TestGuid = '550e8400-e29b-41d4-a716-446655440000'
        $script:TestGuidHex = '550E8400E29B41D4A716446655440000'
        $script:TestGuidRegistry = '{550e8400-e29b-41d4-a716-446655440000}'
    }

    Context 'UUID Conversions' {
        It 'ConvertFrom-UuidToHex converts UUID to hex' {
            Get-Command ConvertFrom-UuidToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-UuidToHex -Uuid $script:TestUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestUuidHex
        }

        It 'ConvertTo-UuidFromHex converts hex to UUID' {
            Get-Command ConvertTo-UuidFromHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertTo-UuidFromHex -Hex $script:TestUuidHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestUuid
        }

        It 'UUID to hex and back roundtrip' {
            $hex = ConvertFrom-UuidToHex -Uuid $script:TestUuid
            $roundtrip = ConvertTo-UuidFromHex -Hex $hex
            $roundtrip | Should -Be $script:TestUuid
        }

        It 'ConvertFrom-UuidToBase64 converts UUID to Base64' {
            Get-Command ConvertFrom-UuidToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-UuidToBase64 -Uuid $script:TestUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'ConvertTo-UuidFromBase64 converts Base64 to UUID' {
            Get-Command ConvertTo-UuidFromBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $base64 = ConvertFrom-UuidToBase64 -Uuid $script:TestUuid
            $result = ConvertTo-UuidFromBase64 -Base64 $base64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestUuid
        }

        It 'UUID to Base64 and back roundtrip' {
            $base64 = ConvertFrom-UuidToBase64 -Uuid $script:TestUuid
            $roundtrip = ConvertTo-UuidFromBase64 -Base64 $base64
            $roundtrip | Should -Be $script:TestUuid
        }

        It 'ConvertFrom-UuidToBase32 converts UUID to Base32' {
            Get-Command ConvertFrom-UuidToBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command _ConvertFrom-HexToBase32 -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Base32 conversion not available'
                return
            }

            $result = ConvertFrom-UuidToBase32 -Uuid $script:TestUuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Z2-7]+$'
        }

        It 'ConvertTo-UuidFromBase32 converts Base32 to UUID' {
            Get-Command ConvertTo-UuidFromBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            if (-not (Get-Command _ConvertFrom-Base32ToHex -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Base32 conversion not available'
                return
            }

            $base32 = ConvertFrom-UuidToBase32 -Uuid $script:TestUuid
            $result = ConvertTo-UuidFromBase32 -Base32 $base32
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestUuid
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
        It 'ConvertFrom-GuidToHex converts GUID to hex' {
            Get-Command ConvertFrom-GuidToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-GuidToHex -Guid $script:TestGuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidHex
        }

        It 'ConvertFrom-GuidToHex handles registry format' {
            $result = ConvertFrom-GuidToHex -Guid $script:TestGuidRegistry
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidHex
        }

        It 'ConvertTo-GuidFromHex converts hex to GUID' {
            Get-Command ConvertTo-GuidFromHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertTo-GuidFromHex -Hex $script:TestGuidHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'ConvertTo-GuidFromHex -RegistryFormat returns registry format' {
            $result = ConvertTo-GuidFromHex -Hex $script:TestGuidHex -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidRegistry
        }

        It 'GUID to hex and back roundtrip' {
            $hex = ConvertFrom-GuidToHex -Guid $script:TestGuid
            $roundtrip = ConvertTo-GuidFromHex -Hex $hex
            $roundtrip | Should -Be $script:TestGuid
        }

        It 'ConvertFrom-GuidToRegistryFormat converts GUID to registry format' {
            Get-Command ConvertFrom-GuidToRegistryFormat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-GuidToRegistryFormat -Guid $script:TestGuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidRegistry
        }

        It 'ConvertTo-GuidFromRegistryFormat converts registry format to GUID' {
            Get-Command ConvertTo-GuidFromRegistryFormat -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertTo-GuidFromRegistryFormat -RegistryGuid $script:TestGuidRegistry
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'GUID to registry format and back roundtrip' {
            $registry = ConvertFrom-GuidToRegistryFormat -Guid $script:TestGuid
            $roundtrip = ConvertTo-GuidFromRegistryFormat -RegistryGuid $registry
            $roundtrip | Should -Be $script:TestGuid
        }

        It 'ConvertFrom-GuidToBase64 converts GUID to Base64' {
            Get-Command ConvertFrom-GuidToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-GuidToBase64 -Guid $script:TestGuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'ConvertTo-GuidFromBase64 converts Base64 to GUID' {
            Get-Command ConvertTo-GuidFromBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $base64 = ConvertFrom-GuidToBase64 -Guid $script:TestGuid
            $result = ConvertTo-GuidFromBase64 -Base64 $base64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'ConvertTo-GuidFromBase64 -RegistryFormat returns registry format' {
            $base64 = ConvertFrom-GuidToBase64 -Guid $script:TestGuid
            $result = ConvertTo-GuidFromBase64 -Base64 $base64 -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidRegistry
        }

        It 'GUID to Base64 and back roundtrip' {
            $base64 = ConvertFrom-GuidToBase64 -Guid $script:TestGuid
            $roundtrip = ConvertTo-GuidFromBase64 -Base64 $base64
            $roundtrip | Should -Be $script:TestGuid
        }

        It 'ConvertFrom-GuidToUuid converts GUID to UUID' {
            Get-Command ConvertFrom-GuidToUuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertFrom-GuidToUuid -Guid $script:TestGuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'ConvertFrom-GuidToUuid handles registry format' {
            $result = ConvertFrom-GuidToUuid -Guid $script:TestGuidRegistry
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'ConvertTo-GuidFromUuid converts UUID to GUID' {
            Get-Command ConvertTo-GuidFromUuid -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null

            $result = ConvertTo-GuidFromUuid -Uuid $script:TestGuid
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuid
        }

        It 'ConvertTo-GuidFromUuid -RegistryFormat returns registry format' {
            $result = ConvertTo-GuidFromUuid -Uuid $script:TestGuid -RegistryFormat
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be $script:TestGuidRegistry
        }

        It 'GUID to UUID and back roundtrip' {
            $uuid = ConvertFrom-GuidToUuid -Guid $script:TestGuid
            $roundtrip = ConvertTo-GuidFromUuid -Uuid $uuid
            $roundtrip | Should -Be $script:TestGuid
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
        It 'UUID can be converted to GUID and back' {
            $guid = ConvertTo-GuidFromUuid -Uuid $script:TestUuid
            $roundtrip = ConvertFrom-GuidToUuid -Guid $guid
            $roundtrip | Should -Be $script:TestUuid
        }

        It 'GUID can be converted to UUID and back' {
            $uuid = ConvertFrom-GuidToUuid -Guid $script:TestGuid
            $roundtrip = ConvertTo-GuidFromUuid -Uuid $uuid
            $roundtrip | Should -Be $script:TestGuid
        }

        It 'New-Uuid and New-Guid generate compatible formats' {
            $uuid = New-Uuid
            $guid = New-Guid
            $uuid | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
            $guid | Should -Match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'
        }
    }

    Context 'Error Handling' {
        It 'ConvertFrom-UuidToHex handles invalid UUID format' {
            { ConvertFrom-UuidToHex -Uuid 'invalid-uuid' } | Should -Throw
        }

        It 'ConvertTo-UuidFromHex handles invalid hex length' {
            { ConvertTo-UuidFromHex -Hex '123' } | Should -Throw
        }

        It 'ConvertFrom-GuidToHex handles invalid GUID format' {
            { ConvertFrom-GuidToHex -Guid 'invalid-guid' } | Should -Throw
        }

        It 'ConvertTo-GuidFromBase64 handles invalid Base64' {
            { ConvertTo-GuidFromBase64 -Base64 'invalid-base64!!!' } | Should -Throw
        }
    }
}
