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

+ (instancetype)collectionWithBlock:(void(^)(void(^)(NSString*)))block ohmoc:(Ohmoc*)ohmoc modelClass:(Class)modelClass {
    OOCCollection* set = [[self alloc] initWithOhmoc:ohmoc];
    set.block = block;
    set.modelClass = modelClass;
    return set;
}

+ (OOCCollection*)collectionWithIds:(NSArray*)ids ohmoc:(Ohmoc*)ohmoc modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] initWithOhmoc:ohmoc];
    c.ids = ids;
    c.modelClass = modelClass;
    return c;
}

+ (OOCCollection*)collectionWithKey:(NSString*)key ohmoc:(Ohmoc*)ohmoc modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] initWithOhmoc:ohmoc];
    c.key = key;
    c.modelClass = modelClass;
    return c;
}

+ (OOCCollection*)collectionWithModel:(OOCModel*)model property:(NSString*)propertyName ohmoc:(Ohmoc*)ohmoc modelClass:(Class)modelClass {
    OOCCollection* c = [[self alloc] initWithOhmoc:ohmoc];
    c.model = model;
    c.propertyName = propertyName;
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
            Ohmoc* ohmoc = self.ohmoc;
            [command addObjectsFromArray:@[@"SORT", mykey]];
            [command addObjectsFromArray:[ohmoc sortBy:by get:get limit:limit offset:offset order:order store:store]];
            r = [ohmoc command:command];
        }];
        return r;
    } else {
        return [OOCList collectionWithBlock:^(void(^localblock)(NSString*)) {
            Ohmoc* ohmoc = self.ohmoc;
            NSString* key = store;
            if (!store) {
                key = [ohmoc tmpKey];
            }
            [self blockWithKey:^(NSString* mykey) {
                NSMutableArray* command = [NSMutableArray arrayWithObjects:@"SORT", mykey, nil];
                [command addObjectsFromArray:[ohmoc sortBy:by get:get limit:limit offset:offset order:order store:key]];
                [ohmoc command:command];
                localblock(key);
            }];
            if (!store) {
                [ohmoc command:@[@"DEL", key]];
            }
        } ohmoc:self.ohmoc modelClass:self.modelClass];
    }
}

- (id<NSFastEnumeration>) sort:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:nil get:get limit:limit offset:offset order:order store:store];
}

- (id<NSFastEnumeration>) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return [self _sortBy:[self toKey:by] get:get limit:limit offset:offset order:order store:store];
}

- (OOCList*) sortBy:(NSString*)by limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    return (OOCList*)[self sortBy:by get:nil limit:limit offset:offset order:order store:store];
}

- (OOCList*) sortBy:(NSString*)by limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order {
    return [self sortBy:by limit:limit offset:offset order:order store:nil];
}

- (OOCList*) sortBy:(NSString*)by order:(NSString*)order {
    return [self sortBy:by limit:0 offset:0 order:order];
}

- (OOCList*) sortBy:(NSString*)by {
    return [self sortBy:by limit:0 offset:0 order:nil store:nil];
}

@end