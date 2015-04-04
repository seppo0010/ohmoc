//
//  OOCModel.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCUnique.h"

@class OOCSet;
@interface OOCModel : NSObject

@property NSString<OOCUnique>* id;

- (NSString*)indexForProperty:(NSString*)property;
- (NSString*)listForProperty:(NSString*)property;
+ (NSDictionary*) counters;
+ (NSArray*) filters:(NSDictionary*)filters;
+ (instancetype)get:(NSString*)id;
+ (instancetype)create:(NSDictionary*)properties;
+ (OOCSet*)all;
+ (BOOL)isCached:(NSString*)id;

@end