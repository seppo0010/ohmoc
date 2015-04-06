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

- (NSUInteger) size {
    __block NSUInteger s = 0;
    [self blockWithKey:^(NSString* mykey) {
        s = [[self.ohmoc command:@[@"LLEN", mykey]] unsignedIntegerValue];
    }];
    return s;
}

- (id)idAtIndex:(NSInteger)index {
    __block id obj = 0;
    [self blockWithKey:^(NSString* mykey) {
        obj = [self.ohmoc command:@[@"LINDEX", mykey, [NSString stringWithFormat:@"%lld", (long long)index]]];
    }];
    return obj;
}

- (id)objectAtIndex:(NSInteger)index {
    return [[self modelClass] get:[self idAtIndex:index]];
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
        _ids = [self.ohmoc command:@[@"LRANGE", mykey, [NSString stringWithFormat:@"%lu", (long unsigned)range.location], [NSString stringWithFormat:@"%lu", (long unsigned)range.length + (long unsigned)range.location - 1]]];
    }];
    return [OOCCollection collectionWithIds:_ids ohmoc:self.ohmoc modelClass:self.modelClass];
}

- (BOOL) contains:(OOCModel*)submodel {
    return [[self arrayValue] containsObject:submodel];
}

- (void)replace:(id<NSFastEnumeration>)models {
    Ohmoc* ohmoc = self.ohmoc;
    [ohmoc command:@[@"MULTI"]];
    [self blockWithKey:^(NSString* mykey) {
        [ohmoc command:@[@"DEL", mykey]];
        for (OOCModel* submodel in models) {
            [ohmoc command:@[@"RPUSH", mykey, submodel.id]];
        }
    }];
    [ohmoc command:@[@"EXEC"]];
}

- (void)push:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [self.ohmoc command:@[@"RPUSH", mykey, submodel.id]];
    }];
}

- (void)unshift:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [self.ohmoc command:@[@"LPUSH", mykey, submodel.id]];
    }];
}

- (void)remove:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [self.ohmoc command:@[@"LREM", mykey, @"0", submodel.id]];
    }];
}

- (NSArray*)ids {
    __block NSArray* _ids;
    [self blockWithKey:^(NSString* mykey) {
        _ids = [self.ohmoc command:@[@"LRANGE", mykey, @"0", @"-1"]];
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