//
//  OOCBook.h
//  ohmoc
//
//  Created by Seppo on 4/4/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"

@protocol OOCAuthor;
@protocol OOCCollection;
@interface OOCBook : OOCModel

@property OOCSet<OOCAuthor>* authors;
@property id<OOCCollection> authors__book;

@end
