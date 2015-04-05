//
//  OOCEvent.m
//  ohmoc
//
//  Created by Seppo on 4/3/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCEvent.h"

@implementation OOCEvent

- (void) save {
    self.slug = [self.name lowercaseString];
    [super save];
}

@end
