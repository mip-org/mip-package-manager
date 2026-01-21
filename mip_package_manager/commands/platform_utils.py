"""Platform detection and compatibility utilities"""

import platform
import sys


def get_current_architecture_tag():
    """Detect the current architecture and return the corresponding MIP architecture tag

    Returns:
        str: Architecture tag (e.g., 'linux_x86_64', 'macosx_11_0_arm64', 'win_amd64')
    """
    system = platform.system()
    machine = platform.machine().lower()
    
    # Normalize machine architecture names
    if machine in ('x86_64', 'amd64'):
        machine = 'x86_64'
    elif machine in ('aarch64', 'arm64'):
        machine = 'arm64'
    else:
        raise ValueError(f"Unsupported architecture: {machine} on {system}")
    
    if system == 'Linux':
        return f'linux_{machine}'
    
    elif system == 'Darwin':  # macOS
        return f'macos_{machine}'
    
    elif system == 'Windows':
        return f'windows_{machine}'
    
    else:
        # Unknown architecture - return a generic tag
        return f'{system.lower()}_{machine}'


def select_best_package_variant(variants, current_architecture=None):
    """Select the best package variant for the current architecture

    When multiple variants of a package exist (e.g., architecture-specific and 'any'),
    prefer the architecture-specific version.

    Args:
        variants: List of package info dictionaries with 'architecture' field
        current_architecture: The current architecture (detected if not provided)

    Returns:
        dict or None: The best matching package variant, or None if no compatible variant
    """
    if current_architecture is None:
        current_architecture = get_current_architecture_tag()
    
    if not variants:
        return None
    
    # Filter to compatible variants only
    for v in variants:
        if 'architecture' not in v:
            print(v)
            print(f"Warning: Package variant {v.get('name', '<unknown>')} is missing 'architecture' field")
            v['architecture'] = 'error_missing_field'
    compatible = [v for v in variants if v['architecture'] == current_architecture or v['architecture'] == 'any']

    if not compatible:
        return None

    # Prefer exact architecture matches over 'any'
    exact_matches = [v for v in compatible if v['architecture'] == current_architecture]
    if exact_matches:
        # If multiple exact matches, prefer the one with highest version/build
        return exact_matches[0]

    # Should not reach here if is_architecture_compatible is working correctly
    return compatible[0] if compatible else None


def get_available_architectures_for_package(variants):
    """Get a list of available architectures for a package

    Args:
        variants: List of package info dictionaries with 'architecture' field

    Returns:
        list: Sorted list of unique architecture tags
    """
    architectures = set(v['architecture'] for v in variants)
    return sorted(architectures)

def print_architecture():
    """Print the current architecture tag"""
    architecture_tag = get_current_architecture_tag()
    print(f"{architecture_tag}")
