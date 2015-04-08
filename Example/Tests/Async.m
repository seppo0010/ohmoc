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
            __block NSUInteger i = 0;
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
    it(@"find", ^{
        waitUntil(^(DoneCallback done) {
            __block OOCUser* john;
            __block OOCUser* jane;
            [ohmoc create:@{@"fname": @"John", @"lname": @"Doe", @"status": @"active"} model:[OOCUser class] callback:^(OOCUser* u) { john = u; }];
            [ohmoc create:@{@"fname": @"Jane", @"lname": @"Doe", @"status": @"active"} model:[OOCUser class] callback:^(OOCUser* u) { jane = u; }];
            XCTAssertNil(john);
            XCTAssertNil(jane);
            OOCSet* res = [ohmoc find:@{@"lname": @"Doe"} model:[OOCUser class]];
            NSMutableArray* results = [NSMutableArray arrayWithCapacity:2];
            [res each:^(OOCUser *user, NSUInteger pos, NSUInteger size) {
                XCTAssertEqual(pos, results.count);
                XCTAssertEqual(size, 2);
                [results addObject:user];
                if (results.count == 2) {
                    XCTAssertNotNil(john);
                    XCTAssertNotNil(jane);
                    XCTAssert([results containsObject:john]);
                    XCTAssert([results containsObject:jane]);
                    done();
                }
            }];
        });
    });
    it(@"with", ^{
        waitUntil(^(DoneCallback done) {
            __block OOCUser2* john;
            __block OOCUser2* jane;
            [ohmoc create:@{@"email": @"john@doe.com"} model:[OOCUser2 class] callback:^(OOCUser2* u) { john = u; }];
            [ohmoc create:@{@"email": @"jane@doe.org"} model:[OOCUser2 class] callback:^(OOCUser2* u) { jane = u; }];
            XCTAssertNil(john);
            XCTAssertNil(jane);
            [ohmoc with:@"email" is:@"john@doe.com" model:[OOCUser2 class] callback:^(OOCUser2* u){
                XCTAssertNotNil(john);
                XCTAssertEqual(u, john);
                done();
            }];
        });
    });
    it(@"with not found", ^{
        waitUntil(^(DoneCallback done) {
            __block OOCUser2* john;
            __block OOCUser2* jane;
            [ohmoc create:@{@"email": @"john@doe.com"} model:[OOCUser2 class] callback:^(OOCUser2* u) { john = u; }];
            [ohmoc create:@{@"email": @"jane@doe.org"} model:[OOCUser2 class] callback:^(OOCUser2* u) { jane = u; }];
            XCTAssertNil(john);
            XCTAssertNil(jane);
            [ohmoc with:@"email" is:@"example@example" model:[OOCUser2 class] callback:^(OOCUser2* u){
                XCTAssertNotNil(john);
                XCTAssertNil(u);
                done();
            }];
        });
    });
    it(@"array value", ^{
        waitUntil(^(DoneCallback done) {
            [ohmoc create:@{@"body": @"A"} model:[OOCPost class] callback:nil];
            [ohmoc create:@{@"body": @"C"} model:[OOCPost class] callback:nil];
            [ohmoc create:@{@"body": @"B"} model:[OOCPost class] callback:nil];
            OOCSet* set = [ohmoc allModels:[OOCPost class]];
            [set arrayValueCallback:^(NSArray* arr){
                NSArray* bodies = [[arr valueForKey:@"body"] sortedArrayUsingSelector:@selector(compare:)];
                NSArray* expected = @[@"A", @"B", @"C"];
                XCTAssertEqualObjects(bodies, expected);
                done();
            }];
        });
    });
    it(@"supports zset", ^{
        waitUntil(^(DoneCallback done) {
            [ohmoc create:@{@"status": @"draft", @"order": @100} model:[OOCPost2 class] callback:nil];
            [ohmoc create:@{@"status": @"draft", @"order": @20.4} model:[OOCPost2 class] callback:nil];
            [ohmoc create:@{@"status": @"published", @"order": @14.3} model:[OOCPost2 class] callback:nil];

            OOCCollection* res = [OOCPost2 collectionWithProperty:@"order" scoreBetween:-INFINITY and:INFINITY ohmoc:ohmoc];
            [res arrayValueCallback:^(NSArray* arr){
                NSArray* orders = [arr valueForKey:@"order"];
                NSArray* expected = @[@14.3, @20.4, @100];
                XCTAssertEqualObjects(expected, orders);
                done();
            }];
        });
    });
});

SpecEnd