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
+ (id) createWithDocumentFilename:(NSString*)filename;
+ (id) createWithPath:(NSString*)path;
+ (Ohmoc*) instance;

- (void) _init;
- (id) initAllowDuplicates:(BOOL)allowDuplicates;
- (id) initWithPath:(NSString*)_path allowDuplicates:(BOOL)allowDuplicates;
- (id) initWithPath:(NSString*)_path;
- (id) initWithDocumentFilename:(NSString*)filename allowDuplicates:(BOOL)allowDuplicates;
- (id) initWithDocumentFilename:(NSString*)filename;


- (OOCSet*) find:(NSDictionary*)dict model:(Class)modelClass;
- (id) with:(NSString*)property is:(id)value model:(Class)modelClass;
- (id)get:(NSString*)id model:(Class)modelClass;
- (id)createModel:(Class)modelClass;
- (id)create:(NSDictionary*)properties model:(Class)modelClass;
- (OOCSet*)allModels:(Class)modelClass;
- (id)getCached:(NSString*)id model:(Class)modelClass;
- (BOOL)isCached:(NSString*)id model:(Class)modelClass;
- (void)setCached:(OOCModel*)model;
- (void)removeCached:(OOCModel*)model;

- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
- (void) flush;
- (NSString*)tmpKey;
- (id)command:(NSArray*)command;
- (id)command:(NSArray*)command binary:(BOOL)binary;

@end