//
//  OOCModel.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCModel.h"
#import "OOCIndexNotFoundException.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"
#import "OOCCollection.h"
#import "OOCSet.h"
#import "OOCsavelua.h"
#import "OOCdeletelua.h"
#import "MessagePack.h"
#import <objc/runtime.h>

@interface OOCModelProperty : NSObject
@property NSString* name;
@property BOOL isUnique; // shortcut when OOCUnique protocol is used
@property BOOL hasIndex; // shortcut when OOCIndex protocol is used
@end
@implementation OOCModelProperty
@end

@interface OOCModelBasicProperty : OOCModelProperty
@property char identifier;
@end
@implementation OOCModelBasicProperty
@end

@interface OOCModelObjectProperty : OOCModelProperty
@property Class klass;
@property NSSet* protocols;
@property Class subtype; // shortcut when OOCSet/OOCList define a protocol that matches a subclass of OOCModel
@property NSString* referenceProperty; // is the object referenced from a property collection
@end
@implementation OOCModelObjectProperty
@end

@interface OOCModelSpec : NSObject
@property NSDictionary* properties;
@property NSSet* indices;
@property NSSet* uniques;
@end
@implementation OOCModelSpec
@end

@implementation OOCModel

@synthesize id;

static NSMutableDictionary* specs = nil;
static NSString* lua_save = nil;
static NSString* lua_delete = nil;

+ (OOCModelProperty*)parse:(NSString*)name type:(NSString*)type {
    if (type.length == 1) {
        OOCModelBasicProperty* property = [[OOCModelBasicProperty alloc] init];
        property.identifier = [type cStringUsingEncoding:NSUTF8StringEncoding][0];
        return property;
    }
    OOCModelObjectProperty* property = [[OOCModelObjectProperty alloc] init];
    property.name = name;

    NSRange range;
    range.location = 2;
    range.length = [type rangeOfString:@"<"].location;
    NSRange subrange;
    if (range.length == NSNotFound) {
        subrange.location = 2;
        subrange.length = type.length -2;
        range.length = [type rangeOfString:@"\"" options:NSLiteralSearch range:subrange].location;
    } else {
        subrange.location = range.length + 1;
        subrange.length = type.length - subrange.location - 2;
        NSString* protocols = [type substringWithRange:subrange];
        property.protocols = [NSSet setWithArray:[protocols componentsSeparatedByString:@"><"]];
        for (NSString* protocol in property.protocols) {
            if ([protocol isEqualToString:@"OOCUnique"]) {
                property.isUnique = true;
            } else if ([protocol isEqualToString:@"OOCIndex"]) {
                property.hasIndex = true;
            } else {
                Class subclass = NSClassFromString(protocol);
                if (subclass && [subclass isSubclassOfClass:[OOCModel class]]) {
                    if (property.subtype) {
                        [NSException raise:@"MultipleSubtypes" format:@"Two models subtypes found for '%@'", type];
                    }
                    property.subtype = subclass;
                }
            }
        }
    }
    range.length -= 2;
    NSString* className = [type substringWithRange:range];
    // className is empty if type is "id".
    if (className.length > 0) {
        property.klass = NSClassFromString(className);
        if (!property.klass) {
            [NSException raise:@"ClassNotFound" format:@"Unable to find class name for type '%@'", type];
        }
    }
    return property;
}

+ (OOCModelSpec*)calculateSpec {
    NSMutableDictionary* properties = [NSMutableDictionary dictionary];

    unsigned int i, j, count, attributeListCount;
    objc_property_t *props = class_copyPropertyList(self, &count);
    for (i = 0; i < count; i++) {
        NSString* type;
        const char *propName = property_getName(props[i]);
        objc_property_attribute_t *attributeList = property_copyAttributeList(props[i], &attributeListCount);
        for (j = 0; j < attributeListCount; j++) {
            if (strcmp(attributeList[j].name, "T") == 0) {
                type = [NSString stringWithCString:attributeList[j].value encoding:NSUTF8StringEncoding];
                break;
            }
        }
        if (!type) {
            continue;
        }
        NSString* propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
        OOCModelProperty* property = [self parse:propertyName type:type];
        [properties setValue:property forKey:propertyName];
    }

    for (NSString* propertyName in [properties copy]) {
        OOCModelProperty* property = [properties valueForKey:propertyName];
        if ([propertyName hasSuffix:@"Meta"]) {
            OOCModelProperty* metaProperty = [properties valueForKey:propertyName];
            OOCModelProperty* property = [properties valueForKey:[propertyName substringToIndex:propertyName.length - 4]];
            property.isUnique = metaProperty.isUnique;
            property.hasIndex = metaProperty.hasIndex;
            [properties removeObjectForKey:propertyName];
        }
        if ([property isKindOfClass:[OOCModelObjectProperty class]] && [[(OOCModelObjectProperty*)property protocols] containsObject:@"OOCCollection"]) {
            NSArray* components = [propertyName componentsSeparatedByString:@"__"];
            if (components.count != 2) {
                [NSException raise:@"TooManyComponents" format:@"When specifying a collection protocol there must be a property and its subproperty, got %@", propertyName];
            }
            OOCModelObjectProperty* object = [properties valueForKey:[components objectAtIndex:0]];
            object.referenceProperty = [components objectAtIndex:1];
            [properties removeObjectForKey:propertyName];
        }
    }

    NSMutableSet* indices = [NSMutableSet set];
    NSMutableSet* uniques = [NSMutableSet set];
    for (NSString* propertyName in properties) {
        OOCModelProperty* property = [properties valueForKey:propertyName];
        if (property.isUnique) {
            [uniques addObject:propertyName];
        }
        if (property.hasIndex) {
            [indices addObject:propertyName];
        }
    }

    OOCModelSpec* spec = [[OOCModelSpec alloc] init];
    spec.properties = [properties copy];
    spec.indices = [indices copy];
    spec.uniques = [uniques copy];
    return spec;
}

+ (OOCModelSpec*)spec {
    NSString* className = NSStringFromClass(self);
    if (!specs) {
        specs = [NSMutableDictionary dictionaryWithCapacity:32];
    }
    OOCModelSpec* spec = [specs valueForKey:className];
    if (!spec) {
        spec = [self calculateSpec];
        [specs setValue:spec forKey:className];
    }
    return spec;
}

+ (BOOL)exists:(NSString*)id {
    return [[Ohmoc command:@[@"SISMEMBER", [@[NSStringFromClass(self), @"all"] componentsJoinedByString:@":"], id]] boolValue];
}

static NSMutableDictionary* cache = nil;

+ (BOOL)isCached:(NSString*)id {
    NSString* cacheKey = [@[NSStringFromClass(self), id] componentsJoinedByString:@":"];
    return !![cache valueForKey:cacheKey];
}

+ (OOCModel*)get:(NSString*)id {
    if (!id) {
        return nil;
    }
    NSString* cacheKey = [@[NSStringFromClass(self), id] componentsJoinedByString:@":"];
    OOCModel* model = [cache valueForKey:cacheKey];
    if (!model && id && [self exists:id]) {
        model = [[self alloc] initWithId:id];
        [model load];
        if (!cache) {
            cache = (NSMutableDictionary*)CFBridgingRelease(CFDictionaryCreateMutable(nil, 0, &kCFCopyStringDictionaryKeyCallBacks, NULL));
        }
        [cache setValue:model forKey:cacheKey];
    }
    return model;
}
- (void) dealloc {
    NSString* cacheKey = [@[NSStringFromClass([self class]), id] componentsJoinedByString:@":"];
    [cache removeObjectForKey:cacheKey];
}

+ (OOCModel*) with:(NSString*)att value:(NSString*)value {
    OOCModelProperty* property = [[[[self class] spec] properties] valueForKey:att];
    if (!property.hasIndex) {
        [OOCIndexNotFoundException raise:@"IndexNotFound" format:@"Index not found: '%@'", att];
    }
    NSString* _id = [Ohmoc command:@[@"HGET", [@[NSStringFromClass(self), @"uniques", att] componentsJoinedByString:@":"], [self stringForIndex:att value:value]]];
    if (_id) {
        OOCModel* model = [[OOCModel alloc] initWithId:_id];
        [model load];
        return model;
    }
    return nil;
}

+ (NSString*)stringForIndex:(NSString*)key value:(id)v {
    OOCModelProperty* prop = [[self spec].properties valueForKey:key];
    if ([prop isKindOfClass:[OOCModelBasicProperty class]]) {
        OOCModelBasicProperty* basicProp = (OOCModelBasicProperty*)prop;
        if (basicProp.identifier == _C_BOOL) {
            v = [v boolValue] ? @"true" : @"false";
        }
    }
    v = [v respondsToSelector:@selector(stringValue)] ? [v stringValue] : v;
    return v;
}

+ (NSString*)indexForKey:(NSString*)key value:(id)v {
    return [@[NSStringFromClass(self), @"indices", key, [self stringForIndex:key value:v]] componentsJoinedByString:@":"];
}
+ (NSArray*) toIndices:(NSString*)key value:(id)value {
    OOCModelProperty* property;
    if ([key hasSuffix:@"_id"]) {
        NSString* propertyKey = [key substringToIndex:key.length - 3];
        property = [[[[self class] spec] properties] valueForKey:propertyKey];
    } else {
        property = [[[[self class] spec] properties] valueForKey:key];
    }
    if (!property.hasIndex) {
        [OOCIndexNotFoundException raise:@"IndexNotFound" format:@"Index not found: '%@'", key];
    }
    if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
        NSMutableArray* indices = [NSMutableArray array];
        for (id v in value) {
            [indices addObject:[self indexForKey:key value:v]];
        }
        return [indices copy];
    } else {
        return @[[self indexForKey:key value:value]];
    }
}

+ (NSArray*) filters:(NSDictionary*)dict {
    NSMutableArray* filters = [NSMutableArray arrayWithCapacity:[dict count]];
    for (NSString* key in dict) {
        [filters addObjectsFromArray:[self toIndices:key value:[dict valueForKey:key]]];
    }
    return [filters copy];
}

+ (OOCSet*) find:(NSDictionary*)dict {
    NSArray* filters = [self filters:dict];
    if (filters.count == 1) {
        // TODO: namespace?
        return [OOCSet collectionWithKey:[filters objectAtIndex:0] namespace:0 modelClass:self];
    } else {
        return [OOCSet collectionWithBlock:^(void(^block)(NSString*)) {
            NSString* key = [Ohmoc tmpKey];
            NSMutableArray* sunionCommand = [@[@"SINTERSTORE", key] mutableCopy];
            [sunionCommand addObjectsFromArray:filters];
            [Ohmoc command:sunionCommand];
            block(key);
            [Ohmoc command:@[@"DEL", key]];
        } namespace:0 modelClass:self];
    }
}

+ (OOCModel*) with:(NSString*)att is:(id)value {
    if (![[self spec].uniques containsObject:att]) {
        [OOCIndexNotFoundException raise:@"IndexNotFound" format:@"Index not found: '%@'", att];
    }

    NSString* id = [Ohmoc command:@[@"HGET", [@[NSStringFromClass(self), @"uniques", att] componentsJoinedByString:@":"], [self stringForIndex:att value:value]]];
    if ([id isKindOfClass:[NSString class]]) {
        return [self get:id];
    }
    return nil;
}

+ (OOCSet*)all {
    return [OOCSet collectionWithKey:[@[NSStringFromClass(self), @"all"] componentsJoinedByString:@":"] namespace:0 modelClass:self];
}

+ (OOCCollection*)fetch:(NSArray*)ids {
    return [OOCCollection collectionWithIds:ids namespace:0 modelClass:self];
}

- (OOCModel*)init {
    if (self = [super init]) {
        OOCModelSpec* spec = [[self class] spec];
        NSDictionary* properties = spec.properties;
        for (NSString* propertyName in properties) {
            OOCModelProperty* property = [properties valueForKey:propertyName];
            if ([property isKindOfClass:[OOCModelObjectProperty class]]) {
                OOCModelObjectProperty* objProperty = (OOCModelObjectProperty*)property;
                Class klass = objProperty.klass;
                if ([klass isSubclassOfClass:[OOCSet class]] || [klass isSubclassOfClass:[OOCList class]]) {
                    // TODO: ns
                    OOCCollection* collection = [klass collectionWithModel:self property:propertyName namespace:0 modelClass:objProperty.subtype];
                    [self setValue:collection forKey:propertyName];
                }
            }
        }
    }
    return self;
}

- (OOCModel*)initWithId:(NSString*)_id {
    if (self = [self init]) {
        self.id = (NSString<OOCUnique>*)_id;
    }
    return self;
}

+ (instancetype)create:(NSDictionary*)properties {
    id instance = [[self alloc] initWithDictionary:properties];
    [instance save];
    return instance;
}

- (void)applyDictionary:(NSDictionary*)properties {
    OOCModelSpec* spec = [[self class] spec];
    for (NSString* key in properties) {
        OOCModelProperty* propertySpec = [spec.properties valueForKey:key];
        if (!propertySpec) {
            continue;
        }
        id value = [properties valueForKey:key];
        [self setValue:value forKey:key];
//        if ([propertySpec isKindOfClass:[OOCModelObjectProperty class]]) {
//            OOCModelObjectProperty* objPropertySpec = (OOCModelObjectProperty*)propertySpec;
//            if (objPropertySpec.referenceProperty) {
//                [[value valueForKey:objPropertySpec.referenceProperty] add:self];
//            }
//        }
    }
}

- (instancetype)initWithDictionary:(NSDictionary*)properties {
    if (self = [self init]) {
        [self applyDictionary:properties];
    }
    return self;
}

- (NSString*)key {
    return [@[NSStringFromClass([self class]), self.id] componentsJoinedByString:@":"];
}

- (void) load {
    NSArray* properties = [Ohmoc command:@[@"HGETALL", self.key]];
    NSDictionary* classProperties = [[self class] spec].properties;
    for (NSUInteger i = 0; i < properties.count; i += 2) {
        NSString* key = [properties objectAtIndex:i];
        id value = [properties objectAtIndex:i + 1];
        if ([classProperties valueForKey:key]) {
            [self setValue:value forKey:key];
        } else if ([key hasSuffix:@"_id"]) {
            NSString* shortkey = [key substringToIndex:key.length - 3];
            OOCModelProperty* property = [classProperties valueForKey:shortkey];
            if (!property) {
                [NSException raise:@"UnknownKey" format:@"Unknown key %@", key];
            }
            if (![property isKindOfClass:[OOCModelObjectProperty class]]) {
                [NSException raise:@"ExpectedObject" format:@"Property is not an object property for key '%@'", key];
            }
            OOCModelObjectProperty* objProperty = (OOCModelObjectProperty*)property;
            [self setValue:[objProperty.klass get:value] forKey:shortkey];
        } else {
            [NSException raise:@"UnknownProperty" format:@"Uknown property %@", key];
        }
    }
}

- (void) save {
    NSDictionary* features;
    NSString* name = NSStringFromClass([self class]);
    if (self.id) {
        features = @{
                     @"id": self.id,
                     @"name": name
                     };
    } else {
        features = @{@"name": name};
    }

    NSMutableArray* properties = [NSMutableArray array];
    OOCModelSpec* spec = [[self class] spec];
    for (NSString* key in spec.properties) {
        id val = [self valueForKey:key];
        if (val && ![val isKindOfClass:[OOCCollection class]]) {
            if ([val isKindOfClass:[OOCModel class]]) {
                [properties addObject:[NSString stringWithFormat:@"%@_id", key]];
                [properties addObject:[(OOCModel*)val id]];
            } else {
                [properties addObject:key];
                [properties addObject:[val respondsToSelector:@selector(stringValue)] ? [val stringValue] : val];
            }
        }
    }

    NSMutableDictionary* indices = [NSMutableDictionary dictionary];
    for (NSString* index in spec.indices) {
        id value = [self valueForKey:index];
        if (value) {
            if ([value isKindOfClass:[OOCModel class]]) {
                [indices setValue:@[[value id]] forKey:[NSString stringWithFormat:@"%@_id", index]];
            } else {
                [indices setValue:@[value] forKey:index];
            }
        }
    }
    NSMutableDictionary* uniques = [NSMutableDictionary dictionary];
    for (NSString* unique in spec.uniques) {
        id val = [self valueForKey:unique];
        [uniques setValue:[[self class] stringForIndex:unique value:val] forKey:unique];
    }

    if (!lua_save) {
        lua_save = [NSString stringWithCString:savelua encoding:NSUTF8StringEncoding];
    }

    id ret = [Ohmoc command:@[@"EVAL", lua_save, @"0", [features messagePack], [properties messagePack], [indices messagePack], [uniques messagePack]]];
    if ([ret isKindOfClass:[NSException class]]) {
        // ugh;
        [ret raise];
    }
    [self setValue:ret forKey:@"id"];

    if (!cache) {
        cache = (NSMutableDictionary*)CFBridgingRelease(CFDictionaryCreateMutable(nil, 0, &kCFCopyStringDictionaryKeyCallBacks, NULL));
    }
    NSString* cacheKey = [@[NSStringFromClass([self class]), id] componentsJoinedByString:@":"];
    [cache setValue:self forKey:cacheKey];
}

- (NSString*)indexForProperty:(NSString *)propertyName {
    OOCModelObjectProperty* property = [[[[self class] spec] properties] valueForKey:propertyName];
    NSString* referenceProperty = property.referenceProperty;
    return [@[NSStringFromClass(property.subtype), @"indices", [NSString stringWithFormat:@"%@_id", referenceProperty], self.id] componentsJoinedByString:@":"];
}

- (NSString*)listForProperty:(NSString *)propertyName {
    OOCModelObjectProperty* property = [[[[self class] spec] properties] valueForKey:propertyName];
    return [@[NSStringFromClass(property.subtype), self.id, propertyName] componentsJoinedByString:@":"];
}

- (void) delete {
    OOCModelSpec* spec = [[self class] spec];
    NSMutableDictionary* uniques = [NSMutableDictionary dictionaryWithCapacity:spec.uniques.count];
    for (NSString* unique in spec.uniques) {
        [uniques setValue:[self valueForKey:unique] forKey:unique];
    }
    if (!lua_delete) {
        lua_delete = [NSString stringWithCString:deletelua encoding:NSUTF8StringEncoding];
    }

    id ret = [Ohmoc command:@[@"EVAL", lua_delete, @"0", [@{@"name": NSStringFromClass([self class]), @"id": self.id, @"key": self.key} messagePack], [uniques messagePack], [@[] messagePack]]];
    if ([ret isKindOfClass:[NSException class]]) {
        // ugh;
        [ret raise];
    }
}

@end