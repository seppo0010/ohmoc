//
//  OOCModel.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCUnique.h"

@class OOCCollection;
@class OOCSet;
@interface OOCModel : NSObject {
    NSString<OOCUnique>* _id;
}

@property (readonly) NSString<OOCUnique>* id;

- (void)applyDictionary:(NSDictionary*)properties;
- (instancetype)initWithDictionary:(NSDictionary*)properties;
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