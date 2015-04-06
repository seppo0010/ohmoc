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
        [self.ohmoc command:@[@"SADD", mykey, submodel.id]];
    }];
}

- (void)remove:(OOCModel*)submodel {
    [self blockWithKey:^(NSString* mykey) {
        [self.ohmoc command:@[@"SREM", mykey, submodel.id]];
    }];
}

- (void)replace:(id<NSFastEnumeration>)models {
    [self blockWithKey:^(NSString* mykey) {
        Ohmoc* ohmoc = self.ohmoc;
        [ohmoc command:@[@"MULTI"]];
        [ohmoc command:@[@"DEL", mykey]];
        for (OOCModel* submodel in models) {
            [ohmoc command:@[@"SADD", mykey, submodel.id]];
        }
        [ohmoc command:@[@"EXEC"]];
    }];
}

@end