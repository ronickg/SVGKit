#!/bin/bash

# Build script for SVGKit Dynamic Framework XCFramework
# This script builds a dynamic framework with CocoaPods dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo "================================"
    echo "$1"
    echo "================================"
    echo ""
}

# Configuration
WORKSPACE="SVGKit-iOS.xcworkspace"
SCHEME="SVGKitFramework-iOS"
CONFIGURATION="Release"
BUILD_DIR="${PWD}/build-frameworks"
OUTPUT_DIR="${PWD}/build"
XCFRAMEWORK_NAME="SVGKit.xcframework"

print_section "Building SVGKit Dynamic Framework"

# Check if workspace exists
if [ ! -d "${WORKSPACE}" ]; then
    print_error "Workspace not found: ${WORKSPACE}"
    print_info "Make sure CocoaPods is installed and run 'pod install' first"
    exit 1
fi

# Clean previous builds
print_info "Cleaning previous builds..."
rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"

# Build for iOS Device (arm64)
print_section "Building for iOS Device (arm64)"
xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk iphoneos \
    -arch arm64 \
    build \
    SYMROOT="${BUILD_DIR}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    EXCLUDED_ARCHS="" \
    | grep -E "^\*\*|warning:|error:|note:" || true

if [ ! -f "${BUILD_DIR}/${CONFIGURATION}-iphoneos/SVGKit.framework/SVGKit" ]; then
    print_error "Device framework binary not created"
    exit 1
fi

print_success "Device framework built successfully"
lipo -info "${BUILD_DIR}/${CONFIGURATION}-iphoneos/SVGKit.framework/SVGKit"

# Build for iOS Simulator (x86_64 + arm64)
print_section "Building for iOS Simulator (x86_64 + arm64)"
xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk iphonesimulator \
    ARCHS="x86_64 arm64" \
    build \
    SYMROOT="${BUILD_DIR}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    EXCLUDED_ARCHS="" \
    ONLY_ACTIVE_ARCH=NO \
    | grep -E "^\*\*|warning:|error:|note:" || true

if [ ! -f "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/SVGKit.framework/SVGKit" ]; then
    print_error "Simulator framework binary not created"
    exit 1
fi

print_success "Simulator framework built successfully"
lipo -info "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/SVGKit.framework/SVGKit"

# Create XCFramework
print_section "Creating XCFramework"
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${CONFIGURATION}-iphoneos/SVGKit.framework" \
    -framework "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/SVGKit.framework" \
    -output "${BUILD_DIR}/${XCFRAMEWORK_NAME}"

print_success "XCFramework created successfully"

# Copy to output directory
print_info "Copying to output directory..."
mkdir -p "${OUTPUT_DIR}"
cp -R "${BUILD_DIR}/${XCFRAMEWORK_NAME}" "${OUTPUT_DIR}/"

# Summary
print_section "Build Summary"

print_info "XCFramework: ${OUTPUT_DIR}/${XCFRAMEWORK_NAME}"
echo ""
print_info "XCFramework structure:"
ls -lh "${OUTPUT_DIR}/${XCFRAMEWORK_NAME}"
echo ""

print_info "Device slice architectures:"
lipo -info "${OUTPUT_DIR}/${XCFRAMEWORK_NAME}/ios-arm64/SVGKit.framework/SVGKit"
echo ""

print_info "Simulator slice architectures:"
lipo -info "${OUTPUT_DIR}/${XCFRAMEWORK_NAME}/ios-arm64_x86_64-simulator/SVGKit.framework/SVGKit"
echo ""

print_info "Total size: $(du -sh ${OUTPUT_DIR}/${XCFRAMEWORK_NAME} | cut -f1)"
echo ""

# Verify macOS-only headers are guarded
print_info "Verifying macOS-only header guards..."
if grep -q "#if TARGET_OS_OSX" "${OUTPUT_DIR}/${XCFRAMEWORK_NAME}/ios-arm64/SVGKit.framework/Headers/SVGKit.h"; then
    print_success "✓ macOS-only headers are properly guarded"
else
    print_warning "⚠ macOS-only headers may not be guarded"
fi

print_section "✓ Build completed successfully!"

echo "To use in your project:"
echo "1. Drag ${XCFRAMEWORK_NAME} into your Xcode project"
echo "2. The framework will automatically link CocoaLumberjack"
echo "3. Import in Swift: import SVGKit"
echo "4. Import in Objective-C: #import <SVGKit/SVGKit.h>"
echo ""
echo "Note: This is a dynamic framework. Make sure it's embedded in your app bundle."
