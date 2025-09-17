#!/bin/bash

# Build script for Bubblemon macOS apps in CI/CD environment
# This script builds all three Bubblemon variants for ARM64

set -e  # Exit on any error

echo "INFO: Building Bubblemon for macOS ARM64 in CI environment..."

# Create required directories
echo "INFO: Creating required directories..."
mkdir -p build/include

# Function to build a target
build_target() {
    local target_name="$1"
    echo "INFO: Building $target_name..."
    
    xcodebuild build \
        -project osx/bubblemon.xcodeproj \
        -configuration Release \
        -target "$target_name" \
        -arch arm64 \
        CONFIGURATION_BUILD_DIR="$(pwd)/build" \
        ONLY_ACTIVE_ARCH=YES \
        VALID_ARCHS=arm64 \
        ARCHS=arm64 \
        GCC_C_LANGUAGE_STANDARD=gnu99 \
        CLANG_WARN_DECLARATION_AFTER_STATEMENT=NO \
        GCC_TREAT_WARNINGS_AS_ERRORS=NO
}

# Build all targets
echo "INFO: Building all Bubblemon targets..."

# Build Menu Bar app (priority target)
build_target "Bubblemon Menu Bar"

# Build Dock app (if it exists)
if xcodebuild -project osx/bubblemon.xcodeproj -list | grep -q "Bubblemon$"; then
    build_target "Bubblemon"
else
    echo "INFO: Bubblemon (Dock) target not found, skipping..."
fi


# Verify builds
echo "INFO: Verifying builds..."

if [ -f "build/Bubblemon Menu Bar.app/Contents/MacOS/Bubblemon Menu Bar" ]; then
    echo "SUCCESS: Bubblemon Menu Bar built successfully"
    file "build/Bubblemon Menu Bar.app/Contents/MacOS/Bubblemon Menu Bar"
else
    echo "ERROR: Bubblemon Menu Bar build failed!"
    exit 1
fi

if [ -f "build/Bubblemon.app/Contents/MacOS/Bubblemon" ]; then
    echo "SUCCESS: Bubblemon Dock built successfully"
    file "build/Bubblemon.app/Contents/MacOS/Bubblemon"
fi


echo "INFO: Build completed successfully!"