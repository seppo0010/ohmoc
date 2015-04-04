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
    return [[[self conn] command:@[@"SCARD", self.key]] unsignedIntegerValue];
}

- (BOOL)containsId:(NSString*)id {
    return [[[self conn] command:@[@"SISMEMBER", self.key, id]] boolValue];
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
    return [[self conn] command:@[@"SMEMBERS", self.key]];
}

- (id<NSFastEnumeration>) _sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    NSMutableArray* command = [NSMutableArray arrayWithObjects:@"SORT", self.key, nil];
    if (get) {
        get = [self toKey:get];
        [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:store]];
        return [[self conn] command:command];
    } else {
        [command addObjectsFromArray:[Ohmoc sortBy:by get:get limit:limit offset:offset order:order store:store]];
        return [OOCCollection collectionWithIds:[[self conn] command:command] namespace:self.ns modelClass:self.modelClass];
    }
}

- (id<NSFastEnumeration>) sort:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:nil get:get limit:limit offset:offset order:order store:store];
}

- (id<NSFastEnumeration>) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:[self toKey:by] get:get limit:limit offset:offset order:order store:store];
}

- (OOCCollection*)find:(NSDictionary*)dict {
    NSArray* filters = [self.modelClass filters:dict];
    NSMutableArray* command = [NSMutableArray arrayWithCapacity:filters.count + 2];
    [command addObjectsFromArray:@[@"SINTER", self.key]];
    [command addObjectsFromArray:filters];
    return [OOCCollection collectionWithIds:[[self conn] command:command] namespace:self.ns modelClass:self.modelClass];
}

- (OOCCollection*)except:(NSDictionary*)dict {
    ObjCHirlite* conn = [self conn];
    NSMutableArray* sunionCommand = [@[@"SUNION"] mutableCopy];
    [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
    NSMutableArray* sdiffCommand = [@[@"SDIFF", self.key] mutableCopy];
    [sdiffCommand addObjectsFromArray:[conn command:sunionCommand]];
    return [OOCCollection collectionWithIds:[conn command:sdiffCommand] namespace:self.ns modelClass:self.modelClass];
}

- (OOCCollection*)combine:(NSDictionary*)dict {
    ObjCHirlite* conn = [self conn];
    NSMutableArray* sunionCommand = [@[@"SUNION"] mutableCopy];
    [sunionCommand addObjectsFromArray:[self.modelClass filters:dict]];
    NSMutableArray* sinterCommand = [@[@"SINTER", self.key] mutableCopy];
    [sinterCommand addObjectsFromArray:[conn command:sunionCommand]];
    return [OOCCollection collectionWithIds:[conn command:sinterCommand] namespace:self.ns modelClass:self.modelClass];
}

- (OOCCollection*)union:(NSDictionary*)dict {
    ObjCHirlite* conn = [self conn];
    NSMutableArray* sinterCommand = [@[@"SINTER"] mutableCopy];
    [sinterCommand addObjectsFromArray:[self.modelClass filters:dict]];
    NSMutableArray* sunionCommand = [@[@"SUNION", self.key] mutableCopy];
    [sunionCommand addObjectsFromArray:[conn command:sinterCommand]];
    return [OOCCollection collectionWithIds:[conn command:sunionCommand] namespace:self.ns modelClass:self.modelClass];
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

@end