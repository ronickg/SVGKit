//
//  SVGKit.m
//  SVGKit-iOS
//
//  Created by Devon Blandin on 5/13/13.
//  Copyright (c) 2013 na. All rights reserved.
//

#import "SVGKit.h"

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#import <CocoaLumberjack/CocoaLumberjack.h>
#elif __has_include("CocoaLumberjack/CocoaLumberjack.h")
#import "CocoaLumberjack/CocoaLumberjack.h"
#endif

@implementation SVGKit : NSObject

+ (void) enableLogging {
#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>) || __has_include("CocoaLumberjack/CocoaLumberjack.h")
    #if TARGET_OS_IOS || TARGET_OS_TV
        [DDLog addLogger:[DDOSLogger sharedInstance]];
    #else
        [DDLog addLogger:[DDASLLogger sharedInstance]];
    #endif
#endif
}

@end
