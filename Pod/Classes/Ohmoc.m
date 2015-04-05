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

static ObjCHirlite* r = NULL;

static long tmpkey = 0;
+ (NSString*)tmpKey {
    return [NSString stringWithFormat:@"tmp%ld", tmpkey++];
}

+ (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store {
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

static NSString* path;

+ (ObjCHirlite*) rlite {
    if (!r) {
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
//        path = [basePath stringByAppendingPathComponent:@"db.rld"]
//        r = [[ObjCHirlite alloc] initWithPath:path];
        r = [[ObjCHirlite alloc] init];
    }
    return r;
}

+ (void) flush {
    [self command:@[@"FLUSHDB"]];
    r = nil;
}

+ (id)command:(NSArray*)command {
    id retval = [[self rlite] command:command];
    if ([retval isKindOfClass:[NSException class]]) {
        NSLog(@"%@", command);
        [retval raise];
    }
    return retval;
}

@end
