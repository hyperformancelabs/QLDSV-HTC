#!/bin/bash

# Function to check if we're in the project root directory
check_root_dir() {
    if [ ! -f "DESCRIPTION.md" ] || [ ! -f "README.md" ]; then
        echo "❌ Error: Please run this script from the QLDSV-HTC project root directory"
        echo "   Current directory: $(pwd)"
        return 1
    fi
    return 0
}

# Export the function so it can be used by other scripts
export -f check_root_dir 