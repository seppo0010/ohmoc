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
});

SpecEnd