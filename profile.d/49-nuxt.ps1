# ===============================================
# 49-nuxt.ps1
# Nuxt.js development helpers (guarded)
# ===============================================

<#
Register Nuxt helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Nuxt execute - run nuxi with arguments
if (-not (Test-Path Function:nuxi -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:nuxi -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand nuxi) { npx nuxi @a } else { Write-Warning 'nuxi not found' } } -Force | Out-Null
}

# Nuxt dev server - start development server
if (-not (Test-Path Function:nuxt-dev -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:nuxt-dev -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx nuxi dev @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
}

# Nuxt build - create production build
if (-not (Test-Path Function:nuxt-build -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:nuxt-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx nuxi build @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
}

# Create Nuxt app - scaffold new Nuxt.js project
if (-not (Test-Path Function:create-nuxt-app -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:create-nuxt-app -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx nuxi@latest init @a } else { Write-Warning 'npx not found' } } -Force | Out-Null
}
