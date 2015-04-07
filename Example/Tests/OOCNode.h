//
//  OOCNode.h
//  ohmoc
//
//  Created by Seppo on 4/5/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OOCModel.h"
#import "Ohmoc.h"

@interface OOCNode : OOCModel

@property (readonly) BOOL available;
@property id<OOCUnique, OOCIndex> availableMeta;
@property int capacity;

@end