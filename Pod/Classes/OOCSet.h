//
//  OOCSet.h
//  Pods
//
//  Created by Seppo on 4/1/15.
//
//

#import "OOCCollection.h"

@class OOCModel;
@class OOCList;
@interface OOCSet : OOCCollection

- (id)get:(NSString*)id;
- (OOCSet*)find:(NSDictionary*)dict;
- (OOCSet*)except:(NSDictionary*)dict;
- (OOCSet*)combine:(NSDictionary*)dict;
- (OOCSet*)union:(NSDictionary*)dict;
- (id)first;
- (id)firstBy:(NSString*)by get:(NSString*)get order:(NSString*)order;
- (id)firstBy:(NSString*)by order:(NSString*)order;


@end
