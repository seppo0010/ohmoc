//
//  OOCSet.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCSet.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"
#import "OOCModel.h"

@implementation OOCSet

+ (instancetype)setWithBlock:(void(^)(void(^)(NSString*)))block namespace:(NSUInteger)ns modelClass:(Class)modelClass {
    OOCSet* set = [[self alloc] init];
    set.block = block;
    set.ns = ns;
    set.modelClass = modelClass;
    return set;
}

- (ObjCHirlite*)conn {
    return [Ohmoc rlite];
}

- (NSString*)toKey:(NSString*)att {
    if ([[self.modelClass counters] valueForKey:att]) {
        return [NSString stringWithFormat:@"*:counters->%@", att];
    } else {
        return [NSString stringWithFormat:@"*->%@", att];
    }
}

- (NSUInteger) size {
    __block NSUInteger size;
    [self blockWithKey:^(NSString* key) {
        size = [[[self conn] command:@[@"SCARD", key]] unsignedIntegerValue];
    }];
    return size;
}

- (BOOL)containsId:(NSString*)id {
    __block BOOL contains;
    [self blockWithKey:^(NSString* key) {
        contains = [[[self conn] command:@[@"SISMEMBER", key, id]] boolValue];
    }];
    return contains;
}

- (BOOL)contains:(OOCModel*)submodel {
    return [self containsId:submodel.id];
}

- (OOCModel*)get:(NSString*)id {
    if ([self containsId:id]) {
        return [self.modelClass get:id];
    }
    return nil;
}

- (NSArray*)ids {
    __block NSArray* ids;
    [self blockWithKey:^(NSString* key) {
        ids = [[self conn] command:@[@"SMEMBERS", key]];
    }];
    return ids;
}

- (id<NSFastEnumeration>) _sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    if (get) {
        get = [self toKey:get];
        NSMutableArray* command = [NSMutableArray arrayWithObjects:@"SORT", self.key, nil];
        [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:store]];
        return [[self conn] command:command];
    } else {
        return [OOCSet setWithBlock:^(void(^localblock)(NSString*)) {
            ObjCHirlite* conn = [self conn];
            NSString* key = store;
            if (!store) {
                key = [Ohmoc tmpKey];
            }
            NSMutableArray* command = [NSMutableArray arrayWithObjects:@"SORT", self.key, nil];
            [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:key]];
            [conn command:command];
            localblock(key);
            if (!store) {
                [conn command:@[@"DEL", key]];
            }
        } namespace:self.ns modelClass:self.modelClass];
    }
}

- (id<NSFastEnumeration>) sort:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:nil get:get limit:limit offset:offset order:order store:store];
}

- (id<NSFastEnumeration>) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:[self toKey:by] get:get limit:limit offset:offset order:order store:store];
}

- (OOCSet*)find:(NSDictionary*)dict {
    NSArray* filters = [self.modelClass filters:dict];
    return [OOCSet setWithBlock:^(void(^localblock)(NSString*)) {
        ObjCHirlite* conn = [self conn];
        NSString* key = [Ohmoc tmpKey];
        NSMutableArray* command = [NSMutableArray arrayWithCapacity:filters.count + 2];
        [command addObjectsFromArray:@[@"SINTERSTORE", key, self.key]];
        [command addObjectsFromArray:filters];
        [conn command:command];
        localblock(key);
        [conn command:@[@"DEL", key]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)except:(NSDictionary*)dict {
    return [OOCSet setWithBlock:^(void(^localblock)(NSString*)) {
        ObjCHirlite* conn = [self conn];
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [conn command:sunionCommand];
        NSArray* sdiffCommand = @[@"SDIFFSTORE", key2, self.key, key1];
        [conn command:sdiffCommand];
        localblock(key2);
        [conn command:@[@"DEL", key1, key2]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCCollection*)combine:(NSDictionary*)dict {
    return [OOCSet setWithBlock:^(void(^localblock)(NSString*)) {
        ObjCHirlite* conn = [self conn];
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [conn command:sunionCommand];
        NSArray* sdiffCommand = @[@"SINTERSTORE", key2, self.key, key1];
        [conn command:sdiffCommand];
        localblock(key2);
        [conn command:@[@"DEL", key1, key2]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCCollection*)union:(NSDictionary*)dict {
    return [OOCSet setWithBlock:^(void(^localblock)(NSString*)) {
        ObjCHirlite* conn = [self conn];
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SINTERSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [conn command:sunionCommand];
        NSArray* sdiffCommand = @[@"SUNIONSTORE", key2, self.key, key1];
        [conn command:sdiffCommand];
        localblock(key2);
        [conn command:@[@"DEL", key1, key2]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (void)setKey:(NSString *)key {
    _key = key;
}

- (NSString*)key {
    if (_key) {
        return _key;
    }
    return [self.model indexForProperty:self.propertyName];
}

- (void) blockWithKey:(void(^)(NSString*))localblock {
    if (_block) {
        _block(localblock);
        return;
    }
    localblock(self.key);
}

@end