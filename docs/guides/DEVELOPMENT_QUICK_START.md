# Development Quick Start - Fast Profile Loading

Quick reference for developers working on the profile.

## 🚀 Quick Setup (30 seconds)

Create a `.env` file in your profile root:

```powershell
PS_PROFILE_DEV_MODE=1
PS_PROFILE_SKIP_UPDATES=1
PS_PROFILE_FAST_RELOAD=1
```

That's it! Your profile will now load 30-50% faster.

## ⚡ Fast Reload Commands

```powershell
reload-fast          # Fast reload (recommended for development)
reload               # Normal reload (for final testing)

# Reload just one fragment
Reload-Fragment -FragmentName 'files'

# Test a fragment in isolation
Test-Fragment -FragmentName 'files'
```

## 📊 Expected Performance

- **Normal Load:** 2-5 seconds
- **Dev Mode Load:** 1-2 seconds ⚡
- **Fast Reload:** 0.5-1 second ⚡⚡
- **Fragment-Only:** 0.1-0.5 seconds ⚡⚡⚡

## 🎯 Development Workflow

### 1. Edit Fragment

```powershell
code profile.d/files.ps1
```

### 2. Fast Reload

```powershell
reload-fast
```

### 3. Test Changes

```powershell
# Your test code here
```

### 4. Repeat

## 🔧 Advanced: Test Fragment in Isolation

```powershell
# Load just bootstrap + your fragment (fastest)
Test-Fragment -FragmentName 'files'

# Now test your changes
# ... your test code ...
```

## 📝 Environment Variables Reference

| Variable                           | Effect                               | Recommended for Dev |
| ---------------------------------- | ------------------------------------ | ------------------- |
| `PS_PROFILE_DEV_MODE=1`            | Enables dev optimizations            | ✅ Yes              |
| `PS_PROFILE_SKIP_UPDATES=1`        | Skips update checks                  | ✅ Yes              |
| `PS_PROFILE_FAST_RELOAD=1`         | Auto-enables fast reload             | ✅ Yes              |
| `PS_PROFILE_LAZY_LOAD_FRAGMENTS=1` | Lazy load fragments (faster startup) | ✅ Yes              |
| `PS_PROFILE_DEBUG=1`               | Shows debug output                   | Optional            |
| `PS_PROFILE_DEBUG=3`               | Shows timing info                    | When profiling      |

## 🐛 Troubleshooting

**Profile still slow?**

```powershell
# Check what's loading
$env:PS_PROFILE_DEBUG = '3'
. $PROFILE
$global:PSProfileFragmentTimes | Sort-Object Duration -Descending | Select-Object -First 5
```

**Fast reload not working?**

```powershell
# Verify dev mode
$env:PS_PROFILE_DEV_MODE
# Should output: 1
```

## 📚 Full Documentation

### Testing

- [TESTING.md](./TESTING.md) - **Primary** testing guide (structure, runner flags, batch scripts)
- [TESTING_PATTERNS.md](../examples/TESTING_PATTERNS.md) - Code examples for writing tests
- [TEST_VERIFICATION_MOCKING_GUIDE.md](./TEST_VERIFICATION_MOCKING_GUIDE.md) - TestSupport stubs
- [VERIFY_COVERAGE.md](./VERIFY_COVERAGE.md) - Coverage verification with `analyze-coverage.ps1`
- [TOOL_REQUIREMENTS.md](./TOOL_REQUIREMENTS.md) - Required and optional test tools

### Performance and workflow

- [DEVELOPMENT_PERFORMANCE.md](./DEVELOPMENT_PERFORMANCE.md) - Complete guide
- [PROFILE_LOAD_TIME_OPTIMIZATION.md](./PROFILE_LOAD_TIME_OPTIMIZATION.md) - General optimizations
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow
