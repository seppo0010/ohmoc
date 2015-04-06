//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(set)

describe(@"set", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"exists returns false if the given id is not included in the set", ^{
        OOCUser* user = [OOCUser create];
        OOCPost* post = [OOCPost create];
        XCTAssertFalse([user.posts contains:post]);
    });
    
    it(@"exists returns true if the given id is included in the set", ^{
        OOCUser* user = [OOCUser create];
        OOCPost* post = [OOCPost create];
        post.user = user;
        [post save];
        XCTAssert([user.posts contains:post]);
    });
    
    it(@"ids returns an array with the ids", ^{
        NSArray* users = @[
                           [OOCUser create:@{@"fname": @"John"}],
                           [OOCUser create:@{@"fname": @"Jane"}],
                           ];
        XCTAssertEqualObjects([users valueForKey:@"id"], [[OOCUser all].ids sortedArrayUsingSelector:@selector(compare:)]);
        
        OOCSet* res = [[OOCUser find:@{@"fname": @"John"}] union:@{@"fname": @"Jane"}];
        XCTAssertEqualObjects([users valueForKey:@"id"], [res.ids sortedArrayUsingSelector:@selector(compare:)]);
    });
});

SpecEnd