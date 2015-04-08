//
//  AppEvent.m
//  ;
//
//  Created by Seppo on 4/7/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "AppEvent.h"

@implementation AppEvent

+ (int)dayForDate:(NSDate*)date {
    return [date timeIntervalSince1970] / (24 * 60 * 60);
}

+ (int) today {
    return [self dayForDate:[NSDate date]];
}

- (double) d_date {
    return [self.date timeIntervalSince1970];
}

- (int) day {
    return [[self class] dayForDate:self.date];
}

@end
