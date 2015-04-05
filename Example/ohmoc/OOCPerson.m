//
//  OOCPerson.m
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCPerson.h"

@implementation OOCPerson

- (NSString<OOCIndex>*) initial {
    return (NSString<OOCIndex>*)[[self.name substringToIndex:1] uppercaseString];
}

@end