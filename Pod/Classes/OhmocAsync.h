//
//  OhmocAsync.h
//  Pods
//
//  Created by Seppo on 4/6/15.
//
//

#import "Ohmoc.h"

@interface OhmocAsync : Ohmoc {
    NSOperationQueue* queue;
}

@property (readonly) NSOperationQueue* queue;

- (void)with:(NSString*)property is:(id)value model:(Class)modelClass callback:(void(^)(id))callback;
- (void)get:(NSString*)id model:(Class)modelClass callback:(void(^)(id))callback;
- (void)createModel:(Class)modelClass callback:(void(^)(id))callback;
- (void)create:(NSDictionary*)properties model:(Class)modelClass callback:(void(^)(id))callback;

@end
