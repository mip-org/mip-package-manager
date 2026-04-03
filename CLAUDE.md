# MIP Package Manager

A package manager for MATLAB/MEX. Handles installing, updating, loading, and unloading packages from channels (GitHub-hosted package repositories).

## Architecture

- `mip.m` — CLI entry point, dispatches to command handlers
- `+mip/` — MATLAB package namespace containing all functionality
  - Core commands: `install.m`, `update.m`, `uninstall.m`, `load.m`, `unload.m`, `list.m`, `info.m`, `avail.m`, `bundle.m`
  - `+build/` — Package preparation, compilation, script generation
  - `+dependency/` — Dependency graph resolution and topological sorting
  - `+utils/` — Utility functions (parsing, storage, discovery, downloads)
- `tests/` — Unit tests using MATLAB's `matlab.unittest` framework

## Key Concepts

- **FQN (Fully Qualified Name)**: `org/channel/package` (e.g., `mip-org/core/chebfun`)
- **Bare name**: Just `package` — resolved via priority: `mip-org/core` first, then alphabetical
- **Channels**: Package repositories hosted on GitHub Pages (e.g., `mip-org/mip-core`)
- **Packages installed at**: `~/.mip/packages/<org>/<channel>/<package>/`
- **Editable installs**: Thin wrapper at `local/local/<pkg>/` pointing to source directory
- **Persistent state**: Uses `setappdata(0, key, value)` for loaded/sticky/directly-loaded package tracking; `directly_installed.txt` for install tracking

## Running Tests

```matlab
addpath('tests'); addpath('tests/helpers');
results = run_tests();
```

Or from any directory:
```matlab
cd /path/to/mip-package-manager
addpath('tests'); addpath('tests/helpers');
results = run_tests();
```

## Development Rules

- **Always add unit tests** for new functionality. Tests go in `tests/Test*.m` as `matlab.unittest.TestCase` subclasses. Use `createTestPackage` and `createTestSourcePackage` helpers to set up fake packages in temporary directories. Use `MIP_ROOT` env var to isolate tests from the real `~/.mip`.
- The special identity `mip-org/core/mip` must always be checked by FQN, never by bare name `'mip'`. Other packages named `mip` on different channels must not get special treatment.
