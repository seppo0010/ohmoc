//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(async)

describe(@"async", ^{
    __block OhmocAsync* ohmoc;
    beforeEach(^{
        ohmoc = [[OhmocAsync alloc] initAllowDuplicates:TRUE];
    });
    it(@"query", ^{
        waitUntil(^(DoneCallback done) {
            [ohmoc createModel:[OOCPost class] callback:nil];
            [ohmoc createModel:[OOCPost class] callback:nil];
            [ohmoc createModel:[OOCPost class] callback:nil];
            OOCSet* set = [ohmoc allModels:[OOCPost class]];
            NSMutableArray* posts = [NSMutableArray arrayWithCapacity:3];
            [set each:^(NSUInteger size, OOCPost*post) {
                XCTAssertEqual(size, 3);
                XCTAssertFalse([posts containsObject:post.id]);
                [posts addObject:post.id];
                if (posts.count == size) {
                    done();
                }
            }];
        });
    });
});

SpecEnd