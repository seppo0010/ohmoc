//
//  OOCList.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCList.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"
#import "OOCModel.h"

@implementation OOCList

- (ObjCHirlite*)conn {
    return [Ohmoc rlite];
}

- (NSUInteger) size {
    return [[[self conn] command:@[@"LLEN", self.key]] unsignedIntegerValue];
}

- (id)idAtIndex:(NSInteger)index {
    return [[self conn] command:@[@"LINDEX", self.key, [NSString stringWithFormat:@"%lld", (long long)index]]];
}

- (id)objectAtIndex:(NSInteger)index {
    return [[self.modelClass alloc] initWithDictionary:[[self conn] command:@[@"HGET", [self idAtIndex:index]]]];
}

- (OOCModel*)first {
    return [self objectAtIndex:0];
}

- (OOCModel*)last {
    return [self objectAtIndex:-1];
}

- (OOCCollection*)collectionWithRange:(NSRange)range {
    NSArray* _ids = [[self conn] command:@[@"LRANGE", self.key, [NSString stringWithFormat:@"%lu", (long unsigned)range.location], [NSString stringWithFormat:@"%lu", (long unsigned)range.length + (long unsigned)range.location - 1]]];
    return [OOCCollection collectionWithIds:_ids namespace:self.ns modelClass:self.modelClass];
}

- (BOOL) contains:(OOCModel*)submodel {
    return [[self arrayValue] containsObject:submodel.id];
}

- (void)replace:(id<NSFastEnumeration>)models {
    ObjCHirlite* _rlite = [self conn];
    [_rlite command:@[@"MULTI"]];
    [_rlite command:@[@"DEL", self.key]];
    for (OOCModel* submodel in models) {
        [_rlite command:@[@"RPUSH", self.key, submodel.id]];
    }
    [_rlite command:@[@"COMMIT"]];
}

- (void)push:(OOCModel*)submodel {
    [[self conn] command:@[@"RPUSH", self.key, submodel.id]];
}

- (void)unshift:(OOCModel*)submodel {
    [[self conn] command:@[@"LPUSH", submodel.id]];
}

- (void)remove:(OOCModel*)submodel {
    [[self conn] command:@[@"LREM", self.key, @"0", submodel.id]];
}

- (NSArray*)ids {
    return [[self conn] command:@[@"LRANGE", self.key, @"0", @"-1"]];
}


- (void)setKey:(NSString *)key {
    _key = key;
}

- (NSString*)key {
    if (_key) {
        return _key;
    }
    return [self.model listForProperty:self.propertyName];
}

@end