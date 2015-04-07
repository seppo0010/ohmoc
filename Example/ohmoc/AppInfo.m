//
//  AppInfo.m
//  ohmoc
//
//  Created by Seppo on 4/7/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "AppInfo.h"

@implementation AppInfo

+ (void) registerEvent:(NSString*)name {
    AppInfo* appInfo = [[self all] first];
    if (!appInfo) {
        appInfo = [AppInfo create];
    }
    [appInfo.events unshift:[AppEvent create:@{@"name": name, @"date": [NSDate date]}]];
}

@end