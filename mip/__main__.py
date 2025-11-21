"""CLI entry point for mip"""

import sys
from .commands import install_package, uninstall_package, list_packages, setup_matlab

def print_usage():
    """Print usage information"""
    print("Usage: mip <command> [arguments]")
    print()
    print("Commands:")
    print("  install <package>   Install a package")
    print("  uninstall <package> Uninstall a package")
    print("  list                List installed packages")
    print("  setup               Set up MATLAB integration")
    print()
    print("Examples:")
    print("  mip install mypackage")
    print("  mip uninstall mypackage")
    print("  mip list")
    print("  mip setup")

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
    
    else:
        print(f"Error: Unknown command '{command}'")
        print()
        print_usage()
        sys.exit(1)

if __name__ == '__main__':
    main()