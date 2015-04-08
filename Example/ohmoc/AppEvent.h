//
//  AppEvent.h
//  ohmoc
//
//  Created by Seppo on 4/7/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "Ohmoc.h"

@protocol AppEvent <NSObject>
@end

@interface AppEvent : OOCModel

@property NSString* name;
@property id<OOCIndex> nameMeta;
@property NSDate* date;

@property (readonly) double d_date;
@property (readonly) id<OOCSortedIndex> d_dateMeta;
@property (readonly) int day;
@property id<OOCSortedIndexGroupBy> d_date__day;

+ (int) today;

@end