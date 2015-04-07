//
//  OOCUser.m
//  ohmoc
//
//  Created by Seppo on 4/2/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCUser.h"

@implementation OOCUser

- (NSString<OOCIndex>*)emailProvider {
    return [[self.email componentsSeparatedByString:@"@"] lastObject];
}

- (void) save {
    if (!_activationCode) {
        self.activationCode = [NSString stringWithFormat:@"user:%@", self.id];
    }
    [super save];
}

@end