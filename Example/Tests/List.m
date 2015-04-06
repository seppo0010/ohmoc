//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(list)

describe(@"list", ^{
    __block OOCPost* p;
    __block OOCComment* c1;
    __block OOCComment* c2;
    __block OOCComment* c3;
    beforeEach(^{
        p = nil;
        c1 = c2 = c3 = nil;
        [[Ohmoc instance] flush];
        p = [OOCPost create:@{}];
        c1 = [OOCComment create:@{}];
        c2 = [OOCComment create:@{}];
        c3 = [OOCComment create:@{}];
        [p.comments push:c1];
        [p.comments push:c2];
        [p.comments push:c3];
    });
    
    it(@"contains", ^{
        BOOL contains = [p.comments contains:c1];
        XCTAssert(contains);
        contains = [p.comments contains:c2];
        XCTAssert(contains);
        contains = [p.comments contains:c3];
        XCTAssert(contains);
    });
    
    it(@"first / last / size / empty?", ^{
        XCTAssertEqual(3, p.comments.size);
        XCTAssertEqual(c1, p.comments.first);
        XCTAssertEqual(c3, p.comments.last);
        XCTAssertFalse(p.comments.isEmpty);
    });
    
    it(@"replace", ^{
        OOCComment* c4 = [OOCComment create];
        [p.comments replace:@[c4]];
        XCTAssertEqualObjects([p.comments ids], @[c4.id]);
    });
    
    it(@"push / unshift", ^{
        OOCComment* c4 = [OOCComment create];
        OOCComment* c5 = [OOCComment create];
        
        [p.comments unshift:c4];
        [p.comments push:c5];
        
        XCTAssertEqual(c4, p.comments.first);
        XCTAssertEqual(c5, p.comments.last);
    });
    
    it(@"delete", ^{
        [p.comments remove:c1];
        XCTAssertEqual(2, p.comments.size);
        XCTAssertFalse([p.comments contains:c1]);
        
        [p.comments remove:c2];
        XCTAssertEqual(1, p.comments.size);
        XCTAssertFalse([p.comments contains:c2]);
        
        [p.comments remove:c3];
        XCTAssertEqual(0, p.comments.size);
        XCTAssertFalse([p.comments contains:c3]);
        
        XCTAssert([p.comments isEmpty]);
    });
    
    it(@"deleting main model cleans up the collection", ^{
        NSString* listkey = [@[NSStringFromClass([OOCPost class]), p.id, @"comments"] componentsJoinedByString:@":"];
        
        BOOL exists = [[[Ohmoc instance] command:@[@"EXISTS", listkey]] boolValue];
        XCTAssert(exists);
        [p delete];
        exists = [[[Ohmoc instance] command:@[@"EXISTS", listkey]] boolValue];
        XCTAssertFalse(exists);
    });
    
    it(@"ids returns an array with the ids", ^{
        NSArray* idList = @[c1.id, c2.id, c3.id];
        XCTAssertEqualObjects(p.comments.ids, idList);
    });
    
    it(@"range", ^{
        NSRange range;
        range.location = 0;
        range.length = 100;
        OOCCollection* sublist = [p.comments collectionWithRange:range];
        XCTAssertEqual(sublist.size, 3);
        
        range.location = 0;
        range.length = 3;
        sublist = [p.comments collectionWithRange:range];
        NSArray* expected = @[c1.id, c2.id, c3.id];;
        XCTAssertEqualObjects(sublist.ids, expected);
        
        range.location = 0;
        range.length = 2;
        sublist = [p.comments collectionWithRange:range];
        expected = @[c1.id, c2.id];;
        XCTAssertEqualObjects(sublist.ids, expected);
        
        range.location = 1;
        range.length = 2;
        sublist = [p.comments collectionWithRange:range];
        expected = @[c2.id, c3.id];;
        XCTAssertEqualObjects(sublist.ids, expected);
    });
});

SpecEnd