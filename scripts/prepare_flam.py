#!/usr/bin/env python3
import subprocess
import shutil
import os
import json

def main():
    repo_url = "https://github.com/klho/FLAM.git"
    clone_dir = "FLAM"
    output_file = "flam.zip"
    
    # Remove clone directory if it exists
    if os.path.exists(clone_dir):
        print(f"Removing existing {clone_dir} directory...")
        shutil.rmtree(clone_dir)
    
    # Clone the repository with submodules
    print(f"Cloning {repo_url} with submodules...")
    subprocess.run(
        ["git", "clone", "--recurse-submodules", repo_url],
        check=True
    )
    
    # Remove .git directories to reduce size
    print("Removing .git directories...")
    for root, dirs, files in os.walk(clone_dir):
        if ".git" in dirs:
            git_dir = os.path.join(root, ".git")
            shutil.rmtree(git_dir)
            dirs.remove(".git")
    
    # Create mip.json with dependencies
    print("Creating mip.json with dependencies...")
    mip_json_path = os.path.join(clone_dir, "mip.json")
    mip_config = {
        "dependencies": []
    }
    with open(mip_json_path, 'w') as f:
        json.dump(mip_config, f, indent=2)
    
    # Create zip file
    print(f"Creating {output_file}...")
    shutil.make_archive("flam", 'zip', clone_dir, '.')
    
    # Clean up cloned directory
    print(f"Cleaning up {clone_dir} directory...")
    shutil.rmtree(clone_dir)
    
    print(f"Created {output_file} successfully!")

if __name__ == "__main__":
    main()
