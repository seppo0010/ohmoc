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

@property (strong) void(^block)(void(^)(NSString*));

+ (instancetype)setWithBlock:(void(^)(void(^)(NSString*)))block namespace:(NSUInteger)ns modelClass:(Class)modelClass;
- (id)get:(NSString*)id;
- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (OOCCollection*)find:(NSDictionary*)dict;
- (OOCCollection*)except:(NSDictionary*)dict;

@end
