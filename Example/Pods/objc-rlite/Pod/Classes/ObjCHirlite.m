//
//  ObjCHirlite.m
//  Pods
//
//  Created by Seppo on 2/28/15.
//
//

#import <string.h>
#import "ObjCHirlite.h"

@implementation ObjCHirlite

@synthesize encoding;

- (ObjCHirlite*) init {
    if (self = [super init]) {
        context = rliteConnect(":memory:", 0);
        encoding = NSUTF8StringEncoding;
    }
    return self;
}

- (ObjCHirlite*) initWithPath:(NSString*)path {
    if (self = [super init]) {
        context = rliteConnect([path UTF8String], 0);
        encoding = NSUTF8StringEncoding;
    }
    return self;
}

- (ObjCHirlite*) initWithPath:(NSString*)path encoding:(NSStringEncoding)_encoding {
    if (self = [self initWithPath:path]) {
        encoding = _encoding;
    }
    return self;
}

- (NSData*) dataFromObject:(id)object {
    if ([object respondsToSelector:@selector(bytes)]) {
        return object;
    }
    if ([object respondsToSelector:@selector(stringValue)]) {
        return [[object stringValue] dataUsingEncoding:encoding];
    }
    if ([object isKindOfClass:[NSString class]]) {
        return [object dataUsingEncoding:encoding];
    }
    [NSException raise:@"Invalid Object" format:@"Object of type %@ cannot be used in command", NSStringFromClass([object class])];
    return nil;
}

- (id) objectFromReply:(rliteReply*)reply binary:(BOOL)binary {
    if (reply->type == RLITE_REPLY_STATUS || reply->type == RLITE_REPLY_STRING) {
        if (reply->type == RLITE_REPLY_STATUS && reply->len == 2 && memcmp(reply->str, "OK", 2) == 0) {
            return [NSNumber numberWithBool:TRUE];
        }
        if (binary) {
            return [NSData dataWithBytes:reply->str length:reply->len];
        }
        return [[NSString alloc] initWithBytes:reply->str length:reply->len encoding:encoding];
    }
    if (reply->type == RLITE_REPLY_NIL) {
        return [NSNull null];
    }
    if (reply->type == RLITE_REPLY_INTEGER) {
        return [NSNumber numberWithLongLong:reply->integer];
    }
    if (reply->type == RLITE_REPLY_ERROR) {
        NSString* reason = [[NSString alloc] initWithBytes:reply->str length:reply->len encoding:encoding];
        return [NSException exceptionWithName:@"ObjCHirliteError" reason:reason userInfo:nil];
    }
    if (reply->type == RLITE_REPLY_ARRAY) {
        size_t i;
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:reply->elements];
        for (i = 0; i < reply->elements; i++) {
            [array addObject:[self objectFromReply:reply->element[i] binary:binary]];
        }
        return [array copy];
    }
    return nil;
}

- (id) command:(NSArray*)command binary:(BOOL)binary {
    int i, argc;
    char **argv;
    size_t *argvlen;
    rliteReply* reply;
    NSData* data;

    argc = (int)[command count];
    argv = malloc(sizeof(char *) * argc);
    argvlen = malloc(sizeof(size_t) * argc);

    for (i = 0; i < argc; i++) {
        data = [self dataFromObject:[command objectAtIndex:i]];
        argv[i] = (char *)[data bytes];
        argvlen[i] = [data length];
    }

    reply = rliteCommandArgv(context, argc, argv, argvlen);

    free(argv);
    free(argvlen);
    id obj = [self objectFromReply:reply binary:binary];
    rliteFreeReplyObject(reply);
    return obj;
}

- (id) command:(NSArray*)command {
    return [self command:command binary:NO];
}


- (void) dealloc {
    rliteFree(context);
}

@end