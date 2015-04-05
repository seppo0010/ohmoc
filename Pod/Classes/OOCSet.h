//
//  OOCSet.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCCollection.h"

@class OOCModel;
@interface OOCSet : OOCCollection

- (id)get:(NSString*)id;
- (id<NSFastEnumeration>) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (id<NSFastEnumeration>) sortBy:(NSString*)by;
- (OOCSet*)find:(NSDictionary*)dict;
- (OOCSet*)except:(NSDictionary*)dict;
- (OOCSet*)combine:(NSDictionary*)dict;
- (OOCSet*)union:(NSDictionary*)dict;
- (id)first;
- (id)firstBy:(NSString*)by get:(NSString*)get order:(NSString*)order;
- (id)firstBy:(NSString*)by order:(NSString*)order;


@end
