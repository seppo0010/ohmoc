//
//  NSArray+arrayWithFastEnumeration.m
//  Pods
//
//  Created by Seppo on 4/5/15.
//
//

#import "NSArray+arrayWithFastEnumeration.h"

@implementation NSArray (arrayWithFastEnumeration)

+ (instancetype)arrayWithFastEnumeration:(id<NSFastEnumeration>)enumeration {
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:0];
    for (id obj in enumeration) {
        [arr addObject:obj];
    }
    return [self arrayWithArray:arr];
}

@end
