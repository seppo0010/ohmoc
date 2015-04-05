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
    [self blockWithKey:^(NSString* mykey) {
        [Ohmoc command:@[@"SADD", mykey, submodel.id]];
    }];
}

- (void)remove:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [Ohmoc command:@[@"SREM", mykey, submodel.id]];
    }];
}

- (void)replace:(id<NSFastEnumeration>)models {
    [self blockWithKey:^(NSString* mykey) {
        [Ohmoc command:@[@"MULTI"]];
        [Ohmoc command:@[@"DEL", mykey]];
        for (OOCModel* submodel in models) {
            [Ohmoc command:@[@"SADD", mykey, submodel.id]];
        }
        [Ohmoc command:@[@"EXEC"]];
    }];
}

@end