# Security Scan Allowlist Configuration

This document explains how to configure the security scan allowlist to reduce false positives in security scanning.

## Overview

The security scanning script (`scripts/utils/security/run-security-scan.ps1`) includes built-in false positive filtering, but you can customize it by providing a custom allowlist file. This is useful when you have:

- Known-safe external commands that are intentionally executed
- Example code or placeholders that match secret patterns
- Test files that contain intentional security anti-patterns

## Allowlist File Format

The allowlist file is a JSON file with three optional sections:

```json
{
  "ExternalCommands": ["git", "pwsh", "powershell"],
  "SecretPatterns": [
    "password\\s*=\\s*[\"']?example",
    "api_key\\s*=\\s*[\"']?your.*key"
  ],
  "FilePatterns": ["\\.tests\\.ps1$", "test-.*\\.ps1$"]
}
```

### ExternalCommands

A list of command names (strings) that are safe to execute. These commands will not trigger warnings for external command execution patterns.

**Example:**

```json
{
  "ExternalCommands": ["git", "pwsh", "npm", "npx", "cargo"]
}
```

### SecretPatterns

A list of regular expression patterns that match known-safe secret-like strings. Lines matching these patterns will not trigger hardcoded secret warnings.

**Important:** These are regex patterns, so special characters must be escaped. For example:

- Use `\\s` for whitespace (not `\s`)
- Use `\\d` for digits (not `\d`)
- Use `[\"']` to match both single and double quotes

**Example:**

```json
{
  "SecretPatterns": [
    "password\\s*=\\s*[\"']?example",
    "password\\s*=\\s*[\"']?test",
    "password\\s*=\\s*[\"']?placeholder",
    "api_key\\s*=\\s*[\"']?your.*key",
    "token\\s*=\\s*[\"']?your.*token"
  ]
}
```

### FilePatterns

A list of regular expression patterns that match file paths. Files matching these patterns will be excluded from security scanning entirely.

**Example:**

```json
{
  "FilePatterns": [
    "\\.tests\\.ps1$",
    "\\.test\\.ps1$",
    "test-.*\\.ps1$",
    ".*\\.example\\.ps1$"
  ]
}
```

## Using the Allowlist

### Option 1: Repository-Level Allowlist

Create a file named `security-allowlist.json` in the repository root or in `scripts/utils/security/`:

```powershell
# Copy the template
Copy-Item scripts/utils/security/security-allowlist.template.json security-allowlist.json

# Edit the file to add your patterns
code security-allowlist.json
```

Then run the security scan with the allowlist:

```powershell
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1 -AllowlistFile security-allowlist.json
```

### Option 2: CI/CD Workflow

The security scan workflow (`.github/workflows/security.yml`) can be updated to use a repository allowlist file:

```yaml
- name: Run Security Scan
  run: pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1 -AllowlistFile security-allowlist.json
```

### Option 3: Default Built-in Allowlist

If no allowlist file is provided, the script uses a default built-in allowlist that includes common safe patterns:

- **ExternalCommands:** `git`, `pwsh`, `powershell`, `npm`, `npx`, `cargo`, `cspell`, `markdownlint`, `git-cliff`
- **SecretPatterns:** Common example/placeholder patterns
- **FilePatterns:** Test file patterns (`.tests.ps1`, `.test.ps1`, `test-*.ps1`)

## Best Practices

1. **Be Specific:** Only add patterns that you're certain are safe. Overly broad patterns can hide real security issues.

2. **Document Why:** Add comments in your allowlist file (using JSON comments if your parser supports them) or document in commit messages why certain patterns are allowed.

3. **Review Regularly:** Periodically review your allowlist to ensure patterns are still valid and necessary.

4. **Test Patterns:** Test your regex patterns using PowerShell's `-match` operator before adding them:

   ```powershell
   $pattern = "password\s*=\s*['""]?example"
   $testString = 'password = "example"'
   $testString -match $pattern  # Should return True
   ```

5. **Use File Patterns for Tests:** Prefer using `FilePatterns` to exclude entire test files rather than adding many `SecretPatterns` for test data.

## Examples

### Example 1: Adding a Safe External Command

If you use `docker` as a safe external command:

```json
{
  "ExternalCommands": ["docker", "docker-compose"]
}
```

### Example 2: Excluding Example Files

If you have example files that contain placeholder secrets:

```json
{
  "FilePatterns": [".*\\.example\\.ps1$", ".*examples/.*\\.ps1$"]
}
```

### Example 3: Allowing Specific Test Patterns

If your tests use specific placeholder patterns:

```json
{
  "SecretPatterns": [
    "password\\s*=\\s*[\"']?test-password-123",
    "api_key\\s*=\\s*[\"']?test-api-key"
  ]
}
```

## Template Files

Two template files are available:

1. **`security-allowlist.example.json`** - A ready-to-use example file that you can copy and customize:

   ```powershell
   Copy-Item scripts/utils/security/security-allowlist.example.json security-allowlist.json
   ```

2. **`security-allowlist.template.json`** - A JSON Schema file that documents the structure and can be used for validation.

## Related Documentation

- [Security Scanning Workflow](../.github/workflows/security.yml)
- [Security Scan Script](../scripts/utils/security/run-security-scan.ps1)
- [CODEBASE_IMPROVEMENTS.md](../CODEBASE_IMPROVEMENTS.md)
