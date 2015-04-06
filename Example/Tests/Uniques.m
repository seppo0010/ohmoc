//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(uniques)

describe(@"uniques", ^{
    __block OOCUser2* u;
    beforeEach(^{
        u = nil;
        [[Ohmoc instance] flush];
        u = [OOCUser2 create:@{@"email": @"a@a.com"}];
    });
    
    it(@"findability", ^{
        XCTAssertEqual([OOCUser2 with:@"email" is:@"a@a.com"], u);
    });
    
    it(@"raises when it already exists during create", ^{
        XCTAssertThrowsSpecific([OOCUser2 create:@{@"email": @"a@a.com"}], OOCUniqueIndexViolationException);
    });
    
    it(@"raises when it already exists during save", ^{
        OOCUser2* u2 = [OOCUser2 create:@{@"email": @"b@b.com"}];
        u2.email = @"a@a.com";
        XCTAssertThrowsSpecific([u2 save], OOCUniqueIndexViolationException);
    });
    it(@"raises if the index doesn't exist", ^{
        XCTAssertThrowsSpecific([OOCUser2 find:@{@"address": @"a@a.com"}], OOCIndexNotFoundException);
    });
    it(@"doesn't raise when saving again and again", ^{
        [u save];
    });
    it(@"removes the previous index when changing", ^{
        id exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssertFalse([exists isKindOfClass:[NSNull class]]);
        
        u.email = @"b@b.com";
        [u save];
        
        XCTAssertNil([OOCUser2 with:@"email" is:@"a@a.com"]);
        exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);
        XCTAssertEqual(u, [OOCUser2 with:@"email" is:@"b@b.com"]);
        
        u.email = nil;
        [u save];
        
        XCTAssertNil([OOCUser2 with:@"email" is:@"b@b.com"]);
        exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"b@b.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);
    });
    it(@"removes the previous index when deleting", ^{
        [u delete];
        XCTAssertNil([OOCUser2 with:@"email" is:@"a@a.com"]);
        id exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);
        
    });
    it(@"unique virtual attribute", ^{
        OOCUser2* u2 = [OOCUser2 create:@{@"email": @"foo@yahoo.com"}];
        XCTAssertEqual([OOCUser2 with:@"provider" is:@"yahoo.com"], u2);
        
        u.email = @"bar@yahoo.com";
        XCTAssertThrowsSpecific([u save], OOCUniqueIndexViolationException);
        
        XCTAssertThrowsSpecific([OOCUser2 create:@{@"email": @"baz@yahoo.com"}], OOCUniqueIndexViolationException);
    });
});

SpecEnd