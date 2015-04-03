//
//  Ohm.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "OOCException.h"
#import "OOCIndexNotFoundException.h"
#import "OOCMissingIDException.h"
#import "OOCUniqueIndexViolationException.h"
#import "OOCModel.h"
#import "OOCCollection.h"
#import "OOCSet.h"
#import "OOCMutableSet.h"
#import "OOCList.h"
#import "OOCIndex.h"

@class ObjCHirlite;
@interface Ohmoc : NSObject

+ (ObjCHirlite*) rlite;
+ (NSArray*) sortBy:(NSString*)by get:(NSString*)get limit:(NSUInteger)limit offset:(NSUInteger)offset order:(NSString*)order store:(NSString*)store;
+ (void) flush;

@end
