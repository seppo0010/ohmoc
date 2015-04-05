//
//  OOCUser2.m
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCUser2.h"

@implementation OOCUser2

- (NSString*)provider {
    return [[self.email componentsSeparatedByString:@"@"] lastObject];
}

@end