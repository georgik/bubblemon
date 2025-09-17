#!/bin/bash

# Manual release script for Bubblemon macOS
# This script creates a GitHub release with the built applications

set -e

# Configuration
REPO_OWNER="$(git remote get-url origin | sed 's/.*github.com[:/]\([^/]*\).*/\1/')"
REPO_NAME="$(git remote get-url origin | sed 's/.*github.com[:/][^/]*\/\(.*\)\.git.*/\1/')"
BUILD_DIR="build"
ARCHIVE_NAME="Bubblemon-macOS-ARM64.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}INFO:${NC} $1"; }
echo_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
echo_warning() { echo -e "${YELLOW}WARNING:${NC} $1"; }
echo_error() { echo -e "${RED}ERROR:${NC} $1"; }

# Check requirements
check_requirements() {
    echo_info "Checking requirements..."
    
    if ! command -v gh &> /dev/null; then
        echo_error "GitHub CLI (gh) is required but not installed."
        echo_info "Install it with: brew install gh"
        echo_info "Then authenticate with: gh auth login"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo_error "GitHub CLI is not authenticated."
        echo_info "Authenticate with: gh auth login"
        exit 1
    fi
    
    if [ ! -d "$BUILD_DIR" ]; then
        echo_error "Build directory not found: $BUILD_DIR"
        echo_info "Run ./build_ci.sh first to build the applications"
        exit 1
    fi
}

# Get version information
get_version() {
    echo_info "Determining version..."
    
    if git describe --tags --exact-match HEAD 2>/dev/null; then
        VERSION=$(git describe --tags --exact-match HEAD)
        echo_info "Using git tag: $VERSION"
        # Check if it's a prerelease (contains alpha, beta, rc, dev)
        if [[ $VERSION =~ (alpha|beta|rc|dev) ]]; then
            IS_PRERELEASE="true"
            echo_info "Detected prerelease version: $VERSION"
        else
            IS_PRERELEASE="false"
            echo_info "Detected stable release: $VERSION"
        fi
    else
        echo_error "No git tag found on current commit!"
        echo_info "This script now requires a version tag. Create one with:"
        echo_info "  git tag v1.0.0"
        echo_info "  git push origin v1.0.0"
        exit 1
    fi
}

# Create release archive
create_archive() {
    echo_info "Creating release archive..."
    
    cd "$BUILD_DIR"
    
    # Create distribution directory
    rm -rf Bubblemon-macOS-Release
    mkdir -p Bubblemon-macOS-Release
    
    # Copy applications
    if [ -d "Bubblemon Menu Bar.app" ]; then
        echo_info "Adding Bubblemon Menu Bar.app"
        cp -R "Bubblemon Menu Bar.app" "Bubblemon-macOS-Release/"
    else
        echo_error "Bubblemon Menu Bar.app not found!"
        exit 1
    fi
    
    if [ -d "Bubblemon.app" ]; then
        echo_info "Adding Bubblemon.app (Dock version)"
        cp -R "Bubblemon.app" "Bubblemon-macOS-Release/"
    else
        echo_warning "Bubblemon.app (Dock version) not found, skipping"
    fi
    
    # Copy documentation
    cp ../README.md "Bubblemon-macOS-Release/" 2>/dev/null || echo_warning "README.md not found"
    cp ../COPYING "Bubblemon-macOS-Release/" 2>/dev/null || echo_warning "COPYING not found"
    
    # Create installation instructions
    cat > "Bubblemon-macOS-Release/INSTALL.txt" << EOF
Bubblemon for macOS - Installation Instructions

1. Extract this archive to a temporary location
2. Copy the desired application(s) to your Applications folder:
   - Bubblemon Menu Bar.app - System monitor in menu bar
   - Bubblemon.app - System monitor in dock (if included)
3. Launch the application
4. The system monitor will appear in your menu bar or dock

System Requirements:
- macOS 10.13 or later
- Apple Silicon recommended (ARM64 native build)

For support and source code, visit:
https://github.com/$REPO_OWNER/$REPO_NAME
EOF
    
    # Create archive
    rm -f "$ARCHIVE_NAME"
    tar -czf "$ARCHIVE_NAME" Bubblemon-macOS-Release/
    
    echo_success "Archive created: $ARCHIVE_NAME ($(du -h "$ARCHIVE_NAME" | cut -f1))"
    cd ..
}

# Create GitHub release
create_github_release() {
    echo_info "Creating GitHub release: $VERSION"
    
    # Create release notes
    RELEASE_NOTES=$(cat << EOF
# Bubblemon for macOS

Automated build of Bubblemon system monitor applications for macOS.

## What's included:
- **Bubblemon Menu Bar** - System monitor in your menu bar with animated bubbles
- **Bubblemon Dock** - System monitor in your dock (if available)

## System Requirements:
- macOS 10.13 or later  
- Apple Silicon (ARM64) native build

## Installation:
1. Download \`$ARCHIVE_NAME\`
2. Extract the archive
3. Copy the desired app(s) to your Applications folder
4. Launch the app - it will show animated bubbles representing CPU and memory usage

## Features:
- Real-time CPU usage monitoring with animated bubbles
- Memory usage visualization
- Native Apple Silicon performance
- Lightweight and efficient

## Build Information:
- **Commit**: $(git rev-parse HEAD)
- **Date**: $(date +'%Y-%m-%d %H:%M:%S UTC')
- **Architecture**: ARM64 (Apple Silicon native)
- **C Standard**: GNU99

---
*For more information and source code, visit the repository.*
EOF
)

    # Create the release
    if [ "$IS_PRERELEASE" = "true" ]; then
        gh release create "$VERSION" \
            "$BUILD_DIR/$ARCHIVE_NAME" \
            --title "Bubblemon macOS $VERSION" \
            --notes "$RELEASE_NOTES" \
            --prerelease
    else
        gh release create "$VERSION" \
            "$BUILD_DIR/$ARCHIVE_NAME" \
            --title "Bubblemon macOS $VERSION" \
            --notes "$RELEASE_NOTES"
    fi
    
    echo_success "Release created successfully!"
    echo_info "Release URL: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$VERSION"
}

# Main execution
main() {
    echo_info "Starting Bubblemon macOS release creation..."
    echo_info "Repository: $REPO_OWNER/$REPO_NAME"
    
    check_requirements
    get_version
    create_archive
    create_github_release
    
    echo_success "Release process completed!"
    echo_info "Users can now download the release from GitHub"
}

# Show usage if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
Bubblemon macOS Release Creator

This script creates a GitHub release with built Bubblemon applications.

Usage: $0 [options]

Prerequisites:
1. Build the applications first: ./build_ci.sh
2. Install GitHub CLI: brew install gh  
3. Authenticate: gh auth login

Options:
  -h, --help    Show this help message

The script will:
1. Check that applications are built
2. Create a release archive with all built apps
3. Generate version from git tag or current date+commit
4. Create GitHub release with the archive
5. Upload the archive as a release asset

Version Detection:
- If current commit has a git tag: uses the tag as version
- Otherwise: generates version like v2024.01.15-abc1234

Examples:
  $0                    # Create release with auto-detected version
  git tag v1.0.0 && $0  # Create release with version v1.0.0
EOF
    exit 0
fi

# Run main function
main