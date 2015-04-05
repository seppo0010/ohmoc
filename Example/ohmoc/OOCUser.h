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
@property NSString* email;
@property id<OOCIndex> emailMeta;
@property (readonly) NSString<OOCIndex>* emailProvider;
@property NSString<OOCIndex>* update;
@property NSString* activationCode;
@property id<OOCIndex> activationCodeMeta;
@property NSString* status;
@property NSString<OOCIndex>* statusMeta;
@property OOCSet<OOCPost>* posts;
@property OOCMutableSet<OOCPost>* posts1;
@property OOCMutableSet<OOCPost>* posts2;
@property id<OOCCollection> posts__user;

@end
