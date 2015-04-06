//
//  Ohm.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "Ohmoc.h"
#import "ObjCHirlite.h"

@implementation Ohmoc

@synthesize rlite = _rlite;

static NSMutableDictionary* threadToInstance = nil;

+ (id) create {
    return [[self alloc] init];
}

+ (Ohmoc*) instance {
    NSThread* thread = [NSThread currentThread];
    NSString* threadId = [NSString stringWithFormat:@"%p", thread];
    Ohmoc* instance = [threadToInstance valueForKey:threadId];
    if (!instance) {
        [NSException raise:@"NoOhmoc" format:@"Ohmoc not started on thread %@", threadId];
    }
    if (!instance.rlite) {
        [NSException raise:@"rliteMissing" format:@"rlite not started on thread %@", threadId];
    }
    return instance;
}

- (void) _init {
    if (!threadToInstance) {
        threadToInstance = [NSMutableDictionary dictionaryWithCapacity:1];
    }

    NSThread* thread = [NSThread currentThread];
    NSString* threadId = [NSString stringWithFormat:@"%p", thread];
    if ([threadToInstance valueForKey:threadId]) {
        [NSException raise:@"TooManyOhmoc" format:@"There is already an Ohmoc instance running in thread %@", threadId];
    }

    if (path) {
        _rlite = [[ObjCHirlite alloc] initWithPath:path];
    } else {
        _rlite = [[ObjCHirlite alloc] init];
    }

    [threadToInstance setValue:self forKey:threadId];
}

- (id) init {
    if (self = [super init]) {
        [self _init];
    }
    return self;
}
- (id) initWithPath:(NSString*)_path {
    if (self = [super init]) {
        path = _path;
        [self _init];
    }
    return self;
}

- (id) initWithDocumentFilename:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [self initWithPath:[basePath stringByAppendingPathComponent:filename]];
}

- (NSString*)tmpKey {
    return [NSString stringWithFormat:@"tmp%ld", tmpkey++];
}

- (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
    NSMutableArray* args = [NSMutableArray array];
    if (by) {
        [args addObjectsFromArray:@[@"BY", by]];
    }
    if (get) {
        [args addObjectsFromArray:@[@"GET", get]];
    }
    if (limit) {
        [args addObjectsFromArray:@[@"LIMIT", [NSString stringWithFormat:@"%lu", (long unsigned)offset], [NSString stringWithFormat:@"%lu", (long unsigned)limit]]];
    }
    if (order) {
        [args addObjectsFromArray:[order componentsSeparatedByString:@" "]];
    }
    if (store) {
        [args addObjectsFromArray:@[@"STORE", store]];
    }
    return [args copy];
}

- (void) flush {
    [self command:@[@"FLUSHDB"]];
}

- (id)command:(NSArray*)command {
    id retval = [_rlite command:command];
    if ([retval isKindOfClass:[NSException class]]) {
        NSException* exc = retval;
        if ([exc.reason rangeOfString:@"UniqueIndexViolation"].length != 0) {
            [[[OOCUniqueIndexViolationException alloc] initWithName:exc.name reason:exc.reason userInfo:exc.userInfo] raise];
        }
        [exc raise];
    }
    return retval;
}

@end
