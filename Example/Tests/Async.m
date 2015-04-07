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
            // no need to wait for callback since calls are enqueued in order
            [ohmoc createModel:[OOCPost class] callback:nil];
            [ohmoc createModel:[OOCPost class] callback:nil];
            [ohmoc createModel:[OOCPost class] callback:nil];
            OOCSet* set = [ohmoc allModels:[OOCPost class]];
            NSMutableArray* posts = [NSMutableArray arrayWithCapacity:3];
            __block NSUInteger i = 0;;
            [set each:^(OOCPost*post, NSUInteger pos, NSUInteger size) {
                XCTAssertEqual(pos, i);
                i++;
                XCTAssertEqual(size, 3);
                XCTAssertFalse([posts containsObject:post.id]);
                [posts addObject:post.id];
                if (posts.count == size) {
                    done();
                }
            }];
        });
    });
    it(@"empty query", ^{
        waitUntil(^(DoneCallback done) {
            OOCSet* set = [ohmoc allModels:[OOCPost class]];
            [set each:^(OOCPost*post, NSUInteger pos, NSUInteger size) {
                XCTAssertEqual(size, 0);
                done();
            }];
        });
    });
    it(@"create", ^{
        waitUntil(^(DoneCallback done) {
            [ohmoc create:@{} model:[OOCPost class] callback:^(OOCPost* post){
                XCTAssert(post.id);
                done();
            }];
        });
    });
});

SpecEnd