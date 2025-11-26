# mip package manager

> **⚠️ Warning**: This project is at a very early stage of development and is subject to breaking changes.

A pip-style package manager for MATLAB packages.

## Installation and Setup

**Step 1**: Install the package using pip.

```bash
pip install mip-package-manager
```

Or install from source:

```bash
# First, clone the repository
git clone https://github.com/mip-org/mip-package-manager.git
cd mip-package-manager

# Then, install the package
pip install -e .
```

**Step 2**: Set up the MATLAB integration.

```bash
mip setup
```

This command will create the necessary directories and files in `~/.mip/matlab` for MATLAB integration.

Then add `~/.mip/matlab` to your MATLAB path permanently. You can do this in MATLAB:

```matlab
addpath('~/.mip/matlab')
savepath
```

Alternatively, you can add this to your MATLAB `startup.m` file (typically located at `~/Documents/MATLAB/startup.m`):

```matlab
addpath('~/.mip/matlab')
```

**Note**: After upgrading to a new version of mip, run `mip setup` to ensure you have the latest MATLAB integration.

## Usage

For detailed documentation on all commands and features, see the [Usage Guide](docs/usage-guide.md).

### Install a package

Either from the command line or from within MATLAB, run:

```bash
mip install package_name
```

For example, to install the `chebfun` package:

```bash
mip install chebfun
```

This downloads and installs a package to `~/.mip/packages/package_name`.

[Table of installable packages](https://mip-org.github.io/mip-core/packages.html)

### Using packages in MATLAB

After setting up the MATLAB path and installing packages, you can load them in MATLAB:

```matlab
% Load a package (adds it to the path for the current session)
mip load package_name

% Now you can use the package functions
```

For example:

```matlab
mip load chebfun
% Now use chebfun functions
```

### List installed packages

```bash
mip list
```

Shows all currently installed packages.

### Uninstall a package

```bash
mip uninstall package_name
```

Removes an installed package after confirmation. Also removes any packages that depend on it.

## Internal Package Structure

- Packages are stored in `~/.mip/packages/`
- Each package is extracted from a zip (.mhl) file into its own directory
- Each package has a `mip.json` file containing metadata, a `load_package.m` that gets called when the package is loaded, and an `unload_package.m` that gets called when the package is unloaded.
- The `+mip` MATLAB namespace is installed in `~/.mip/matlab/+mip/`

## Example

```bash
# Install a package
mip install chebfun

# List installed packages
mip list

# Use in MATLAB
matlab
>> mip load chebfun
>> % Now use the toolbox functions

# Uninstall
mip uninstall chebfun
```

## How to add new packages

For now mip supports a [limited set of packages](https://mip-org.github.io/mip-core/packages.html). To add a new package, you can submit a pull request to https://github.com/mip-org/mip-core.

## Requirements

- Python 3.6+
- MATLAB

## Authors

Jeremy Magland and Dan Fortunato - Center for Computational Mathematics, Flatiron Institute

## License

Apache License 2.0
