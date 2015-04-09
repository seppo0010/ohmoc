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
    it(@"can update multiple objects", ^{
        Ohmoc* ohmoc = [Ohmoc instance];
        @autoreleasepool {
            [ohmoc multi];
            OOCPerson* p1 = [OOCPerson create];
            OOCPerson* p2 = [OOCPerson create];
            OOCPerson* p3 = [OOCPerson create];
            [ohmoc exec];

            [ohmoc multi];
            p1.name = @"Person 1";
            [p1 save];
            p2.name = @"Person 2";
            [p2 save];
            p3.name = @"Person 3";
            [p3 save];
            [ohmoc exec];
        }
        XCTAssertFalse([OOCPerson isCached:@"1"]);
        NSArray* names = [[[[OOCPerson all] arrayValue] valueForKey:@"name"] sortedArrayUsingSelector:@selector(compare:)];
        NSArray* expected = @[@"Person 1", @"Person 2", @"Person 3"];
        XCTAssertEqualObjects(names, expected);
    });
});

SpecEnd