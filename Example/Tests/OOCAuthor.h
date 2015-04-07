//
//  OOCAuthor.h
//  ohmoc
//
//  Created by Seppo on 4/4/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@class OOCBook;
@interface OOCAuthor : OOCModel

@property OOCBook<OOCIndex>* book;
@property NSString<OOCIndex>* mood;

@end

@protocol OOCAuthor <NSObject>
@end