//
//  SVGKit.m
//  SVGKit-iOS
//
//  Created by Devon Blandin on 5/13/13.
//  Copyright (c) 2013 na. All rights reserved.
//

#import "SVGKit.h"

@implementation SVGKit : NSObject

+ (void) enableLogging {
    // Logging is now always enabled in DEBUG mode via NSLog
    // See SVGKDefine_Private.h for logging macros
    NSLog(@"[SVGKit] Logging is enabled via NSLog");
}

@end
