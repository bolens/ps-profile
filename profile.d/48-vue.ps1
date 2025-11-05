# ===============================================
# 48-vue.ps1
# Vue.js development helpers (guarded)
# ===============================================

<#
Register Vue helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Vue execute - run vue with arguments
if (-not (Test-Path Function:vue -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:vue -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @vue/cli @a } elseif (Test-HasCommand vue) { vue @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
}

# Vue create project - create new Vue.js project
if (-not (Test-Path Function:vue-create -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:vue-create -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @vue/cli create @a } elseif (Test-HasCommand vue) { vue create @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
}

# Vue serve - start development server
if (-not (Test-Path Function:vue-serve -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:vue-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand npx) { npx @vue/cli serve @a } elseif (Test-HasCommand vue) { vue serve @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
}
