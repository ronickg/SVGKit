/**
SVGKDefine_Private.h

SVGKDefine define some common macro used for private header.
*/

#ifndef SVGKDefine_Private_h
#define SVGKDefine_Private_h

#import "SVGKDefine.h"

// These macro is only used inside framework project, does not expose to public header and effect user's define

// Logging macros - using NSLog for errors/warnings, no-op for debug/verbose
#if DEBUG
    #define SVGKitLogError(frmt, ...)   NSLog(@"[SVGKit ERROR] %s: " frmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
    #define SVGKitLogWarn(frmt, ...)    NSLog(@"[SVGKit WARN] %s: " frmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
    #define SVGKitLogInfo(frmt, ...)    NSLog(@"[SVGKit INFO] " frmt, ##__VA_ARGS__)
    #define SVGKitLogDebug(frmt, ...)   NSLog(@"[SVGKit DEBUG] " frmt, ##__VA_ARGS__)
    #define SVGKitLogVerbose(frmt, ...) // Verbose logs disabled
#else
    #define SVGKitLogError(frmt, ...)   NSLog(@"[SVGKit ERROR] %s: " frmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
    #define SVGKitLogWarn(frmt, ...)    NSLog(@"[SVGKit WARN] %s: " frmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
    #define SVGKitLogInfo(frmt, ...)    // Info logs disabled in release
    #define SVGKitLogDebug(frmt, ...)   // Debug logs disabled in release
    #define SVGKitLogVerbose(frmt, ...) // Verbose logs disabled in release
#endif

#if SVGKIT_MAC
#define NSStringFromCGRect(rect) NSStringFromRect(rect)
#define NSStringFromCGSize(size) NSStringFromSize(size)
#define NSStringFromCGPoint(point) NSStringFromPoint(point)
#endif

#endif /* SVGKDefine_Private_h */
