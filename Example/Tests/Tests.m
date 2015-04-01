//
//  ohmocTests.m
//  ohmocTests
//
//  Created by Sebastian Waisbrot on 04/01/2015.
//  Copyright (c) 2014 Sebastian Waisbrot. All rights reserved.
//

#import "OOCUser.h"
#import "OOCPost.h"

SpecBegin(ohmoc)

describe(@"association", ^{
    __block OOCUser* u;
    __block OOCPost* p;
    before(^{
        u = [OOCUser create:@{}];
        p = [OOCPost create:@{@"user": u}];
    });
    it(@"basic shake and bake", ^{
        XCTAssert([u.posts contains:p]);
        OOCPost* p2 = [u.posts get:p.id];
        XCTAssertEqualObjects(u, p2.user);
    });
});

SpecEnd
