# MIP Package Manager - MATLAB Implementation

A pure MATLAB client for the MIP package manager for MATLAB packages.

## Features

- **Package Installation**: Install packages from the mip repository, local .mhl files, or URLs
- **Dependency Resolution**: Automatically resolves and installs package dependencies
- **Package Management**: List, uninstall, and get information about installed packages
- **Package Loading**: Load/unload packages into the MATLAB path
- **Collision Detection**: Find symbol name collisions across packages
- **Architecture Detection**: Automatic detection of system architecture for package compatibility

## Installation

1. Add the `matlab/` directory to your MATLAB path:
   ```matlab
   addpath('/path/to/mip-package-manager/matlab')
   savepath
   ```

2. Verify installation:
   ```matlab
   mip architecture
   ```

## Usage

### Installing Packages

```matlab
% Install from repository
mip install chebfun

% Install multiple packages
mip install package1 package2 package3

% Install from local .mhl file
mip install /path/to/package.mhl

% Install from URL
mip install https://example.com/package.mhl
```

### Listing Packages

```matlab
% List all installed packages
mip list

% List loaded packages
mip list-loaded

% Get detailed package information
mip info chebfun
```

### Uninstalling Packages

```matlab
% Uninstall a package (with confirmation)
mip uninstall mypackage

% Uninstall multiple packages
mip uninstall package1 package2
```

### Loading/Unloading Packages

```matlab
% Load a package
mip load chebfun

% Load and pin a package
mip load chebfun --pin

% Unload a package
mip unload chebfun

% Unload all non-pinned packages
mip unload --all

% Pin/unpin packages
mip pin chebfun
mip unpin chebfun
```

### Utility Commands

```matlab
% Find symbol name collisions
mip find-name-collisions

% Display current architecture
mip architecture

% Get help
help mip
```

## Architecture

```
matlab/
├── mip.m                      # Main dispatcher function
├── +mip/                      # Package namespace
│   ├── +utils/                # Utility functions
│   │   ├── get_mip_dir.m
│   │   ├── get_packages_dir.m
│   │   ├── get_architecture.m
│   │   ├── download_file.m
│   │   ├── extract_mhl.m
│   │   └── read_package_json.m
│   ├── +dependency/           # Dependency resolution
│   │   ├── build_dependency_graph.m
│   │   ├── topological_sort.m
│   │   └── find_reverse_dependencies.m
│   ├── install.m              # Install command
│   ├── uninstall.m            # Uninstall command
│   ├── list.m                 # List command
│   ├── architecture.m         # Architecture command
│   ├── find_name_collisions.m # Collision detection
│   ├── info.m                 # Package info command
│   ├── load.m                 # Load package
│   ├── unload.m               # Unload package
│   ├── pin.m                  # Pin package
│   ├── unpin.m                # Unpin package
│   └── list_loaded.m          # List loaded packages
└── README.md                  # This file
```

## Package Storage

Packages are installed to `~/.mip/packages/` by default. You can customize this location by setting the `MIP_DIR` environment variable:

```matlab
setenv('MIP_DIR', '/custom/path')
```

## How It Works

### Installation Process

1. **Fetch Package Index**: Downloads the package index from `https://mip-org.github.io/mip-core/index.json`
2. **Architecture Detection**: Detects the current system architecture
3. **Dependency Resolution**: Builds a complete dependency graph
4. **Download & Extract**: Downloads and extracts packages in dependency order
5. **Verification**: Validates each package's `mip.json` file

### Package Format

Packages are distributed as `.mhl` files (which are zip archives) containing:
- `mip.json` - Package metadata
- `load_package.m` - Script to load the package
- `unload_package.m` - Script to unload the package
- Package files and directories

### mip.json Structure

```json
{
  "name": "packagename",
  "version": "1.0.0",
  "dependencies": ["dep1", "dep2"],
  "exposed_symbols": ["function1", "class1"]
}
```

## MATLAB-Specific Implementation Details

### HTTP Operations
- Uses `websave()` for downloading files
- Limited to basic HTTP GET requests (no custom headers or authentication)

### File Operations
- Uses standard MATLAB functions: `mkdir()`, `rmdir()`, `dir()`, `fullfile()`
- Home directory accessed via `getenv('HOME')` (Unix) or `getenv('USERPROFILE')` (Windows)

### JSON Parsing
- Uses `jsondecode()` and `fileread()` for parsing `mip.json` files

### Platform Detection
- Uses `computer()` and `computer('arch')` to detect OS and architecture
- Maps to mip architecture tags: `linux_x86_64`, `macos_arm64`, `windows_x86_64`, etc.

### User Input
- Uses `input()` for confirmation prompts
- **Note**: May not work in all MATLAB contexts (e.g., deployed applications)

## Limitations

1. **HTTP Capabilities**: 
   - No progress indicators during downloads
   - No support for custom HTTP headers or authentication
   - No concurrent downloads

2. **Interactive Input**:
   - Confirmation prompts using `input()` may not work in all MATLAB environments
   - No transaction rollback if installation fails partway through

3. **Error Recovery**:
   - Manual cleanup may be needed if installations fail
   - No automatic rollback of partially installed packages

## Differences from Python Implementation

1. **No `mip setup` command**: The MATLAB package is self-contained in the matlab/ directory
2. **Direct function calls**: All functionality is callable from within MATLAB (e.g., `mip.install('pkg')`)
3. **Simplified architecture**: No separate CLI vs MATLAB integration - everything is MATLAB
4. **Container.Map instead of dict**: Uses MATLAB's containers.Map for hash tables

## Examples

### Complete Workflow

```matlab
% Add mip to path (first time only)
addpath('/path/to/mip-package-manager/matlab')
savepath

% Check architecture
mip architecture

% Install a package
mip install chebfun

% List installed packages
mip list

% Load the package
mip load chebfun

% Use the package
x = chebfun('sin(x)', [0, 2*pi]);
plot(x)

% Unload when done
mip unload chebfun

% Uninstall
mip uninstall chebfun
```

### Managing Dependencies

```matlab
% Install a package with dependencies
mip install mypackage

% The installation plan shows all packages to be installed
% Installation plan (3 packages):
%   - dependency1 1.0.0
%   - dependency2 2.0.0
%   - mypackage 1.5.0

% Get package info to see dependencies
mip info mypackage
```

### Finding Collisions

```matlab
% Install several packages
mip install package1 package2 package3

% Check for symbol name collisions
mip find-name-collisions

% Output shows which symbols appear in multiple packages
% Name collisions found: 2
% Colliding symbols:
%   - myfunction (found in: package1, package2)
%   - MyClass (found in: package2, package3)
```

## Troubleshooting

### Package Not Found
```matlab
% Error: Package 'mypackage' not found in repository
% Solution: Check package name spelling and availability
mip list  % List installed packages
```

### Architecture Mismatch
```matlab
% Error: Package 'mypackage' is not available for architecture 'macos_arm64'
% Solution: Check available architectures or contact package maintainer
mip architecture  % See your current architecture
```

### Installation Fails
```matlab
% If installation fails partway through, manually clean up:
packagesDir = fullfile(getenv('HOME'), '.mip', 'packages');
% Remove incomplete package directory manually
```

## Contributing

To add new functionality:

1. Add functions to the appropriate namespace (`+mip/`, `+mip/+utils/`, `+mip/+dependency/`)
2. Update the main dispatcher (`mip.m`) if adding new commands
3. Follow MATLAB documentation standards (use `help functionname` format)
4. Add error handling with meaningful error identifiers (`mip:errorType`)

## License

Apache License 2.0

## Authors

Jeremy Magland and Dan Fortunato - Center for Computational Mathematics, Flatiron Institute
