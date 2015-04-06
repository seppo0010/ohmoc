//
//  OOCObject.m
//  Pods
//
//  Created by Seppo on 4/6/15.
//
//

#import "OOCObject.h"

@implementation OOCObject

- (instancetype) initWithOhmoc:(Ohmoc*)ohmoc {
    if (self = [self init]) {
        self.ohmoc = ohmoc;
    }
    return self;
}

@end