//
//  OOCNode.m
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCNode.h"

@implementation OOCNode

- (BOOL) available {
    return self.capacity <= 90;
}

@end