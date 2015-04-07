//
//  OOCPost.m
//  ohmoc
//
//  Created by Seppo on 4/2/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCPost.h"

@implementation OOCPost

- (NSSet<OOCIndex>*) tag {
    return (NSSet<OOCIndex>*)[NSSet setWithArray:[self.tags componentsSeparatedByString:@" "]];
}

@end