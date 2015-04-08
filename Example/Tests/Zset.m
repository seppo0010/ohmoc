//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(zset)

describe(@"zset", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"the indices exist", ^{
        [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];
        NSArray* drafts = [[Ohmoc instance] command:@[@"ZRANGE", @"OOCPost2:sorted:order:status:draft", @"0", @"-1", @"withscores"]];
        NSArray* expected = @[@2, @20.4, @1, @100];
        XCTAssertEqual(expected.count, drafts.count);
        for (NSUInteger i = 0; i < expected.count; i++) {
            XCTAssertEqual([[drafts objectAtIndex:i] doubleValue], [[expected objectAtIndex:i] doubleValue]);
        }
        NSArray* all = [[Ohmoc instance] command:@[@"ZRANGE", @"OOCPost2:sorted:order", @"0", @"-1", @"withscores"]];
        expected = @[@3, @14.3, @2, @20.4, @1, @100];
        XCTAssertEqual(expected.count, all.count);
        for (NSUInteger i = 0; i < expected.count; i++) {
            XCTAssertEqual([[all objectAtIndex:i] doubleValue], [[expected objectAtIndex:i] doubleValue]);
        }
    });
    it(@"the objects are removed from the indices upon deletion", ^{
        OOCPost2* p1 = [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        OOCPost2* p2 = [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        OOCPost2* p3 = [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];
        [p1 delete];
        [p2 delete];
        [p3 delete];
        NSArray* drafts = [[Ohmoc instance] command:@[@"ZRANGE", @"OOCPost2:sorted:order:status:draft", @"0", @"-1", @"withscores"]];
        NSArray* all = [[Ohmoc instance] command:@[@"ZRANGE", @"OOCPost2:sorted:order", @"0", @"-1", @"withscores"]];
        XCTAssertEqualObjects(drafts, @[]);
        XCTAssertEqualObjects(all, @[]);
    });
    it(@"the indices are updated when the object is modified", ^{
        OOCPost2* p = [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        NSString* score = [[Ohmoc instance] command:@[@"ZSCORE", @"OOCPost2:sorted:order", @"1"]];
        XCTAssertEqualObjects(score, @"100");
        score = [[Ohmoc instance] command:@[@"ZSCORE", @"OOCPost2:sorted:order:status:draft", @"1"]];
        XCTAssertEqualObjects(score, @"100");

        p.order = 123.45;
        [p save];

        score = [[Ohmoc instance] command:@[@"ZSCORE", @"OOCPost2:sorted:order", @"1"]];
        XCTAssertEqualObjects(score, @"123.45");
        score = [[Ohmoc instance] command:@[@"ZSCORE", @"OOCPost2:sorted:order:status:draft", @"1"]];
        XCTAssertEqualObjects(score, @"123.45");
    });

    it(@"can fetch a collection with a range", ^{
        [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        OOCPost2* p2 = [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        OOCPost2* p3 = [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];

        NSArray* res  = [[OOCPost2 collectionWithProperty:@"order" scoreBetween:-INFINITY and:30] arrayValue];
        XCTAssertEqual(res.count, 2);
        XCTAssertEqual([res objectAtIndex:0], p3);
        XCTAssertEqual([res objectAtIndex:1], p2);
    });

    it(@"can fetch a reversed collection with a range", ^{
        [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        OOCPost2* p2 = [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        OOCPost2* p3 = [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];

        NSRange range;
        range.location = 0;
        range.length = 10;
        NSArray* res  = [[OOCPost2 collectionWithProperty:@"order" scoreBetween:-INFINITY and:30 range:range reverse:TRUE] arrayValue];
        XCTAssertEqual(res.count, 2);
        XCTAssertEqual([res objectAtIndex:1], p3);
        XCTAssertEqual([res objectAtIndex:0], p2);
    });

    it(@"can fetch a collection using a minimum", ^{
        [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        OOCPost2* p2 = [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];

        NSArray* res  = [[OOCPost2 collectionWithProperty:@"order" scoreBetween:20 and:30] arrayValue];
        XCTAssertEqual(res.count, 1);
        XCTAssertEqual([res objectAtIndex:0], p2);
    });

    it(@"can fetch an empty collection", ^{
        [OOCPost2 create:@{@"status": @"draft", @"order": @100}];
        [OOCPost2 create:@{@"status": @"draft", @"order": @20.4}];
        [OOCPost2 create:@{@"status": @"published", @"order": @14.3}];

        NSArray* res  = [[OOCPost2 collectionWithProperty:@"order" scoreBetween:10000 and:INFINITY] arrayValue];
        XCTAssertEqual(res.count, 0);
    });
    it(@"throws an exception when the index does not exist", ^{
        XCTAssertThrowsSpecific([OOCUser collectionWithProperty:@"fname" scoreBetween:-INFINITY and:INFINITY], OOCIndexNotFoundException);
    });
});

SpecEnd