//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(indices)

describe(@"indices", ^{
    __block OOCUser* u1, *u2, *u3;
    beforeEach(^{
        u1 = u2 = u3 = nil;
        [[Ohmoc instance] flush];
        u1 = [OOCUser create:@{@"email": @"foo", @"activationCode": @"bar", @"update": @"baz"}];
        u2 = [OOCUser create:@{@"email": @"bar"}];
        u3 = [OOCUser create:@{@"email": @"baz qux"}];
    });
    
    it(@"be able to find by the given attribute", ^{
        OOCUser* first = [[OOCUser find:@{@"email": @"foo"}] first];
        XCTAssertEqual(first, u1);
    });
    
    it(@"raise if the index doesn't exist", ^{
        XCTAssertThrowsSpecific([OOCUser find:@{@"address": @"foo"}], OOCIndexNotFoundException);
    });
    
    it(@"avoid intersections with the all collection", ^{
        [[OOCUser find:@{@"email": @"foo"}] blockWithKey:^(NSString* mykey) {
            XCTAssertEqualObjects(mykey, @"OOCUser:indices:email:foo");
        }];
    });
    
    it(@"allow multiple chained finds", ^{
        NSUInteger size = [[[[OOCUser find:@{@"email": @"foo"}] find:@{@"activationCode": @"bar"}] find:@{@"update": @"baz"}] size];
        XCTAssertEqual(size, 1);
    });
    
    it(@"return nil if no results are found", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"foobar"}];
        XCTAssert([res isEmpty]);
        XCTAssertNil([res first]);
    });
    
    it(@"update indices when changing attribute values", ^{
        u1.email = @"baz";
        [u1 save];
        
        OOCSet* res = [OOCUser find:@{@"email": @"foo"}];
        XCTAssertEqual(res.size, 0);
        res = [OOCUser find:@{@"email": @"baz"}];
        XCTAssertEqual(res.size, 1);
        XCTAssertEqual(res.first, u1);
    });
    
    it(@"remove from the index after deleting", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"bar"}];
        XCTAssertEqual(res.size, 1);
        [u2 delete];
        res = [OOCUser find:@{@"email": @"bar"}];
        XCTAssertEqual(res.size, 0);
    });
    it(@"work with attributes that contain spaces", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"baz qux"}];
        XCTAssertEqual(res.size, 1);
        XCTAssertEqual(res.first, u3);
    });
});

describe(@"indices2", ^{
    __block OOCUser* u1, *u2, *u3;
    beforeEach(^{
        u1 = u2 = u3 = nil;
        [[Ohmoc instance] flush];
        u1 = [OOCUser create:@{@"email": @"foo@gmail.com"}];
        u2 = [OOCUser create:@{@"email": @"bar@gmail.com"}];
        u3 = [OOCUser create:@{@"email": @"bazqux@yahoo.com"}];
    });
    
    it(@"allow indexing by an arbitrary attribute", ^{
        OOCSet* res = [OOCUser find:@{@"emailProvider": @"gmail.com"}];
        NSArray* arr = [NSArray arrayWithFastEnumeration:[res sortBy:@"id"]];
        NSArray* arr2 = @[u1, u2];
        XCTAssertEqualObjects(arr, arr2);
    });
});

describe(@"indices3", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"index bug", ^{
        OOCNode* n = [OOCNode create:@{}];
        n.capacity = 91;
        [n save];
        
        OOCSet* res = [OOCNode find:@{@"available": @TRUE}];
        XCTAssertEqual(res.size, 0);
        res = [OOCNode find:@{@"available": @FALSE}];
        XCTAssertEqual(res.size, 1);
    });
    
    it(@"uniques bug", ^{
        OOCNode* n = [OOCNode create:@{}];
        n.capacity = 91;
        [n save];
        
        OOCNode* n2 = [OOCNode with:@"available" is:@TRUE];
        XCTAssertNil(n2);
        n2 = [OOCNode with:@"available" is:@FALSE];
        XCTAssertEqual(n, n2);
    });
});

SpecEnd