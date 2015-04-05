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

- (NSString*)toKey:(NSString*)att {
    return [NSString stringWithFormat:@"%@:*->%@", NSStringFromClass(self.modelClass), att];
}

- (NSUInteger) size {
    __block NSUInteger size;
    [self blockWithKey:^(NSString* key) {
        size = [[Ohmoc command:@[@"SCARD", key]] unsignedIntegerValue];
    }];
    return size;
}

- (BOOL)containsId:(NSString*)id {
    __block BOOL contains;
    [self blockWithKey:^(NSString* key) {
        contains = [[Ohmoc command:@[@"SISMEMBER", key, id]] boolValue];
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
        ids = [Ohmoc command:@[@"SMEMBERS", key]];
    }];
    return ids;
}

- (id<NSFastEnumeration>) _sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    if (get) {
        get = [self toKey:get];
        NSMutableArray*  command = [NSMutableArray array];
        __block id<NSFastEnumeration> r;
        [self blockWithKey:^(NSString* mykey) {
            [command addObjectsFromArray:@[@"SORT", mykey]];
            [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:store]];
            r = [Ohmoc command:command];
        }];
        return r;
    } else {
        return [OOCList collectionWithBlock:^(void(^localblock)(NSString*)) {
            NSString* key = store;
            if (!store) {
                key = [Ohmoc tmpKey];
            }
            [self blockWithKey:^(NSString* mykey) {
                NSMutableArray* command = [NSMutableArray arrayWithObjects:@"SORT", mykey, nil];
                [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:key]];
                [Ohmoc command:command];
                localblock(key);
            }];
            if (!store) {
                [Ohmoc command:@[@"DEL", key]];
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

- (id<NSFastEnumeration>) sortBy:(NSString*)by {
    return [self sortBy:by get:nil limit:0 offset:0 order:nil store:nil];
}

- (OOCSet*)find:(NSDictionary*)dict {
    NSArray* filters = [self.modelClass filters:dict];
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        NSString* key = [Ohmoc tmpKey];
        NSMutableArray* command = [NSMutableArray arrayWithCapacity:filters.count + 2];
        [self blockWithKey:^(NSString* mykey) {
            [command addObjectsFromArray:@[@"SINTERSTORE", key, mykey]];
            [command addObjectsFromArray:filters];
            [Ohmoc command:command];
            localblock(key);
            [Ohmoc command:@[@"DEL", key]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)except:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [Ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SDIFFSTORE", key2, mykey, key1]];
            [Ohmoc command:sdiffCommand];
            localblock(key2);
            [Ohmoc command:@[@"DEL", key1, key2]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)combine:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [Ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SINTERSTORE", key2, mykey, key1]];
            [Ohmoc command:sdiffCommand];
            localblock(key2);
            [Ohmoc command:@[@"DEL", key1, key2]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)union:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        NSString* key1 = [Ohmoc tmpKey];
        NSString* key2 = [Ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SINTERSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [Ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SUNIONSTORE", key2, mykey, key1]];
            [Ohmoc command:sdiffCommand];
            localblock(key2);
        }];
        [Ohmoc command:@[@"DEL", key1, key2]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (id)firstBy:(NSString*)by get:(NSString*)get order:(NSString*)order {
    for (id obj in [self sortBy:@"fname" get:get limit:1 offset:0 order:order store:nil]) {
        return obj;
    }
    return nil;
}

- (id)firstBy:(NSString*)by order:(NSString*)order {
    return [self firstBy:by get:nil order:order];
}

- (id)first {
    return [self firstBy:nil order:nil];
}

- (NSString*)keyForProperty:(NSString*)propertyName {
    return [self.model indexForProperty:self.propertyName];
}

@end