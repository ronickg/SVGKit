#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="SVGKit-iOS"
TARGET_NAME="SVGKit-iOS"
LIBRARY_NAME="libSVGKit-iOS.2.1.0.a"
XCFRAMEWORK_NAME="SVGKit.xcframework"
CONFIGURATION="Debug" # Change to "Release" for release builds
MIN_IOS_VERSION="12.0"

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/build"
XCFRAMEWORK_OUTPUT="${BUILD_DIR}/${XCFRAMEWORK_NAME}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}SVGKit XCFramework Build Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean build directory
clean() {
    print_info "Cleaning previous builds..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
}

# Function to build for a specific SDK
build_for_sdk() {
    local SDK="$1"
    local OUTPUT_DIR="${BUILD_DIR}/${CONFIGURATION}-${SDK}"

    print_info "Building for ${SDK}..."

    # Prevent the build script from recursing by setting ALREADYINVOKED
    export ALREADYINVOKED="true"

    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -target "${TARGET_NAME}" \
        -configuration "${CONFIGURATION}" \
        -sdk "${SDK}" \
        EXCLUDED_ARCHS="" \
        IPHONEOS_DEPLOYMENT_TARGET="${MIN_IOS_VERSION}" \
        BUILD_DIR="${BUILD_DIR}" \
        SYMROOT="${BUILD_DIR}" \
        OBJROOT="${BUILD_DIR}/Intermediates" \
        ONLY_ACTIVE_ARCH=NO \
        build \
        | grep -E "error:|warning:|Building|Libtool|PhaseScriptExecution" || true

    if [ ! -f "${OUTPUT_DIR}/${LIBRARY_NAME}" ]; then
        print_error "Build failed for ${SDK}! Library not found at ${OUTPUT_DIR}/${LIBRARY_NAME}"
        exit 1
    fi

    print_info "✓ Successfully built for ${SDK}"
}

# Function to verify library architectures
verify_architectures() {
    local LIBRARY_PATH="$1"
    local EXPECTED_ARCHS="$2"

    print_info "Verifying architectures in $(basename ${LIBRARY_PATH})..."
    lipo -info "${LIBRARY_PATH}"
}

# Function to create XCFramework
create_xcframework() {
    print_info "Creating XCFramework..."

    local DEVICE_LIB="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${LIBRARY_NAME}"
    local SIMULATOR_LIB="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${LIBRARY_NAME}"
    local DEVICE_HEADERS="${BUILD_DIR}/${CONFIGURATION}-iphoneos/usr/local/include"
    local SIMULATOR_HEADERS="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/usr/local/include"

    # Verify both libraries exist
    if [ ! -f "${DEVICE_LIB}" ]; then
        print_error "Device library not found at ${DEVICE_LIB}"
        exit 1
    fi

    if [ ! -f "${SIMULATOR_LIB}" ]; then
        print_error "Simulator library not found at ${SIMULATOR_LIB}"
        exit 1
    fi

    # Verify headers exist
    if [ ! -d "${DEVICE_HEADERS}" ]; then
        print_error "Device headers not found at ${DEVICE_HEADERS}"
        exit 1
    fi

    # Remove existing XCFramework
    rm -rf "${XCFRAMEWORK_OUTPUT}"

    # Create XCFramework
    xcodebuild -create-xcframework \
        -library "${DEVICE_LIB}" \
        -headers "${DEVICE_HEADERS}" \
        -library "${SIMULATOR_LIB}" \
        -headers "${SIMULATOR_HEADERS}" \
        -output "${XCFRAMEWORK_OUTPUT}"

    if [ ! -d "${XCFRAMEWORK_OUTPUT}" ]; then
        print_error "Failed to create XCFramework!"
        exit 1
    fi

    print_info "✓ Successfully created XCFramework"
}

# Function to display build summary
show_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Build Summary${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""

    print_info "XCFramework: ${XCFRAMEWORK_OUTPUT}"
    echo ""

    # Show XCFramework structure
    print_info "XCFramework structure:"
    ls -lh "${XCFRAMEWORK_OUTPUT}"
    echo ""

    # Show architectures for each slice
    print_info "Device slice architectures:"
    lipo -info "${XCFRAMEWORK_OUTPUT}/ios-arm64/${LIBRARY_NAME}"
    echo ""

    print_info "Simulator slice architectures:"
    lipo -info "${XCFRAMEWORK_OUTPUT}/ios-arm64_x86_64-simulator/${LIBRARY_NAME}"
    echo ""

    # Show total size
    local TOTAL_SIZE=$(du -sh "${XCFRAMEWORK_OUTPUT}" | cut -f1)
    print_info "Total size: ${TOTAL_SIZE}"
    echo ""

    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "To use in your project:"
    echo "1. Drag ${XCFRAMEWORK_NAME} into your Xcode project"
    echo "2. Add '-ObjC' to Other Linker Flags"
    echo "3. Link required frameworks: CoreText, CoreImage, libxml2, QuartzCore, CoreGraphics, UIKit"
    echo ""
}

# Main build process
main() {
    # Check if we're in the correct directory
    if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
        print_error "Could not find ${PROJECT_NAME}.xcodeproj in current directory!"
        print_error "Please run this script from the SVGKit root directory."
        exit 1
    fi

    # Clean previous builds
    clean

    # Build for iOS device
    build_for_sdk "iphoneos"

    # Build for iOS simulator
    build_for_sdk "iphonesimulator"

    # Verify architectures
    verify_architectures "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${LIBRARY_NAME}" "arm64"
    verify_architectures "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${LIBRARY_NAME}" "arm64 x86_64"

    # Create XCFramework
    create_xcframework

    # Show summary
    show_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            CONFIGURATION="Release"
            print_info "Building in Release configuration"
            shift
            ;;
        --clean-only)
            clean
            print_info "Clean completed"
            exit 0
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --release      Build in Release configuration (default: Debug)"
            echo "  --clean-only   Clean build directory and exit"
            echo "  --help         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main build process
main
