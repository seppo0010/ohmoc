//
//  OOCPost.h
//  ohmoc
//
//  Created by Seppo on 4/2/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@class OOCUser;

@interface OOCPost : OOCModel

@property OOCUser<OOCIndex>* user;

@end

@protocol OOCPost <NSObject>
@end