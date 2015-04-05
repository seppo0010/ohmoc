//
//  OOCPerson.h
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@protocol OOCPerson <NSObject>
@end

@interface OOCPerson : OOCModel

@property NSString* name;
@property (readonly) NSString<OOCIndex>* initial;

@end