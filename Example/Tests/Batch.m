//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(batch)

describe(@"batch", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"can do an empty multi/exec", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        [ohmoc multi];
        [ohmoc exec];
    });
    it(@"can create an object", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        [ohmoc multi];
        OOCPerson* p = [OOCPerson create];
        [ohmoc exec];
        XCTAssertEqual([[OOCPerson all] first], p);
    });
    it(@"can create multiple objects", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        [ohmoc multi];
        OOCPerson* p1 = [OOCPerson create];
        OOCPerson* p2 = [OOCPerson create];
        OOCPerson* p3 = [OOCPerson create];
        OOCPost* post = [OOCPost create];
        [ohmoc exec];
        NSArray* personas = [[OOCPerson all] arrayValue];
        XCTAssertEqual(personas.count, 3);
        XCTAssert([personas containsObject:p1]);
        XCTAssert([personas containsObject:p2]);
        XCTAssert([personas containsObject:p3]);
        NSArray* posts = [[OOCPost all] arrayValue];
        NSArray* expected = @[post];
        XCTAssertEqualObjects(posts, expected);
        XCTAssertEqual(post, [posts objectAtIndex:0]);
    });
    it(@"cannot edit object being created", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        @autoreleasepool {
            [ohmoc multi];
            OOCUser* user = [OOCUser create];
            user.fname = (id)@"charlie";
            XCTAssertThrowsSpecific([user save], OOCMissingIDException);
            [ohmoc exec];
        }
        XCTAssertEqual([[OOCUser all] size], 1);
    });
    it(@"can edit object multiple times not being created", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        @autoreleasepool {
            OOCUser* user = [OOCUser create];
            [ohmoc multi];
            user.fname = (id)@"charlie";
            [user save];
            user.lname = (id)@"brown";
            [user save];
            [ohmoc exec];
        }
        XCTAssertEqual([[OOCUser all] size], 1);
        OOCUser* user = [[OOCUser all] first];
        XCTAssertEqualObjects(user.fname, @"charlie");
        XCTAssertEqualObjects(user.lname, @"brown");
    });
});

SpecEnd