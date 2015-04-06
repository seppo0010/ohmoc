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

- (NSUInteger) size {
    __block NSUInteger size;
    [self blockWithKey:^(NSString* key) {
        size = [[[Ohmoc instance] command:@[@"SCARD", key]] unsignedIntegerValue];
    }];
    return size;
}

- (BOOL)containsId:(NSString*)id {
    __block BOOL contains;
    [self blockWithKey:^(NSString* key) {
        contains = [[[Ohmoc instance] command:@[@"SISMEMBER", key, id]] boolValue];
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
        ids = [[Ohmoc instance] command:@[@"SMEMBERS", key]];
    }];
    return ids;
}

- (OOCSet*)find:(NSDictionary*)dict {
    NSArray* filters = [self.modelClass filters:dict];
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        Ohmoc* ohmoc = [Ohmoc instance];
        NSString* key = [ohmoc tmpKey];
        NSMutableArray* command = [NSMutableArray arrayWithCapacity:filters.count + 2];
        [self blockWithKey:^(NSString* mykey) {
            [command addObjectsFromArray:@[@"SINTERSTORE", key, mykey]];
            [command addObjectsFromArray:filters];
            [ohmoc command:command];
            localblock(key);
            [ohmoc command:@[@"DEL", key]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)except:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        Ohmoc* ohmoc = [Ohmoc instance];
        NSString* key1 = [ohmoc tmpKey];
        NSString* key2 = [ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SDIFFSTORE", key2, mykey, key1]];
            [ohmoc command:sdiffCommand];
            localblock(key2);
            [ohmoc command:@[@"DEL", key1, key2]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)combine:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        Ohmoc* ohmoc = [Ohmoc instance];
        NSString* key1 = [ohmoc tmpKey];
        NSString* key2 = [ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SUNIONSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SINTERSTORE", key2, mykey, key1]];
            [ohmoc command:sdiffCommand];
            localblock(key2);
            [ohmoc command:@[@"DEL", key1, key2]];
        }];
    } namespace:self.ns modelClass:self.modelClass];
}

- (OOCSet*)union:(NSDictionary*)dict {
    return [OOCSet collectionWithBlock:^(void(^localblock)(NSString*)) {
        Ohmoc* ohmoc = [Ohmoc instance];
        NSString* key1 = [ohmoc tmpKey];
        NSString* key2 = [ohmoc tmpKey];
        NSMutableArray* sunionCommand = [@[@"SINTERSTORE", key1] mutableCopy];
        [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
        [ohmoc command:sunionCommand];
        NSMutableArray* sdiffCommand = [NSMutableArray arrayWithCapacity:4];
        [self blockWithKey:^(NSString* mykey) {
            [sdiffCommand addObjectsFromArray:@[@"SUNIONSTORE", key2, mykey, key1]];
            [ohmoc command:sdiffCommand];
            localblock(key2);
        }];
        [ohmoc command:@[@"DEL", key1, key2]];
    } namespace:self.ns modelClass:self.modelClass];
}

- (id)firstBy:(NSString*)by get:(NSString*)get order:(NSString*)order {
    for (id obj in [self sortBy:by get:get limit:1 offset:0 order:order store:nil]) {
        return obj;
    }
    return nil;
}

- (id)firstBy:(NSString*)by order:(NSString*)order {
    return [self firstBy:by get:nil order:order];
}

- (id)first {
    return [self firstBy:@"id" order:nil];
}

- (NSString*)keyForProperty:(NSString*)propertyName {
    return [self.model indexForProperty:self.propertyName];
}

@end