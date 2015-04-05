//
//  OOCCollection.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

// https://developer.apple.com/library/mac/samplecode/FastEnumerationSample/Listings/EnumerableClass_mm.html

#import "OOCCollection.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"
#import "OOCModel.h"

@implementation OOCCollection

+ (instancetype)collectionWithBlock:(void(^)(void(^)(NSString*)))block namespace:(NSUInteger)ns modelClass:(Class)modelClass {
    OOCCollection* set = [[self alloc] init];
    set.block = block;
    set.ns = ns;
    set.modelClass = modelClass;
    return set;
}

+ (OOCCollection*)collectionWithIds:(NSArray*)ids namespace:(NSUInteger)ns modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] init];
    c.ids = ids;
    c.ns = ns;
    c.modelClass = modelClass;
    return c;
}

+ (OOCCollection*)collectionWithKey:(NSString*)key namespace:(NSUInteger)ns modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] init];
    c.key = key;
    c.ns = ns;
    c.modelClass = modelClass;
    return c;
}

+ (OOCCollection*)collectionWithModel:(OOCModel*)model property:(NSString*)propertyName namespace:(NSUInteger)ns modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] init];
    c.model = model;
    c.propertyName = propertyName;
    c.ns = ns;
    c.modelClass = modelClass;
    return c;
}

- (NSString*)toKey:(NSString*)att {
    return [NSString stringWithFormat:@"%@:*->%@", NSStringFromClass(self.modelClass), att];
}

- (NSString*)idAtIndex:(NSUInteger)index {
    return [self.ids objectAtIndex:index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)stackbufLength {
    NSUInteger count = 0;
    if (objects == nil) {
        objects = [NSMutableArray arrayWithCapacity:[self size]];
    }
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    if (countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[0];
    }

    NSUInteger size = [self size];
    if (countOfItemsAlreadyEnumerated < size) {
        state->itemsPtr = stackbuf;
        [Ohmoc command:@[@"SELECT", [NSString stringWithFormat:@"%lu", (long unsigned)self.ns]]];
        while((countOfItemsAlreadyEnumerated < size) && (count < stackbufLength)) {
            // TODO: pipeline
            // TODO: make model
            NSString* _id = [self idAtIndex:countOfItemsAlreadyEnumerated];
            id obj = [self.modelClass get:_id];
            [objects addObject:obj]; // need to retain while the collection is alive
            stackbuf[count] = obj;
            countOfItemsAlreadyEnumerated++;
            count++;
        }
    } else {
        count = 0;
    }
    state->state = countOfItemsAlreadyEnumerated;
    return count;
}

- (NSUInteger) size {
    return self.ids.count;
}

- (BOOL) isEmpty {
    return [self size] == 0;
}

- (NSArray*)arrayValue {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self size]];
    for (id obj in self) {
        [array addObject:obj];
    }
    return [array copy];
}

- (BOOL) contains:(OOCModel*)submodel {
    return [self.ids containsObject:submodel.id];
}

- (void)setKey:(NSString *)key {
    _key = key;
}

- (NSString*)key {
    [NSException raise:@"Must not call OOCSet.key" format:@"Use blockWithKey instead"];
    return nil;
}

- (NSString*)keyForProperty:(NSString*)propertyName {
    return nil;
}

- (void) blockWithKey:(void(^)(NSString*))localblock {
    if (_block) {
        _block(localblock);
    }
    else if (_key) {
        localblock(_key);
    } else {
        localblock([self keyForProperty:self.propertyName]);
    }
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

- (OOCList*) sortBy:(NSString*)by limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return (OOCList*)[self _sortBy:[self toKey:by] get:nil limit:limit offset:offset order:order store:store];
}

- (OOCList*) sortBy:(NSString*)by {
    return [self sortBy:by limit:0 offset:0 order:nil store:nil];
}

@end