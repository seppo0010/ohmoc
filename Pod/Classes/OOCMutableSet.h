//
//  OOCMutableSet.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCSet.h"

@interface OOCMutableSet : OOCSet

- (void)add:(OOCModel*)model;
- (void)remove:(OOCModel*)model;

@end
