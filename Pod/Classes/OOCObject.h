//
//  OOCObject.h
//  Pods
//
//  Created by Seppo on 4/6/15.
//
//

#import <Foundation/Foundation.h>

@class Ohmoc;
@interface OOCObject : NSObject

@property Ohmoc* ohmoc;

- (instancetype) initWithOhmoc:(Ohmoc*)ohmoc;

@end
