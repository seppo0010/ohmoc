//
//  Ohm.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCException.h"
#import "OOCIndexNotFoundException.h"
#import "OOCMissingIDException.h"
#import "OOCUniqueIndexViolationException.h"
#import "OOCModel.h"
#import "OOCCollection.h"
#import "OOCSet.h"
#import "OOCMutableSet.h"
#import "OOCList.h"
#import "OOCIndex.h"

@class ObjCHirlite;
@interface Ohmoc : NSObject {
    NSString* path;
    ObjCHirlite* _rlite;
    long tmpkey;

    NSMutableDictionary* cache;
}

@property (readonly) ObjCHirlite* rlite;

+ (id) create;
+ (Ohmoc*) instance;

- (OOCSet*) find:(NSDictionary*)dict model:(Class)modelClass;
- (OOCModel*) with:(NSString*)property is:(id)value model:(Class)modelClass;
- (OOCModel*)get:(NSString*)id model:(Class)modelClass;
- (OOCModel*)createModel:(Class)modelClass;
- (OOCModel*)create:(NSDictionary*)properties model:(Class)modelClass;
- (OOCSet*)allModels:(Class)modelClass;
- (OOCModel*)getCached:(NSString*)id model:(Class)modelClass;
- (BOOL)isCached:(NSString*)id model:(Class)modelClass;
- (void)setCached:(OOCModel*)model;
- (void)removeCached:(OOCModel*)model;

- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (void) flush;
- (NSString*)tmpKey;
- (id)command:(NSArray*)command;

@end