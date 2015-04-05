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
@property NSString<OOCIndex>* email;
@property (readonly) NSString<OOCIndex>* emailProvider;
@property NSString<OOCIndex>* update;
@property NSString* activationCode;
@property id<OOCIndex> activationCodeMeta;
@property NSString* status;
@property NSString<OOCIndex>* statusMeta;
@property OOCSet<OOCPost>* posts;
@property id<OOCCollection> posts__user;

@end
