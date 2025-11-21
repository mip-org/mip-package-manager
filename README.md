# mip

A simple command-line package manager for MATLAB packages.

## Installation

Install the package using pip:

```bash
pip install -e .
```

Or if you want to install it for development:

```bash
pip install --editable .
```

## Setup

After installation, set up MATLAB integration:

```bash
mip setup
```

This will copy the `+mip` directory to your MATLAB userpath so you can use `mip.import()` in MATLAB.

## Usage

### Install a package

```bash
mip install package_name
```

Downloads and installs a package from `https://magland.github.io/mip/package_name.zip` to `~/.mip/packages/package_name`.

### Uninstall a package

```bash
mip uninstall package_name
```

Removes an installed package after confirmation.

### List installed packages

```bash
mip list
```

Shows all currently installed packages.

### Using packages in MATLAB

After running `mip setup` and installing packages, you can import them in MATLAB:

```matlab
% Import a package (adds it to the path for the current session)
mip.import('package_name')

% Now you can use the package functions
```

## Package Structure

- Packages are stored in `~/.mip/packages/`
- Each package is extracted from a zip file into its own directory
- The `+mip` MATLAB namespace is installed in your MATLAB userpath

## Examples

```bash
# Install a package
mip install my_matlab_toolbox

# List installed packages
mip list

# Use in MATLAB
matlab
>> mip.import('my_matlab_toolbox')
>> % Now use the toolbox functions

# Uninstall when done
mip uninstall my_matlab_toolbox
```

## Requirements

- Python 3.6+
- MATLAB (for `mip setup` and using packages in MATLAB)
- requests library (installed automatically)
