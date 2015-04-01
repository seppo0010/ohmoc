//
//  OOCList.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCCollection.h"

@interface OOCList : OOCCollection

- (id)objectAtIndex:(NSInteger)index;
- (OOCModel*)first;
- (OOCModel*)last;
- (OOCCollection*)collectionWithRange:(NSRange)range;
- (void)replace:(id<NSFastEnumeration>)models;
- (void)push:(OOCModel*)model;
- (void)unshift:(OOCModel*)model;
- (void)remove:(OOCModel*)model;
- (NSArray*)ids;

@end