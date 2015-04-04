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
        [args addObjectsFromArray:@[@"GET", by]];
    }
    if (limit) {
        [args addObjectsFromArray:@[@"LIMIT", [NSString stringWithFormat:@"%zu", limit], [NSString stringWithFormat:@"%zu", offset]]];
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
    [r command:@[@"FLUSHDB"]];
}

@end
