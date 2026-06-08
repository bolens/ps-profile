# Fragment Loading Optimization

How the profile achieves fast startup through command pre-registration and lazy fragment loading.

## How It Works

Fragments register commands when they load, but the command dispatcher needs the registry populated before fragments execute. The loader solves this by **pre-registering** commands from fragment source (AST + regex parsing, with SQLite caching) without executing fragment code, then loading fragments **on demand** when a command is first used.

```
Profile Start
  ↓
Load bootstrap fragments (required infrastructure)
  ↓
Pre-register commands from all fragment files (parse only, no execution)
  ↓
Register CommandDispatcher (full command registry available)
  ↓
Skip non-bootstrap fragment execution (lazy mode, default)
  ↓
Load fragment when user invokes a command from that fragment
```

Key modules:

- `scripts/lib/fragment/FragmentCommandRegistry.psm1` — `Register-CommandsFromFragmentAst`, `Register-AllFragmentCommands`
- `scripts/lib/fragment/FragmentLoader.psm1` — on-demand fragment loading
- `scripts/lib/fragment/CommandDispatcher.psm1` — `CommandNotFoundAction` integration
- `scripts/lib/profile/ProfileFragmentLoader.psm1` — startup orchestration

See [Fragment Command Access](FRAGMENT_COMMAND_ACCESS.md) for dispatcher and wrapper details.

## Configuration

| Variable | Default | Effect |
| -------- | ------- | ------ |
| `PS_PROFILE_LAZY_LOAD_FRAGMENTS` | enabled | Skip loading non-bootstrap fragments at startup |
| `PS_PROFILE_LOAD_ALL_FRAGMENTS` | — | Set `1` to load all fragments at startup (disables lazy loading) |
| `PS_PROFILE_PRE_REGISTER_COMMANDS` | enabled | Parse fragments to populate registry without executing them |
| `PS_PROFILE_CREATE_PROXIES` | enabled | Lightweight proxy functions for tab completion |
| `PS_PROFILE_PREWARM_CACHE` | off | Pre-load SQLite cache entries at startup ([Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md)) |
| `PS_PROFILE_USE_AST_PARSING` | — | Use AST parsing in addition to regex (more accurate, slower) |

`PS_PROFILE_LAZY_LOAD_FRAGMENTS` takes precedence over `PS_PROFILE_LOAD_ALL_FRAGMENTS` when both are set.

### Load all fragments (previous behavior)

```powershell
$env:PS_PROFILE_LOAD_ALL_FRAGMENTS = '1'
```

### Disable proxy creation for faster startup

```powershell
$env:PS_PROFILE_CREATE_PROXIES = '0'
```

## Trade-offs

| Mode | Startup | First command use | Tab completion |
| ---- | ------- | ----------------- | -------------- |
| Lazy (default) | Fastest | Loads owning fragment once | Proxies enabled by default |
| Load all | Slower | No extra load | Full registry without proxies |

## Limitations

- Commands created only at runtime (not visible in source) are not pre-registered; the dispatcher loads the fragment when the command is invoked.
- Complex dynamic command registration may require regex fallback or fragment load.
- Fragment dependencies are resolved when the fragment loads on demand.

## Related Documentation

- [Fragment Command Access](FRAGMENT_COMMAND_ACCESS.md)
- [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md)
- [Profile Load Time Optimization](PROFILE_LOAD_TIME_OPTIMIZATION.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)
