#!/usr/bin/env bash
#
# SkyPilot Flake Update Script
# 
# This script automatically updates the SkyPilot package in flake.nix to the
# latest release from GitHub. It handles version detection, hash calculation,
# and verification automatically.
#
# Usage: ./update.sh
#
# The script will:
# 1. Fetch the latest SkyPilot release from GitHub API
# 2. Update the version and tag in flake.nix
# 3. Calculate the new SHA256 hash automatically
# 4. Verify the build works before committing changes
# 5. Rollback on any errors
#
# Requirements: curl, jq, nix, git

set -euo pipefail

# ANSI color codes for formatted output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions with colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verify all required tools are available before proceeding
check_dependencies() {
    local deps=("curl" "jq" "nix" "git")
    print_status "Checking required dependencies..."
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is required but not installed."
            print_error "Please install $dep and try again."
            exit 1
        fi
    done
    
    print_status "All dependencies found"
}

# Fetch the latest release version from GitHub API
get_latest_version() {
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/skypilot-org/skypilot/releases/latest | jq -r '.tag_name')
    
    if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
        print_error "Failed to fetch latest release version from GitHub API"
        print_error "Check your internet connection and GitHub API access"
        exit 1
    fi
    
    echo "$latest_tag"
}

# Extract current version from flake.nix file
get_current_version() {
    if [[ ! -f "flake.nix" ]]; then
        print_error "flake.nix not found in current directory"
        exit 1
    fi
    
    grep -o 'version = "[^"]*"' flake.nix | sed 's/version = "\([^"]*\)"/\1/'
}

# Update version strings in flake.nix
update_version() {
    local new_version="$1"
    local version_without_v="${new_version#v}"
    
    print_status "Updating version to $version_without_v in flake.nix..."
    
    # Update the version field
    sed -i "s/version = \"[^\"]*\"/version = \"$version_without_v\"/" flake.nix
    # Update the tag field to maintain v prefix
    sed -i "s/tag = \"v[^\"]*\"/tag = \"$new_version\"/" flake.nix
    
    print_status "Version updated successfully"
}

# Calculate and update the source hash for the new version
update_hash() {
    local version="$1"
    
    print_status "Calculating SHA256 hash for version $version..."
    
    local new_hash
    # Try nix-prefetch-github first (more reliable if available)
    if command -v nix-prefetch-github &> /dev/null; then
        print_status "Using nix-prefetch-github..."
        new_hash=$(nix-prefetch-github skypilot-org skypilot --rev "$version" | jq -r '.sha256')
        # Convert to SRI format
        new_hash="sha256-$new_hash"
    else
        # Fallback to nix-prefetch-url with SRI conversion
        print_status "Using nix-prefetch-url with SRI conversion..."
        local tarball_url="https://github.com/skypilot-org/skypilot/archive/$version.tar.gz"
        local raw_hash
        raw_hash=$(nix-prefetch-url --unpack --type sha256 "$tarball_url" 2>/dev/null)
        new_hash=$(nix hash to-sri --type sha256 "$raw_hash")
    fi
    
    if [[ -z "$new_hash" ]]; then
        print_error "Failed to calculate source hash"
        print_error "This could be due to network issues or invalid version tag"
        exit 1
    fi
    
    print_status "Calculated hash: $new_hash"
    
    # Update the hash field in flake.nix
    sed -i "s/hash = \"sha256-[^\"]*\"/hash = \"$new_hash\"/" flake.nix
    print_status "Hash updated in flake.nix"
}

# Build and verify the updated package works correctly
verify_update() {
    print_status "Building and verifying the updated package..."
    
    # Attempt to build the SkyPilot package
    print_status "Building SkyPilot package..."
    if nix build --cores 4 --max-jobs 4 .#skypilot; then
        print_status "Package build successful!"
        
        # Verify the built version matches expectations
        print_status "Verifying built version..."
        local built_version
        built_version=$(result/bin/sky --version | grep -o 'version [0-9.]*' | cut -d' ' -f2)
        local expected_version
        expected_version=$(get_current_version)
        
        if [[ "$built_version" == "$expected_version" ]]; then
            print_status "Version verification successful: $built_version"
            return 0
        else
            print_error "Version mismatch detected!"
            print_error "Expected: $expected_version, but built binary reports: $built_version"
            return 1
        fi
    else
        print_error "Package build failed!"
        print_error "This could indicate missing dependencies or build system issues"
        return 1
    fi
}

# Main update workflow
main() {
    print_status "Starting SkyPilot update process..."
    
    # Verify we have all required tools
    check_dependencies
    
    # Get current and latest versions
    local current_version
    current_version=$(get_current_version)
    print_status "Current version: $current_version"
    
    print_status "Fetching latest SkyPilot release from GitHub..."
    local latest_version
    latest_version=$(get_latest_version)
    print_status "Latest available version: $latest_version"
    
    # Check if update is needed
    local latest_version_without_v="${latest_version#v}"
    if [[ "$current_version" == "$latest_version_without_v" ]]; then
        print_status "Already up to date! No changes needed."
        exit 0
    fi
    
    print_status "Update required: $current_version → $latest_version_without_v"
    
    # Create safety backup before making changes
    print_status "Creating backup of current flake.nix..."
    cp flake.nix flake.nix.bak
    print_status "Backup saved as flake.nix.bak"
    
    # Perform the update
    update_version "$latest_version"
    update_hash "$latest_version"
    
    # Verify everything works before finishing
    if verify_update; then
        print_status "✅ Update verification successful!"
        
        # Clean up backup file
        rm -f flake.nix.bak
        print_status "Removed backup file"
        
        # Update the flake lock file with new inputs
        print_status "Updating flake.lock file..."
        nix flake update
        
        print_status "🎉 Successfully updated SkyPilot to version $latest_version_without_v!"
        print_status "You can now use: nix build .#skypilot or nix develop"
    else
        print_error "❌ Update verification failed!"
        print_error "Restoring original flake.nix from backup..."
        mv flake.nix.bak flake.nix
        print_error "Update aborted. Original file restored."
        exit 1
    fi
}

# Entry point - run main function with all command line arguments
main "$@"