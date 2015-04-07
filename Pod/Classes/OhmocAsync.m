//
//  OhmocAsync.m
//  Pods
//
//  Created by Seppo on 4/6/15.
//
//

#import "OhmocAsync.h"

@implementation OhmocAsync

@synthesize queue;

- (void) _init {
    [super _init];
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
}

- (void)find:(NSDictionary*)dict model:(Class)modelClass callback:(void(^)(OOCSet*))callback {
    [queue addOperationWithBlock:^{
        id r = [self find:dict model:modelClass];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (callback) callback(r);
        }];
    }];
}

- (void)with:(NSString*)property is:(id)value model:(Class)modelClass callback:(void(^)(id))callback {
    [queue addOperationWithBlock:^{
        id r = [self with:property is:value model:modelClass];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (callback) callback(r);
        }];
    }];
}

- (void)get:(NSString*)_id model:(Class)modelClass callback:(void(^)(id))callback {
    [queue addOperationWithBlock:^{
        id r = [self get:_id model:modelClass];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (callback) callback(r);
        }];
    }];
}

- (void)createModel:(Class)modelClass callback:(void(^)(id))callback {
    [queue addOperationWithBlock:^{
        id r = [self createModel:modelClass];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (callback) callback(r);
        }];
    }];
}

- (void)create:(NSDictionary*)properties model:(Class)modelClass callback:(void(^)(id))callback {
    [queue addOperationWithBlock:^{
        id r = [self create:properties model:modelClass];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (callback) callback(r);
        }];
    }];
}

- (id)command:(NSArray*)command binary:(BOOL)binary {
    if ([NSOperationQueue currentQueue] != queue) {
        [NSException raise:@"CommandFromWrongThread" format:@"Calling command:binary: from outside the operation queue in OhmocAsync"];
    }
    return [super command:command binary:binary];
}

@end