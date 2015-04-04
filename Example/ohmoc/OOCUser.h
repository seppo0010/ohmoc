//
//  OOCUser.h
//  ohmoc
//
//  Created by Seppo on 4/2/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "OOCPost.h"
#import "Ohmoc.h"

@class OOCPost;
@interface OOCUser : OOCModel

@property NSString<OOCIndex>* fname;
@property NSString<OOCIndex>* lname;
@property NSString<OOCIndex>* status;
@property OOCSet<OOCPost>* posts;
@property id<OOCCollection> posts__user;

@end
