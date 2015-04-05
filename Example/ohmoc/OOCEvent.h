//
//  OOCEvent.h
//  ohmoc
//
//  Created by Seppo on 4/3/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@protocol OOCPerson;
@interface OOCEvent : OOCModel

@property NSString* name;
@property id<OOCIndex> nameMeta;
@property NSString* location;
@property NSString* slug;
@property OOCMutableSet<OOCPerson>* attendees;

@end
