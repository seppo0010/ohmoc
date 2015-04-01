//
//  ObjCHirlite.h
//  Pods
//
//  Created by Seppo on 2/28/15.
//
//

#import <Foundation/Foundation.h>
#import "hirlite.h"

@interface ObjCHirlite : NSObject {
    rliteContext* context;
    NSStringEncoding encoding;
}

- (ObjCHirlite*) initWithPath:(NSString*)path;
- (ObjCHirlite*) initWithPath:(NSString*)path encoding:(NSStringEncoding)encoding;

- (id) command:(NSArray*)command;
- (id) command:(NSArray*)command binary:(BOOL)binary;

@property NSStringEncoding encoding;

@end
