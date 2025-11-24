# SVGKit XCFramework Build Instructions

## Quick Start

To build the XCFramework, simply run:

```bash
./build-xcframework.sh
```

This will create `build/SVGKit.xcframework` with support for:
- iOS devices (arm64)
- iOS Simulator on Intel Macs (x86_64)
- iOS Simulator on Apple Silicon Macs (arm64)

## Build Script Options

```bash
./build-xcframework.sh [options]
```

### Available Options

- `--release` - Build in Release configuration (default: Debug)
- `--clean-only` - Clean build directory and exit
- `--help` - Show help message

### Examples

Build in Release mode:
```bash
./build-xcframework.sh --release
```

Clean previous builds:
```bash
./build-xcframework.sh --clean-only
```

## Output

The script creates:
```
build/
└── SVGKit.xcframework/
    ├── Info.plist
    ├── ios-arm64/                          # For iOS devices
    │   ├── Headers/                        # 132 header files
    │   └── libSVGKit-iOS.2.1.0.a          # Device library (~6.5 MB)
    └── ios-arm64_x86_64-simulator/        # For iOS Simulator
        ├── Headers/                        # 132 header files
        └── libSVGKit-iOS.2.1.0.a          # Simulator library (~13 MB)
```

## Using the XCFramework in Your Project

### 1. Add to Xcode Project

Drag `SVGKit.xcframework` into your Xcode project.

### 2. Configure Build Settings

In your target's **Build Settings**:
- Add `-ObjC` to **Other Linker Flags**

### 3. Link Required Frameworks

In your target's **Build Phases** → **Link Binary with Libraries**, add:
- CoreText.framework
- CoreImage.framework
- libxml2.tbd
- QuartzCore.framework
- CoreGraphics.framework
- UIKit.framework

### 4. Start Using SVGKit

```objc
#import <SVGKit/SVGKit.h>

// Load and display an SVG
SVGKImage *image = [SVGKImage imageNamed:@"example.svg"];
SVGKFastImageView *imageView = [[SVGKFastImageView alloc] initWithSVGKImage:image];
[self.view addSubview:imageView];
```

## Requirements

- Xcode 12.0 or later
- macOS 10.15 or later
- Command Line Tools installed: `xcode-select --install`

## Troubleshooting

### Build fails with "database is locked" error

This happens when multiple builds run concurrently. The script sets `ALREADYINVOKED=true` to prevent this, but if you still encounter this:

1. Clean the build: `./build-xcframework.sh --clean-only`
2. Kill any running xcodebuild processes: `killall xcodebuild`
3. Try again: `./build-xcframework.sh`

### Missing architectures warning

If Xcode shows warnings about `EXCLUDED_ARCHS`, the script automatically overrides this with `EXCLUDED_ARCHS=""` to ensure all architectures are built.

### CocoaLumberjack errors

The project includes a fix for CocoaLumberjack compatibility in `Source/SVGKit.m` (line 22: `DDOSLogger` → `DDASLLogger`).

## Manual Build (Alternative)

If you prefer to build manually without the script:

### For Device (iphoneos):
```bash
export ALREADYINVOKED="true"
xcodebuild -project SVGKit-iOS.xcodeproj \
  -target SVGKit-iOS \
  -configuration Debug \
  -sdk iphoneos \
  EXCLUDED_ARCHS="" \
  build
```

### For Simulator (iphonesimulator):
```bash
export ALREADYINVOKED="true"
xcodebuild -project SVGKit-iOS.xcodeproj \
  -target SVGKit-iOS \
  -configuration Debug \
  -sdk iphonesimulator \
  EXCLUDED_ARCHS="" \
  build
```

### Create XCFramework:
```bash
xcodebuild -create-xcframework \
  -library build/Debug-iphoneos/libSVGKit-iOS.2.1.0.a \
  -headers build/Debug-iphoneos/usr/local/include \
  -library build/Debug-iphonesimulator/libSVGKit-iOS.2.1.0.a \
  -headers build/Debug-iphonesimulator/usr/local/include \
  -output build/SVGKit.xcframework
```

## Build Configuration

The build script uses the following defaults:

- **Configuration**: Debug (use `--release` for Release)
- **Minimum iOS Version**: 12.0
- **Project**: SVGKit-iOS.xcodeproj
- **Target**: SVGKit-iOS
- **Output**: build/SVGKit.xcframework

To customize these, edit the variables at the top of `build-xcframework.sh`.

## Additional Resources

- [SVGKit GitHub](https://github.com/SVGKit/SVGKit)
- [SVGKit Wiki](https://github.com/SVGKit/SVGKit/wiki)
- [Apple XCFramework Documentation](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle)
