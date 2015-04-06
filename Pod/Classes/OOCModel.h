//
//  OOCModel.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCUnique.h"
#import "OOCObject.h"

@class OOCCollection;
@class OOCSet;
@interface OOCModel : OOCObject {
    NSString<OOCUnique>* _id;
}

@property (readonly) NSString<OOCUnique>* id;

- (void)applyDictionary:(NSDictionary*)properties;
- (OOCModel*)initWithId:(NSString*)id ohmoc:(Ohmoc*)ohmoc;
- (instancetype)initWithDictionary:(NSDictionary*)properties ohmoc:(Ohmoc*)ohmoc;
- (NSString*)indexForProperty:(NSString*)property;
- (NSString*)listForProperty:(NSString*)property;
+ (NSArray*) filters:(NSDictionary*)filters;
+ (OOCSet*) find:(NSDictionary*)dict;
+ (instancetype) with:(NSString*)property is:(id)value;
+ (instancetype)get:(NSString*)id;
+ (instancetype)create;
+ (instancetype)create:(NSDictionary*)properties;
- (id)get:(NSString*)prop;
- (void)set:(NSString*)att value:(id)val;
+ (OOCSet*)all;
+ (BOOL)isCached:(NSString*)id;
- (void) save;
- (void) delete;

@end