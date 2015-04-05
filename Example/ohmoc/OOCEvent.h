//
//  OOCEvent.h
//  ohmoc
//
//  Created by Seppo on 4/3/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"

@protocol OOCPerson;
@interface OOCEvent : OOCModel

@property NSString* name;
@property NSString* location;
@property NSString* slug;
@property OOCSet<OOCPerson>* attendees;

@end
