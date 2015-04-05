//
//  OOCModel.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCUnique.h"

@class OOCCollection;
@class OOCSet;
@interface OOCModel : NSObject

@property NSString<OOCUnique>* id;

- (NSString*)indexForProperty:(NSString*)property;
- (NSString*)listForProperty:(NSString*)property;
+ (NSArray*) filters:(NSDictionary*)filters;
+ (OOCSet*) find:(NSDictionary*)dict;
+ (instancetype)get:(NSString*)id;
+ (instancetype)create:(NSDictionary*)properties;
+ (OOCSet*)all;
+ (BOOL)isCached:(NSString*)id;
- (void) save;

@end