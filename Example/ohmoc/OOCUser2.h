//
//  OOCUser2.h
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"

@interface OOCUser2 : OOCModel

@property NSString<OOCUnique>* email;
@property (readonly) NSString<OOCUnique>* provider;

@end