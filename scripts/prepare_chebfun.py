#!/usr/bin/env python3
import requests
import os

def main():
    url = "https://github.com/chebfun/chebfun/archive/master.zip"
    output_file = "chebfun.zip"
    
    print(f"Downloading {url}...")
    response = requests.get(url)
    response.raise_for_status()
    
    with open(output_file, 'wb') as f:
        f.write(response.content)
    
    print(f"Created {output_file} successfully!")

if __name__ == "__main__":
    main()