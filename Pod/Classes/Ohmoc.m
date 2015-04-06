//
//  Ohm.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "Ohmoc.h"
#import "ObjCHirlite.h"

@implementation Ohmoc

@synthesize rlite = _rlite;

static NSMutableDictionary* threadToInstance = nil;

+ (id) create {
    return [[self alloc] init];
}

+ (Ohmoc*) instance {
    NSThread* thread = [NSThread currentThread];
    NSString* threadId = [NSString stringWithFormat:@"%p", thread];
    Ohmoc* instance = [threadToInstance valueForKey:threadId];
    if (!instance) {
        [NSException raise:@"NoOhmoc" format:@"Ohmoc not started on thread %@", threadId];
    }
    if (!instance.rlite) {
        [NSException raise:@"rliteMissing" format:@"rlite not started on thread %@", threadId];
    }
    return instance;
}

- (void) _init {
    if (!threadToInstance) {
        threadToInstance = [NSMutableDictionary dictionaryWithCapacity:1];
    }

    NSThread* thread = [NSThread currentThread];
    NSString* threadId = [NSString stringWithFormat:@"%p", thread];
    if ([threadToInstance valueForKey:threadId]) {
        [NSException raise:@"TooManyOhmoc" format:@"There is already an Ohmoc instance running in thread %@", threadId];
    }

    if (path) {
        _rlite = [[ObjCHirlite alloc] initWithPath:path];
    } else {
        _rlite = [[ObjCHirlite alloc] init];
    }

    [threadToInstance setValue:self forKey:threadId];
}

- (id) init {
    if (self = [super init]) {
        [self _init];
    }
    return self;
}
- (id) initWithPath:(NSString*)_path {
    if (self = [super init]) {
        path = _path;
        [self _init];
    }
    return self;
}

- (id) initWithDocumentFilename:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [self initWithPath:[basePath stringByAppendingPathComponent:filename]];
}

- (NSString*)tmpKey {
    return [NSString stringWithFormat:@"tmp%ld", tmpkey++];
}

- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    NSMutableArray* args = [NSMutableArray array];
    if (by) {
        [args addObjectsFromArray:@[@"BY", by]];
    }
    if (get) {
        [args addObjectsFromArray:@[@"GET", get]];
    }
    if (limit) {
        [args addObjectsFromArray:@[@"LIMIT", [NSString stringWithFormat:@"%lu", (long unsigned)offset], [NSString stringWithFormat:@"%lu", (long unsigned)limit]]];
    }
    if (order) {
        [args addObjectsFromArray:[order componentsSeparatedByString:@" "]];
    }
    if (store) {
        [args addObjectsFromArray:@[@"STORE", store]];
    }
    return [args copy];
}

- (void) flush {
    [self command:@[@"FLUSHDB"]];
}

- (id)command:(NSArray*)command {
    id retval = [_rlite command:command];
    if ([retval isKindOfClass:[NSException class]]) {
        NSException* exc = retval;
        if ([exc.reason rangeOfString:@"UniqueIndexViolation"].length != 0) {
            [[[OOCUniqueIndexViolationException alloc] initWithName:exc.name reason:exc.reason userInfo:exc.userInfo] raise];
        }
        [exc raise];
    }
    return retval;
}

- (BOOL)exists:(NSString*)id model:(Class)modelClass {
    return [[self command:@[@"SISMEMBER", [@[NSStringFromClass(modelClass), @"all"] componentsJoinedByString:@":"], id]] boolValue];
}

- (OOCModel*)get:(NSString*)id model:(Class)modelClass {
    if (!id) {
        return nil;
    }
    OOCModel* model = [modelClass getCached:id];
    if (!model && id && [self exists:id model:modelClass]) {
        model = [[modelClass alloc] initWithId:id ohmoc:self];
        [model load];
    }
    return model;
}

- (OOCModel*) with:(NSString*)att value:(NSString*)value model:(Class)modelClass {
    OOCModelProperty* property = [[[modelClass spec] properties] valueForKey:att];
    if (!property.hasIndex) {
        [OOCIndexNotFoundException raise:@"IndexNotFound" format:@"Index not found: '%@'", att];
    }
    NSString* _id = [self command:@[@"HGET", [@[NSStringFromClass(modelClass), @"uniques", att] componentsJoinedByString:@":"], [modelClass stringForIndex:att value:value]]];
    if (_id) {
        OOCModel* model = [[OOCModel alloc] initWithId:_id ohmoc:self];
        [model load];
        return model;
    }
    return nil;
}

- (OOCSet*) find:(NSDictionary*)dict model:(Class)modelClass {
    NSArray* filters = [modelClass filters:dict];
    if (filters.count == 1) {
        return [OOCSet collectionWithKey:[filters objectAtIndex:0] ohmoc:self modelClass:modelClass];
    } else {
        return [OOCSet collectionWithBlock:^(void(^block)(NSString*)) {
            Ohmoc* ohmoc = self;
            NSString* key = [ohmoc tmpKey];
            NSMutableArray* sunionCommand = [@[@"SINTERSTORE", key] mutableCopy];
            [sunionCommand addObjectsFromArray:filters];
            [ohmoc command:sunionCommand];
            block(key);
            [ohmoc command:@[@"DEL", key]];
        } ohmoc:self modelClass:modelClass];
    }
}

- (OOCModel*) with:(NSString*)att is:(id)value model:(Class)modelClass {
    if (![[modelClass spec].uniques containsObject:att]) {
        [OOCIndexNotFoundException raise:@"IndexNotFound" format:@"Index not found: '%@'", att];
    }

    NSString* id = [self command:@[@"HGET", [@[NSStringFromClass(modelClass), @"uniques", att] componentsJoinedByString:@":"], [modelClass stringForIndex:att value:value]]];
    if ([id isKindOfClass:[NSString class]]) {
        return [self get:id model:modelClass];
    }
    return nil;
}

- (OOCSet*)allModels:(Class)modelClass {
    return [OOCSet collectionWithKey:[@[NSStringFromClass(modelClass), @"all"] componentsJoinedByString:@":"] ohmoc:self modelClass:modelClass];
}

- (OOCCollection*)fetch:(NSArray*)ids model:(Class)modelClass {
    return [OOCCollection collectionWithIds:ids ohmoc:self modelClass:modelClass];
}

- (OOCModel*)createModel:(Class)modelClass {
    id instance = [[modelClass alloc] initWithOhmoc:self];
    [instance save];
    return instance;
}

- (OOCModel*)create:(NSDictionary*)properties model:(Class)modelClass {
    id instance = [[modelClass alloc] initWithDictionary:properties ohmoc:self];
    [instance save];
    return instance;
}

- (OOCModel*)getCached:(NSString*)id model:(Class)modelClass {
    NSString* cacheKey = [@[NSStringFromClass(modelClass), id] componentsJoinedByString:@":"];
    return [cache valueForKey:cacheKey];
}

- (BOOL)isCached:(NSString*)id model:(Class)modelClass {
    return !![self getCached:id model:modelClass];
}

- (void)setCached:(OOCModel*)model {
    if (!cache) {
        cache = (NSMutableDictionary*)CFBridgingRelease(CFDictionaryCreateMutable(nil, 0, &kCFCopyStringDictionaryKeyCallBacks, NULL));
    }
    NSString* cacheKey = [@[NSStringFromClass(model.class), model.id] componentsJoinedByString:@":"];
    [cache setValue:model forKey:cacheKey];
}

- (void)removeCached:(OOCModel*)model {
    NSString* cacheKey = [@[NSStringFromClass(model.class), model.id] componentsJoinedByString:@":"];
    [cache removeObjectForKey:cacheKey];
}

@end