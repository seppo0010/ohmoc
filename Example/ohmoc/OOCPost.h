//
//  OOCPost.h
//  ohmoc
//
//  Created by Seppo on 4/2/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@protocol OOCComment;
@class OOCComment;
@class OOCUser;

@protocol OOCPost <NSObject>
@end

@interface OOCPost : OOCModel

@property NSString* body;
@property BOOL published;
@property OOCSet<OOCPost>* related;
@property NSString* tags;
@property (readonly) NSSet<OOCIndex>* tag;

@property OOCUser* user;
@property id<OOCIndex> userMeta;
@property OOCList<OOCComment>* comments;

@end