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

@interface OOCModelProperty : NSObject
@property NSString* name;
@property BOOL readonly; // the property is (readonly)
@property BOOL isUnique; // OOCUnique protocol is used
@property BOOL hasIndex; // OOCIndex protocol is used
@end

@interface OOCModelBasicProperty : OOCModelProperty
@property char identifier;
@end

@interface OOCModelObjectProperty : OOCModelProperty
@property Class klass;
@property NSSet* protocols;
@property Class subtype; // shortcut when OOCSet/OOCList define a protocol that matches a subclass of OOCModel
@property NSString* referenceProperty; // is the object referenced from a property collection
@end

@interface OOCModelSpec : NSObject
@property NSDictionary* properties;
@property NSSet* indices;
@property NSSet* uniques;
@property NSSet* tracked;
@end

@class OOCCollection;
@class OOCSet;
@interface OOCModel : OOCObject {
    NSString<OOCUnique>* _id;
}

@property (readonly) NSString<OOCUnique>* id;

+ (OOCSet*) find:(NSDictionary*)dict;
+ (instancetype) with:(NSString*)property is:(id)value;
+ (instancetype)get:(NSString*)id;
+ (instancetype)create;
+ (instancetype)create:(NSDictionary*)properties;
+ (OOCSet*)all;
+ (OOCModel*)getCached:(NSString*)id;
+ (BOOL)isCached:(NSString*)id;

+ (NSArray*) filters:(NSDictionary*)filters;
+ (OOCModelSpec*)spec;
+ (NSString*)stringForIndex:(NSString*)key value:(id)v;

- (void)applyDictionary:(NSDictionary*)properties;
- (OOCModel*)initWithId:(NSString*)id ohmoc:(Ohmoc*)ohmoc;
- (instancetype)initWithDictionary:(NSDictionary*)properties ohmoc:(Ohmoc*)ohmoc;
- (NSString*)indexForProperty:(NSString*)property;
- (NSString*)listForProperty:(NSString*)property;
- (id)get:(NSString*)prop;
- (void)set:(NSString*)att value:(id)val;
- (void) save;
- (void) load;
- (void) delete;

@end