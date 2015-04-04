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

@interface OOCPost : OOCModel

@property OOCUser<OOCIndex>* user;
@property OOCList<OOCComment>* comments;

@end

@protocol OOCPost <NSObject>
@end