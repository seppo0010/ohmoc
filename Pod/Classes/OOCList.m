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
    __block NSUInteger s = 0;
    [self blockWithKey:^(NSString* mykey) {
        s = [[[self conn] command:@[@"LLEN", mykey]] unsignedIntegerValue];
    }];
    return s;
}

- (id)idAtIndex:(NSInteger)index {
    __block id obj = 0;
    [self blockWithKey:^(NSString* mykey) {
        obj = [[self conn] command:@[@"LINDEX", mykey, [NSString stringWithFormat:@"%lld", (long long)index]]];
    }];
    return obj;
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
    __block NSArray* _ids;
    [self blockWithKey:^(NSString* mykey) {
        _ids = [[self conn] command:@[@"LRANGE", mykey, [NSString stringWithFormat:@"%lu", (long unsigned)range.location], [NSString stringWithFormat:@"%lu", (long unsigned)range.length + (long unsigned)range.location - 1]]];
    }];
    return [OOCCollection collectionWithIds:_ids namespace:self.ns modelClass:self.modelClass];
}

- (BOOL) contains:(OOCModel*)submodel {
    return [[self arrayValue] containsObject:submodel.id];
}

- (void)replace:(id<NSFastEnumeration>)models {
    ObjCHirlite* _rlite = [self conn];
    [_rlite command:@[@"MULTI"]];
    [self blockWithKey:^(NSString* mykey) {
        [_rlite command:@[@"DEL", mykey]];
        for (OOCModel* submodel in models) {
            [_rlite command:@[@"RPUSH", mykey, submodel.id]];
        }
    }];
    [_rlite command:@[@"COMMIT"]];
}

- (void)push:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [[self conn] command:@[@"RPUSH", mykey, submodel.id]];
    }];
}

- (void)unshift:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [[self conn] command:@[@"LPUSH", mykey, submodel.id]];
    }];
}

- (void)remove:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [[self conn] command:@[@"LREM", mykey, @"0", submodel.id]];
    }];
}

- (NSArray*)ids {
    __block NSArray* _ids;
    [self blockWithKey:^(NSString* mykey) {
        _ids = [[self conn] command:@[@"LRANGE", mykey, @"0", @"-1"]];
    }];
    return _ids;
}


- (void)setKey:(NSString *)key {
    _key = key;
}

- (NSString*)keyForProperty:(NSString*)propertyName {
    return [self.model listForProperty:self.propertyName];
}

@end