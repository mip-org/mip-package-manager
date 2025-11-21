"""Command implementations for mip"""

import os
import shutil
import sys
import subprocess
import zipfile
import json
from pathlib import Path
from urllib import request
from urllib.error import URLError, HTTPError


def get_mip_dir():
    """Get the mip packages directory path"""
    home = Path.home()
    return home / '.mip' / 'packages'


def install_package(package_name, _installing_stack=None):
    """Install a package from the mip repository
    
    Args:
        package_name: Name of the package to install
        _installing_stack: Internal parameter to track installation chain for circular dependency detection
    """
    if _installing_stack is None:
        _installing_stack = []
    
    # Check for circular dependencies
    if package_name in _installing_stack:
        cycle = ' -> '.join(_installing_stack + [package_name])
        print(f"Error: Circular dependency detected: {cycle}")
        sys.exit(1)
    
    mip_dir = get_mip_dir()
    package_dir = mip_dir / package_name
    
    # Check if already installed
    if package_dir.exists():
        print(f"Package '{package_name}' is already installed")
        return
    
    # Add to installation stack for circular dependency detection
    _installing_stack.append(package_name)
    
    # Try to download the package
    url = f"https://magland.github.io/mip/{package_name}.zip"
    print(f"Downloading {package_name} from {url}...")
    
    try:
        # Create temporary file for download
        zip_path = mip_dir / f"{package_name}.zip"
        mip_dir.mkdir(parents=True, exist_ok=True)
        
        # Download the file
        request.urlretrieve(url, zip_path)
        
        # Extract the zip file
        print(f"Extracting {package_name}...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(package_dir)
        
        # Clean up zip file
        zip_path.unlink()
        
        # Check for dependencies in mip.json
        mip_json_path = package_dir / "mip.json"
        if mip_json_path.exists():
            try:
                with open(mip_json_path, 'r') as f:
                    mip_config = json.load(f)
                
                dependencies = mip_config.get('dependencies', [])
                if dependencies:
                    print(f"Installing dependencies for '{package_name}': {', '.join(dependencies)}")
                    for dep in dependencies:
                        install_package(dep, _installing_stack.copy())
            except json.JSONDecodeError as e:
                print(f"Warning: Could not parse mip.json for '{package_name}': {e}")
            except Exception as e:
                print(f"Warning: Error processing dependencies for '{package_name}': {e}")
        
        print(f"Successfully installed '{package_name}'")
        
    except HTTPError as e:
        print(f"Error: Could not download package '{package_name}' (HTTP {e.code})")
        print(f"URL: {url}")
        sys.exit(1)
    except URLError as e:
        print(f"Error: Could not download package '{package_name}': {e.reason}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to install package '{package_name}': {e}")
        # Clean up if something went wrong
        if package_dir.exists():
            shutil.rmtree(package_dir)
        sys.exit(1)


def uninstall_package(package_name):
    """Uninstall a package"""
    mip_dir = get_mip_dir()
    package_dir = mip_dir / package_name
    
    # Check if package is installed
    if not package_dir.exists():
        print(f"Package '{package_name}' is not installed")
        return
    
    # Confirm uninstallation
    response = input(f"Are you sure you want to uninstall '{package_name}'? (y/n): ")
    if response.lower() not in ['y', 'yes']:
        print("Uninstallation cancelled")
        return
    
    # Remove the package directory
    try:
        shutil.rmtree(package_dir)
        print(f"Successfully uninstalled '{package_name}'")
    except Exception as e:
        print(f"Error: Failed to uninstall package '{package_name}': {e}")
        sys.exit(1)


def list_packages():
    """List all installed packages"""
    mip_dir = get_mip_dir()
    
    if not mip_dir.exists():
        print("No packages installed yet")
        return
    
    packages = [d.name for d in mip_dir.iterdir() if d.is_dir()]
    
    if not packages:
        print("No packages installed yet")
    else:
        print("Installed packages:")
        for package in sorted(packages):
            print(f"  - {package}")


def setup_matlab():
    """Set up the +mip directory in MATLAB path"""
    try:
        # Try to get MATLAB userpath
        print("Detecting MATLAB userpath...")
        result = subprocess.run(
            ['matlab', '-batch', 'disp(userpath)'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            print("Error: Could not run MATLAB")
            print("Make sure MATLAB is installed and available in your PATH")
            sys.exit(1)
        
        # Parse the userpath (remove trailing colon/semicolon if present)
        userpath = result.stdout.strip().rstrip(':;')
        
        if not userpath:
            print("Error: Could not determine MATLAB userpath")
            sys.exit(1)
        
        print(f"MATLAB userpath: {userpath}")
        
        # Get the source +mip directory
        source_mip = Path(__file__).parent / '+mip'
        if not source_mip.exists():
            print("Error: +mip directory not found in package")
            sys.exit(1)
        
        # Destination path
        dest_mip = Path(userpath) / '+mip'
        
        # Create userpath if it doesn't exist
        Path(userpath).mkdir(parents=True, exist_ok=True)
        
        # Copy the +mip directory
        if dest_mip.exists():
            print(f"Removing existing +mip directory at {dest_mip}...")
            shutil.rmtree(dest_mip)
        
        print(f"Copying +mip to {dest_mip}...")
        shutil.copytree(source_mip, dest_mip)
        
        print(f"Successfully set up mip in MATLAB!")
        print(f"You can now use 'mip.import('[package]')' in MATLAB")
        
    except subprocess.TimeoutExpired:
        print("Error: MATLAB command timed out")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: MATLAB not found")
        print("Make sure MATLAB is installed and available in your PATH")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to set up MATLAB integration: {e}")
        sys.exit(1)
