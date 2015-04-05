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
- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (OOCCollection*)find:(NSDictionary*)dict;
- (OOCCollection*)except:(NSDictionary*)dict;
- (id)firstBy:(NSString*)by get:(NSString*)get order:(NSString*)order;
- (id)firstBy:(NSString*)by order:(NSString*)order;


@end
