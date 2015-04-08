//
//  OOCPost2.h
//  ohmoc
//
//  Created by Seppo on 4/7/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import <Ohmoc.h>

@interface OOCPost2 : OOCModel

@property NSString* status;
@property double order;
@property id<OOCSortedIndex> orderMeta;
@property id<OOCSortedIndexGroupBy> order__status;

@end
