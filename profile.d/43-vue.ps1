# ===============================================
# 43-vue.ps1
# Vue.js development helpers (guarded)
# ===============================================

<#
Register Vue helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Vue execute - run vue with arguments
if (-not (Test-Path Function:vue -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:vue -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @vue/cli @a } elseif (Test-CachedCommand vue) { vue @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:vue -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @vue/cli @a } elseif (Get-Command vue -ErrorAction SilentlyContinue) { vue @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  }
}

# Vue create project - create new Vue.js project
if (-not (Test-Path Function:vue-create -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:vue-create -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @vue/cli create @a } elseif (Test-CachedCommand vue) { vue create @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:vue-create -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @vue/cli create @a } elseif (Get-Command vue -ErrorAction SilentlyContinue) { vue create @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  }
}

# Vue serve - start development server
if (-not (Test-Path Function:vue-serve -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:vue-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand npx) { npx @vue/cli serve @a } elseif (Test-CachedCommand vue) { vue serve @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:vue-serve -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command npx -ErrorAction SilentlyContinue) { npx @vue/cli serve @a } elseif (Get-Command vue -ErrorAction SilentlyContinue) { vue serve @a } else { Write-Warning 'npx or vue not found' } } -Force | Out-Null
  }
}


