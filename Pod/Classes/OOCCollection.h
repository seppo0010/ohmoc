//
//  OOCCollection.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>

@protocol OOCCollection <NSObject>
@end

@class OOCModel;
@class OOCList;
@interface OOCCollection : NSObject <NSFastEnumeration> {
    NSMutableArray* objects;
    NSString* _key;
    void(^_block)(void(^)(NSString*));
}

// collections behave either like a set, a list or an array of ids
// if there are ids, we should use that
// if the class is OOCList use key and list commands
// if the class is OOCSet use key and set commands
@property NSArray* ids;

// key or {model and propertyName} may be set
// {model and propertyName} will be used to generate the key if absent
@property (weak) OOCModel* model;
@property NSString* propertyName;
@property NSString* key;
@property NSUInteger ns;
@property (strong) Class modelClass;

@property (strong) void(^block)(void(^)(NSString*));


+ (instancetype)collectionWithBlock:(void(^)(void(^)(NSString*)))block namespace:(NSUInteger)ns modelClass:(Class)modelClass;
+ (instancetype)collectionWithIds:(NSArray*)ids namespace:(NSUInteger)ns modelClass:(Class)model;
+ (instancetype)collectionWithKey:(NSString*)key namespace:(NSUInteger)ns modelClass:(Class)model;
+ (instancetype)collectionWithModel:(OOCModel*)model property:(NSString*)propertyName namespace:(NSUInteger)ns modelClass:(Class)modelClass;
- (BOOL) isEmpty;
- (NSArray*)arrayValue;
- (NSUInteger) size;
- (BOOL) contains:(OOCModel*)model;
- (void) blockWithKey:(void(^)(NSString*))localblock;
- (id<NSFastEnumeration>) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (OOCList*) sortBy:(NSString*)by limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (OOCList*) sortBy:(NSString*)by;

@end