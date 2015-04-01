//
//  OOCMutableSet.m
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCMutableSet.h"
#import "OOCModel.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"

@implementation OOCMutableSet

- (ObjCHirlite*)conn {
    return [Ohmoc rlite];
}

- (void)add:(OOCModel*)submodel {
    [[self conn] command:@[@"SADD", self.key, submodel.id]];
}

- (void)remove:(OOCModel*)submodel {
    [[self conn] command:@[@"SREM", self.key, submodel.id]];
}

- (void)replace:(id<NSFastEnumeration>)models {
    ObjCHirlite* conn = [self conn];
    [conn command:@[@"MULTI"]];
    [conn command:@[@"DEL", self.key]];
    for (OOCModel* submodel in models) {
        [conn command:@[@"SADD", self.key, submodel.id]];
    }
    [conn command:@[@"EXEC"]];
}

@end