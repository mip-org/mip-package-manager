# mip Usage Guide

This guide provides detailed documentation for using the mip package manager from both the command line and within MATLAB.

## Table of Contents

- [CLI Commands](#cli-commands)
- [MATLAB Interface](#matlab-interface)
- [Package Management Workflows](#package-management-workflows)
- [Installation Locations](#installation-locations)
- [Advanced Features](#advanced-features)

## CLI Commands

### `mip install`

Install packages from the repository, a local `.mhl` file, or a URL.

```bash
mip install <package> [package2] ...
```

**Examples:**

```bash
# From repository
mip install chebfun

# Multiple packages
mip install package1 package2 package3

# From local file or URL
mip install path/to/package.mhl
mip install https://example.com/package.mhl
```

Packages are extracted to `~/.mip/packages/<package_name>`.

### `mip uninstall`

Remove installed packages after confirmation. Dependent packages are also removed.

```bash
mip uninstall <package> [package2] ...
```

**Example:**

```bash
mip uninstall chebfun package1 package2
```

### `mip list`

Display all currently installed packages.

```bash
mip list
```

This shows package names and their installation paths.

### `mip setup`

Set up MATLAB integration by creating necessary directories and files in `~/.mip/matlab/`.

```bash
mip setup
```

Run this after first installation, after upgrading mip, or if integration files are corrupted.

After setup, add `~/.mip/matlab` to your MATLAB path (see [Installation Locations](#installation-locations)).

### `mip find-name-collisions`

Detect symbol name collisions across all installed packages.

```bash
mip find-name-collisions
```

This scans all installed packages and reports any function or class names that appear in multiple packages, which could cause conflicts when packages are loaded simultaneously.

### `mip architecture`

Display the current architecture tag for your system.

```bash
mip architecture
```

This is useful for understanding which `.mhl` package files are compatible with your system. See [Architecture Tags documentation](architecture-tags.md) for details.

## MATLAB Interface

After running `mip setup` and adding `~/.mip/matlab` to your MATLAB path, you can use mip commands directly from MATLAB.

### `mip load`

Load a package by adding it to the MATLAB path for the current session.

```matlab
mip load <package>
mip load <package> --pin
```

**Examples:**

```matlab
% Load a package
mip load chebfun

% Load and pin a package in one command
mip load mypackage --pin
```

**What happens:**
- The package's `load_package.m` script is executed
- Package directories are added to the MATLAB path
- Package functions become available

### `mip unload`

Remove a package from the MATLAB path.

```matlab
mip unload <package>
mip unload --all
```

**Examples:**

```matlab
% Unload a specific package
mip unload chebfun

% Unload all non-pinned packages
mip unload --all
```

**What happens:**
- The package's `unload_package.m` script is executed
- Package directories are removed from the MATLAB path
- Package functions are no longer available

**Note:** Pinned packages are not unloaded when using `mip unload --all`.

### `mip pin`

Pin a loaded package to prevent it from being unloaded.

```matlab
mip pin <package>
```

**Example:**

```matlab
% Load and use a package frequently
mip load chebfun
mip pin chebfun

% Now it won't be unloaded by 'mip unload --all'
```

Pinned packages remain loaded even when `mip unload --all` is called, making them ideal for packages you use regularly.

### `mip unpin`

Unpin a package, allowing it to be unloaded normally.

```matlab
mip unpin <package>
```

**Example:**

```matlab
mip unpin chebfun
```

### `mip list-loaded`

Display all currently loaded packages and their pin status.

```matlab
mip list-loaded
```

This shows which packages are currently on the MATLAB path and which are pinned.

### Other MATLAB Commands

Commands not handled specially by the MATLAB interface are forwarded to the system CLI:

```matlab
% These call the system mip command
mip install mypackage
mip uninstall mypackage
mip list
mip setup
mip find-name-collisions
```

## Package Management Workflows

### Initial Setup

```bash
# 1. Install mip
pip install mip-package-manager

# 2. Set up MATLAB integration
mip setup

# 3. In MATLAB, add to path permanently
addpath('~/.mip/matlab')
savepath
```

### Installing and Using Packages

```bash
# Install and verify
mip install chebfun
mip list
```

```matlab
% Load and use in MATLAB
mip load chebfun
x = chebfun('sin(x)', [0, 2*pi]);
plot(x)

% Unload when done (optional)
mip unload chebfun
```

### Managing Multiple Packages

```bash
mip install package1 package2 package3
mip list
```

```matlab
mip load package1
mip load package2
mip pin package1

% Unloads only package2 (package1 is pinned)
mip unload --all
```

### Working with Local Packages

```bash
mip install ~/Downloads/mypackage-1.0.0-any-none-any.mhl
mip install https://example.com/packages/mypackage.mhl
```

## Installation Locations

### Package Storage

- **Packages:** `~/.mip/packages/`
  - Each package is in its own subdirectory: `~/.mip/packages/<package_name>/`
  - Contains `mip.json` metadata file
  - Contains `load_package.m` and `unload_package.m` scripts
  - Contains package files and directories

### MATLAB Integration

- **MATLAB files:** `~/.mip/matlab/`
  - Main interface: `~/.mip/matlab/mip.m`
  - Package namespace: `~/.mip/matlab/+mip/`
  - Functions: `load_package.m`, `unload_package.m`, `pin.m`, `unpin.m`, `list_loaded.m`

**Important:** Add `~/.mip/matlab` to your MATLAB path for the interface to work.

### Configuration

Currently, mip uses the default locations shown above. Package state (loaded/pinned packages) is maintained in MATLAB's workspace during the session.

## Advanced Features

### Name Collision Detection

Before loading packages, check for symbol conflicts:

```bash
mip find-name-collisions
```

This helps identify potential issues when multiple packages define functions or classes with the same name. If collisions exist, you may need to:
- Load packages selectively
- Use package namespaces explicitly
- Contact package maintainers about conflicts

### Package Pinning Strategy

Use pinning for packages you use frequently:

```matlab
% Set up your environment with commonly used packages
mip load optimization_toolkit --pin
mip load visualization_utils --pin
mip load data_processing --pin

% Load task-specific packages temporarily
mip load special_analysis

% Clean up when switching tasks
mip unload --all  % Only removes special_analysis
```

### Package Dependencies

Packages can declare dependencies in their `mip.json` file. When you install a package:
- Dependencies are automatically installed
- When uninstalling, dependent packages are also removed

Check dependencies by examining a package's `mip.json`:

```bash
cat ~/.mip/packages/<package_name>/mip.json
```

### Upgrading Packages

To upgrade a package to a newer version:

```bash
# Uninstall the old version
mip uninstall packagename

# Install the new version
mip install packagename
```

Or install directly from a new `.mhl` file:

```bash
mip install packagename-2.0.0-any-none-any.mhl
```

### Installing from Multiple Sources

mip supports installing from:
- **Repository:** `mip install packagename`
- **Local file:** `mip install /path/to/package.mhl`
- **URL:** `mip install https://example.com/package.mhl`

This flexibility allows you to:
- Use official repository packages for stability
- Test local development versions
- Install packages from custom repositories
