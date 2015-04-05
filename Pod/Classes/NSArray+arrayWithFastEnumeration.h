//
//  NSArray+arrayWithFastEnumeration.h
//  Pods
//
//  Created by Seppo on 4/5/15.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (arrayWithFastEnumeration)

+ (instancetype)arrayWithFastEnumeration:(id<NSFastEnumeration>)enumeration;

@end