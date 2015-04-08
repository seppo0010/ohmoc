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

@implementation OOCModelProperty
@end

@implementation OOCModelBasicProperty
@end

@implementation OOCModelObjectProperty
@end

@implementation OOCModelSpec
@end

@interface OOCModel (private)

@property NSString<OOCUnique>* id;

@end

@implementation OOCModel (private)

- (void) setId:(NSString<OOCUnique> *)id {
    _id = id;
}

@end

@implementation OOCModel

@synthesize id = _id;

static NSMutableDictionary* specs = nil;
static NSString* lua_save = nil;
static NSString* lua_delete = nil;

+ (OOCModelProperty*)parse:(NSString*)name type:(NSString*)type {
    if (type.length == 1) {
        OOCModelBasicProperty* property = [[OOCModelBasicProperty alloc] init];
        property.name = name;
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
            } else if ([protocol isEqualToString:@"OOCSortedIndex"]) {
                property.hasSortedIndex = true;
            } else {
                Class subclass = NSClassFromString(protocol);
                if (subclass && [subclass isSubclassOfClass:[OOCModel class]]) {
                    if (property.subtype) {
                        [OOCException raise:@"MultipleSubtypes" format:@"Two models subtypes found for '%@'", type];
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
            [OOCException raise:@"ClassNotFound" format:@"Unable to find class name for type '%@'", type];
        }
    }
    return property;
}

+ (OOCModelSpec*)calculateSpec {
    NSMutableDictionary* properties = [NSMutableDictionary dictionary];
    NSMutableSet* tracked = [NSMutableSet set];

    unsigned int i, j, count, attributeListCount;
    Class kls = self;
    do {
        objc_property_t *props = class_copyPropertyList(kls, &count);
        for (i = 0; i < count; i++) {
            NSString* type;
            BOOL readonly = FALSE;
            const char *propName = property_getName(props[i]);
            objc_property_attribute_t *attributeList = property_copyAttributeList(props[i], &attributeListCount);
            for (j = 0; j < attributeListCount; j++) {
                if (strcmp(attributeList[j].name, "T") == 0) {
                    type = [NSString stringWithCString:attributeList[j].value encoding:NSUTF8StringEncoding];
                }
                if (strcmp(attributeList[j].name, "R") == 0) {
                    readonly = TRUE;
                }
            }
            if (!type) {
                continue;
            }
            NSString* propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
            if ([propertyName isEqualToString:@"id"]) {
                readonly = FALSE;
            }
            OOCModelProperty* property = [self parse:propertyName type:type];
            property.readonly = readonly;
            if ([property isKindOfClass:[OOCModelObjectProperty class]]) {
                OOCModelObjectProperty* objProperty = (OOCModelObjectProperty*)property;
                if ([objProperty.klass isSubclassOfClass:[OOCCollection class]]) {
                    [tracked addObject:propertyName];
                }
            }
            [properties setValue:property forKey:propertyName];
        }
    } while ((kls = kls.superclass) != [OOCObject class]);

    for (NSString* propertyName in [properties copy]) {
        OOCModelProperty* property = [properties valueForKey:propertyName];
        if ([propertyName hasSuffix:@"Meta"]) {
            OOCModelProperty* metaProperty = [properties valueForKey:propertyName];
            OOCModelProperty* property = [properties valueForKey:[propertyName substringToIndex:propertyName.length - 4]];
            property.isUnique = metaProperty.isUnique;
            property.hasIndex = metaProperty.hasIndex;
            property.hasSortedIndex = metaProperty.hasSortedIndex;
            property.groupBy = metaProperty.groupBy;
            property.readonly = metaProperty.readonly;
            [properties removeObjectForKey:propertyName];
        }
        if ([property isKindOfClass:[OOCModelObjectProperty class]] && [[(OOCModelObjectProperty*)property protocols] containsObject:@"OOCCollection"]) {
            NSArray* components = [propertyName componentsSeparatedByString:@"__"];
            if (components.count != 2) {
                [OOCException raise:@"TooManyComponents" format:@"When specifying a collection protocol there must be a property and its subproperty, got %@", propertyName];
            }
            OOCModelObjectProperty* object = [properties valueForKey:[components objectAtIndex:0]];
            object.referenceProperty = [components objectAtIndex:1];
            [properties removeObjectForKey:propertyName];
        }
        else if ([property isKindOfClass:[OOCModelObjectProperty class]] && [[(OOCModelObjectProperty*)property protocols] containsObject:@"OOCSortedIndexGroupBy"]) {
            NSArray* components = [propertyName componentsSeparatedByString:@"__"];
            if (components.count != 2) {
                [OOCException raise:@"TooManyComponents" format:@"When specifying a collection protocol there must be a property and its subproperty, got %@", propertyName];
            }
            property.name = [components objectAtIndex:0];
            property.groupBy = [components objectAtIndex:1];
            property.hasSortedIndex = TRUE;
        }
    }

    NSMutableSet* indices = [NSMutableSet set];
    NSMutableSet* sorted = [NSMutableSet set];
    NSMutableSet* uniques = [NSMutableSet set];
    for (NSString* propertyName in properties) {
        OOCModelProperty* property = [properties valueForKey:propertyName];
        if (property.isUnique) {
            [uniques addObject:propertyName];
        }
        if (property.hasIndex) {
            [indices addObject:propertyName];
        }
        if (property.hasSortedIndex) {
            [sorted addObject:propertyName];
        }
    }

    OOCModelSpec* spec = [[OOCModelSpec alloc] init];
    spec.properties = [properties copy];
    spec.indices = [indices copy];
    spec.uniques = [uniques copy];
    spec.tracked = [tracked copy];
    spec.sorted = [sorted copy];
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

+ (OOCModel*)getCached:(NSString*)id {
    return [[Ohmoc instance] getCached:id model:self];
}

+ (BOOL)isCached:(NSString*)id {
    return [[Ohmoc instance] isCached:id model:self];
}

- (void) dealloc {
    [self.ohmoc removeCached:self];
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

- (OOCModel*)initWithOhmoc:(Ohmoc*)ohmoc {
    if (self = [super initWithOhmoc:ohmoc]) {
        OOCModelSpec* spec = [[self class] spec];
        NSDictionary* properties = spec.properties;
        for (NSString* propertyName in properties) {
            OOCModelProperty* property = [properties valueForKey:propertyName];
            if ([property isKindOfClass:[OOCModelObjectProperty class]]) {
                OOCModelObjectProperty* objProperty = (OOCModelObjectProperty*)property;
                Class klass = objProperty.klass;
                if ([klass isSubclassOfClass:[OOCCollection class]]) {
                    OOCCollection* collection = [klass collectionWithModel:self property:propertyName ohmoc:self.ohmoc modelClass:objProperty.subtype];
                    [self setValue:collection forKey:propertyName];
                }
            }
        }
    }
    return self;
}

- (OOCModel*)initWithId:(NSString*)id ohmoc:(Ohmoc *)ohmoc {
    if (self = [self initWithOhmoc:ohmoc]) {
        self.id = (NSString<OOCUnique>*)id;
    }
    return self;
}

- (void)applyDictionary:(NSDictionary*)properties {
    OOCModelSpec* spec = [[self class] spec];
    for (NSString* key in properties) {
        OOCModelProperty* propertySpec = [spec.properties valueForKey:key];
        if (!propertySpec) {
            continue;
        }
        id value = [properties valueForKey:key];
        if ([value isKindOfClass:[NSNull class]]) {
            [self setValue:nil forKey:key];
        } else {
            [self setValue:value forKey:key];
        }
    }
}

- (instancetype)initWithDictionary:(NSDictionary*)properties ohmoc:(Ohmoc*)ohmoc {
    if (self = [self initWithOhmoc:ohmoc]) {
        [self applyDictionary:properties];
    }
    return self;
}

- (NSString*)key {
    return [@[NSStringFromClass([self class]), self.id] componentsJoinedByString:@":"];
}

- (void) setValue:(id)value forKey:(NSString *)key {
    NSDictionary* classProperties = [[self class] spec].properties;
    if ([classProperties valueForKey:key]) {
        OOCModelProperty* property = [classProperties valueForKey:key];
        if (!property) {
            [OOCException raise:@"UnknownKey" format:@"Unknown key %@", key];
        }
        if (property.readonly) {
            return;
        }
        id val = nil;
        if ([property isKindOfClass:[OOCModelObjectProperty class]]) {
            OOCModelObjectProperty* objectProperty = (OOCModelObjectProperty*)property;
            if (![objectProperty.klass isSubclassOfClass:[NSString class]]
                && [objectProperty.klass conformsToProtocol:@protocol(NSCoding)]
                && ![objectProperty.klass isSubclassOfClass:[NSData class]]
                && [value isKindOfClass:[NSData class]]) {
                val = [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            if ([objectProperty.klass isSubclassOfClass:[NSData class]]) {
                val = value;
            }
        }

        if (!val) {
            if ([value isKindOfClass:[NSData class]]) {
                val = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            } else {
                val = value;
            }
        }

        if ([property isKindOfClass:[OOCModelBasicProperty class]]) {
            OOCModelBasicProperty* basicProperty = (OOCModelBasicProperty*)property;
            // This is bullshit. BOOL is sometimes _C_CHR and sometimes _C_BOOL
            // depending on the context. Since booleans are more common, we
            // have to assume all chars are booleans.
            // But I wish we could support char as well.
            if (basicProperty.identifier == _C_CHR) {
                val = [val boolValue] ? @TRUE : @FALSE;
            }
            // This is bullshit II. For some reason NSString doesn't alwasy have a
            // longValue method. Why? I don't know.
            if (basicProperty.identifier == _C_LNG && ![val respondsToSelector:@selector(longValue)]) {
                val = [NSNumber numberWithLongLong:[val longLongValue]];
            }
        }
        [super setValue:val forKey:key];
    } else if ([key hasSuffix:@"_id"]) {
        NSString* shortkey = [key substringToIndex:key.length - 3];
        OOCModelProperty* property = [classProperties valueForKey:shortkey];
        if (!property) {
            [OOCException raise:@"UnknownKey" format:@"Unknown key %@", key];
        }
        if (property.readonly) {
            return;
        }
        if (![property isKindOfClass:[OOCModelObjectProperty class]]) {
            [OOCException raise:@"ExpectedObject" format:@"Property is not an object property for key '%@'", key];
        }
        OOCModelObjectProperty* objProperty = (OOCModelObjectProperty*)property;
        [self setValue:[objProperty.klass get:[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding]] forKey:shortkey];
    } else {
        [OOCException raise:@"UnknownProperty" format:@"Uknown property %@", key];
    }
}

- (void) load {
    NSArray* properties = [self.ohmoc command:@[@"HGETALL", self.key] binary:TRUE];
    for (NSUInteger i = 0; i < properties.count; i += 2) {
        NSString* key = [[NSString alloc] initWithData:[properties objectAtIndex:i] encoding:NSUTF8StringEncoding];
        id value = [properties objectAtIndex:i + 1];
        [self setValue:value forKey:key];
    }
    [self.ohmoc setCached:self];
}

+ (NSString*)sortedIndexKeyForProperty:(OOCModelProperty*)property groupByValue:(id)groupByValue {
    NSMutableArray* arr = [NSMutableArray arrayWithObjects:NSStringFromClass(self), @"sorted", property.name, nil];
    if (property.groupBy) {
        [arr addObject:property.groupBy];
        [arr addObject:groupByValue];
    }
    return [arr componentsJoinedByString:@":"];
}

- (NSDictionary*) updateSortedIndices {
    NSMutableDictionary* indices = [NSMutableDictionary dictionary];
    OOCModelSpec* spec = [[self class] spec];
    NSDictionary* properties = spec.properties;
    for (NSString* propName in spec.sorted) {
        OOCModelProperty* property = [properties valueForKey:propName];
        id groupByValue = nil;
        if (property.groupBy) {
            groupByValue = [self valueForKey:property.groupBy];
        }
        NSString* key = [[self class] sortedIndexKeyForProperty:property groupByValue:groupByValue];
        [indices setValue:property forKey:key];
    }
    return [indices copy];
}

- (void) pruneSortedIndices {
    if (!self.id) {
        return;
    }
    NSDictionary* indices = [self updateSortedIndices];
    for (NSString* key in indices) {
        OOCModelProperty* property = [indices valueForKey:key];
        if (!property.groupBy) {
            return;
        }
        double oldValue = [[self.ohmoc command:@[@"HGET", self.key, property.groupBy]] doubleValue];
        double newValue = [[self valueForKey:property.name] doubleValue];
        // comparing doubles with == ?! What is this?
        // In theory if the value was not changed, is just the result of
        // deserializing the serialized value, so it should be ok. Right?
        // Worst case scenario, we'll be wasting some CPU cycles
        if (oldValue != newValue) {
            NSString* key = [[self class] sortedIndexKeyForProperty:property groupByValue:[self valueForKey:property.name]];
            [self.ohmoc command:@[@"ZREM", key, self.id]];
        }
    }
}

- (void) addSortedIndices{
    NSDictionary* indices = [self updateSortedIndices];
    for (NSString* key in indices) {
        OOCModelProperty* property = [indices valueForKey:key];
        id value = [self valueForKey:property.name];
        if (!value || [value isKindOfClass:[NSNull class]]) {
            [self.ohmoc command:@[@"ZREM", key, self.id]];
        } else {
            if (![value respondsToSelector:@selector(doubleValue)]) {
                [OOCException raise:@"InvalidSortedProperty" format:@"To use a property as a sorted index, it must implement doubleValue"];
            }
            NSString* score = [NSString stringWithFormat:@"%lf", [value doubleValue]];
            [self.ohmoc command:@[@"ZADD", key, score, self.id]];
        }
    }
}

- (void) removeSortedIndices {
    NSDictionary* indices = [self updateSortedIndices];
    for (NSString* key in indices) {
        [self.ohmoc command:@[@"ZREM", key, self.id]];
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

    NSMutableDictionary* binaryProperties = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableArray* properties = [NSMutableArray array];
    OOCModelSpec* spec = [[self class] spec];
    for (NSString* key in spec.properties) {
        id val = [self valueForKey:key];
        if (val && ![val conformsToProtocol:@protocol(NSFastEnumeration)]) {
            if ([val isKindOfClass:[NSData class]]) {
                [binaryProperties setValue:val forKey:key];
            } else if ([val isKindOfClass:[OOCModel class]]) {
                [properties addObject:[NSString stringWithFormat:@"%@_id", key]];
                [properties addObject:[(OOCModel*)val id]];
            } else {
                if ([val respondsToSelector:@selector(stringValue)]) {
                    val = [val stringValue];
                }
                if (![val isKindOfClass:[NSString class]] && [val conformsToProtocol:@protocol(NSCoding)]) {
                    [binaryProperties setValue:[NSKeyedArchiver archivedDataWithRootObject:val] forKey:key];
                    continue;
                }
                [properties addObject:key];
                [properties addObject:val];
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
                if ([value isKindOfClass:[NSArray class]]) {
                    [indices setValue:value forKey:index];
                } else if ([value isKindOfClass:[NSSet class]]) {
                    [indices setValue:[value allObjects] forKey:index];
                } else if ([value respondsToSelector:@selector(arrayValue)]) {
                    [indices setValue:[value arrayValue] forKey:index];
                } else if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
                    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:0];
                    for (id obj in value) {
                        [arr addObject:obj];
                    }
                    [indices setValue:arr forKey:index];
                } else {
                    [indices setValue:@[value] forKey:index];
                }
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

    if (self.id) {
        [self pruneSortedIndices];
    }
    id ret = [self.ohmoc command:@[@"EVAL", lua_save, @"0", [features messagePack], [properties messagePack], [indices messagePack], [uniques messagePack]]];
    [self setId:ret];
    for (NSString* key in binaryProperties) {
        [self set:key value:[binaryProperties valueForKey:key]];
    }
    [self addSortedIndices];
    [self.ohmoc setCached:self];
}

- (NSString*)indexForProperty:(NSString *)propertyName {
    if (!self.id) {
        [OOCMissingIDException raise:@"MissingID" format:@"MissingID %@", self];
    }
    OOCModelObjectProperty* property = [[[[self class] spec] properties] valueForKey:propertyName];
    NSString* referenceProperty = property.referenceProperty;
    if (!referenceProperty) {
        return [self listForProperty:propertyName];
    }
    return [@[NSStringFromClass(property.subtype), @"indices", [NSString stringWithFormat:@"%@_id", referenceProperty], self.id] componentsJoinedByString:@":"];
}

- (NSString*)listForProperty:(NSString *)propertyName {
    if (!self.id) {
        [OOCMissingIDException raise:@"MissingID" format:@"MissingID %@", self];
    }
    return [@[NSStringFromClass([self class]), self.id, propertyName] componentsJoinedByString:@":"];
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

    [self removeSortedIndices];
    [self.ohmoc command:@[@"EVAL", lua_delete, @"0", [@{@"name": NSStringFromClass([self class]), @"id": self.id, @"key": self.key} messagePack], [uniques messagePack], [[spec.tracked allObjects] messagePack]]];
}

- (id)get:(NSString*)att {
    id property = [self.ohmoc command:@[@"HGET", self.key, att] binary:TRUE];
    [self setValue:property forKey:att];
    return [self valueForKey:att];
}

- (void)set:(NSString*)att value:(id)val {
    if (val == nil || [val isKindOfClass:[NSNull class]]) {
        [self.ohmoc command:@[@"HDEL", self.key, att]];
        [self setValue:nil forKey:att];
    } else {
        [self.ohmoc command:@[@"HSET", self.key, att, val]];
        [self setValue:val forKey:att];
    }
}

+ (OOCSet*) find:(NSDictionary*)dict {
    return [[Ohmoc instance] find:dict model:self];
}

+ (instancetype) with:(NSString*)property is:(id)value {
    return [[Ohmoc instance] with:property is:value model:self];
}

+ (instancetype)get:(NSString*)id {
    return [[Ohmoc instance] get:id model:self];
}

+ (instancetype)create {
    return [[Ohmoc instance] createModel:self];
}

+ (instancetype)create:(NSDictionary*)properties {
    return [[Ohmoc instance] create:properties model:self];
}

+ (OOCSet*)all {
    return [[Ohmoc instance] allModels:self];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)propertyName scoreBetween:(double)min and:(double)max andProperty:(NSString*)filterProperty is:(id)groupByValue range:(NSRange)range reverse:(BOOL)reverse ohmoc:(Ohmoc*)ohmoc {
    NSDictionary* properties = [self spec].properties;
    OOCModelProperty* property;

    if (filterProperty) {
        property = [properties valueForKey:[NSString stringWithFormat:@"%@__%@", propertyName, filterProperty]];
        if (!property.groupBy || !property.hasSortedIndex) {
            [OOCIndexNotFoundException raise:@"SortedIndexMissing" format:@"Trying to query for property %@ with group by %@ on class %@ but no index was found", propertyName, filterProperty, NSStringFromClass(self)];
        }
    } else {
        property = [properties valueForKey:propertyName];
        if (![property hasSortedIndex]) {
            [OOCIndexNotFoundException raise:@"SortedIndexMissing" format:@"Trying to query for property %@ on class %@ but no index was found", propertyName, NSStringFromClass(self)];
        }
    }

    return [OOCList collectionWithBlock:^(void(^block)(NSString*)) {
        NSString* key = [ohmoc tmpKey];
        NSString* minStr = min == (double)-INFINITY ? @"-inf" : [NSString stringWithFormat:@"%lf", min];
        NSString* maxStr = max == (double)INFINITY ? @"+inf" : [NSString stringWithFormat:@"%lf", max];
        NSArray* _ids = [ohmoc command:@[
                                         reverse ? @"ZREVRANGEBYSCORE" : @"ZRANGEBYSCORE",
                                         [self sortedIndexKeyForProperty:property groupByValue:groupByValue],
                                         reverse ? maxStr : minStr,
                                         reverse ? minStr : maxStr,
                                         @"LIMIT",
                                         [NSString stringWithFormat:@"%lu", (long unsigned)range.location],
                                         [NSString stringWithFormat:@"%lu", (long unsigned)range.length + (long unsigned)range.location - 1]
                                         ]];
        if (_ids.count == 0) {
            block(key);
            return;
        }
        NSMutableArray* command = [NSMutableArray arrayWithCapacity:_ids.count + 2];
        [command addObjectsFromArray:@[@"RPUSH", key]];
        [command addObjectsFromArray:_ids];
        [ohmoc command:command];
        block(key);
        [ohmoc command:@[@"DEL", key]];
    } ohmoc:ohmoc modelClass:self];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)property scoreBetween:(double)min and:(double)max range:(NSRange)range reverse:(BOOL)reverse ohmoc:(Ohmoc*)ohmoc {
    return [self collectionWithProperty:property scoreBetween:min and:max andProperty:nil is:nil range:range reverse:reverse ohmoc:ohmoc];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)property scoreBetween:(double)min and:(double)max range:(NSRange)range reverse:(BOOL)reverse {
    return [self collectionWithProperty:property scoreBetween:min and:max range:range reverse:reverse ohmoc:[Ohmoc instance]];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)property scoreBetween:(double)min and:(double)max range:(NSRange)range {
    return [self collectionWithProperty:property scoreBetween:min and:max range:range reverse:FALSE];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)property scoreBetween:(double)min and:(double)max {
    NSRange range;
    range.location = 0;
    range.length = UINT_MAX;
    return [self collectionWithProperty:property scoreBetween:min and:max range:range];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)propertyName scoreBetween:(double)min and:(double)max andProperty:(NSString*)filterProperty is:(id)groupByValue range:(NSRange)range {
    return [self collectionWithProperty:propertyName scoreBetween:min and:max andProperty:filterProperty is:groupByValue range:range reverse:FALSE ohmoc:[Ohmoc instance]];
}

+ (OOCCollection*)collectionWithProperty:(NSString*)property scoreBetween:(double)min and:(double)max ohmoc:(Ohmoc*)ohmoc {
    NSRange range;
    range.location = 0;
    range.length = UINT_MAX;
    return [self collectionWithProperty:property scoreBetween:min and:max range:range reverse:FALSE ohmoc:ohmoc];
}
@end