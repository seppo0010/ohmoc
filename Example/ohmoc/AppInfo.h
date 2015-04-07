//
//  AppInfo.h
//  ohmoc
//
//  Created by Seppo on 4/7/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import <Ohmoc.h>
#import "AppEvent.h"

@interface AppInfo : OOCModel

@property OOCList<AppEvent>* events;

+ (void) registerEvent:(NSString*)name;

@end