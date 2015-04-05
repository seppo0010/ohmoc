//
//  OOCBook.h
//  ohmoc
//
//  Created by Seppo on 4/4/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"

@protocol OOCAuthor;
@interface OOCBook : OOCModel

@property OOCSet<OOCAuthor>* authors;

@end
