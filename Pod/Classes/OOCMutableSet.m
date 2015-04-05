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

- (void)add:(OOCModel*)submodel {
    [Ohmoc command:@[@"SADD", self.key, submodel.id]];
}

- (void)remove:(OOCModel*)submodel {
    [Ohmoc command:@[@"SREM", self.key, submodel.id]];
}

- (void)replace:(id<NSFastEnumeration>)models {
    [Ohmoc command:@[@"MULTI"]];
    [Ohmoc command:@[@"DEL", self.key]];
    for (OOCModel* submodel in models) {
        [Ohmoc command:@[@"SADD", self.key, submodel.id]];
    }
    [Ohmoc command:@[@"EXEC"]];
}

@end