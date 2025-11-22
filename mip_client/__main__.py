"""CLI entry point for mip-client"""

import sys
from .commands import install_package, uninstall_package, list_packages, setup_matlab, find_name_collisions

def print_usage():
    """Print usage information"""
    print("Usage: mip <command> [arguments]")
    print()
    print("Commands:")
    print("  install <package>      Install a package from repository, local .mhl file, or URL")
    print("  uninstall <package>    Uninstall a package")
    print("  list                   List installed packages")
    print("  setup                  Set up MATLAB integration")
    print("  find-name-collisions   Find symbol name collisions across packages")
    print()
    print("Examples:")
    print("  mip install mypackage")
    print("  mip install package.mhl")
    print("  mip install https://example.com/package.mhl")
    print("  mip uninstall mypackage")
    print("  mip list")
    print("  mip setup")
    print("  mip find-name-collisions")

def main():
    """Main entry point for the CLI"""
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    if command == 'install':
        if len(sys.argv) < 3:
            print("Error: Package name required")
            print("Usage: mip install <package>")
            sys.exit(1)
        package_name = sys.argv[2]
        install_package(package_name)
    
    elif command == 'uninstall':
        if len(sys.argv) < 3:
            print("Error: Package name required")
            print("Usage: mip uninstall <package>")
            sys.exit(1)
        package_name = sys.argv[2]
        uninstall_package(package_name)
    
    elif command == 'list':
        list_packages()
    
    elif command == 'setup':
        setup_matlab()
    
    elif command == 'find-name-collisions':
        find_name_collisions()
    
    else:
        print(f"Error: Unknown command '{command}'")
        print()
        print_usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
