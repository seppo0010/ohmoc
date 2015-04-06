//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"
#import "MessagePack.h"

SpecBegin(types)

describe(@"types", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });

    it(@"create and fetch", ^{
#define B1 TRUE
#define B2 TRUE
#define D1 123.456
#define F1 0.456f
#define F2 0.458f
#define I1 1234
#define I2 15512
#define L1 123124
#define LL1 12341251551
#define S1 @"hello world!"
        char *_d2 = "A\0C";
        NSData* d2 = [NSData dataWithBytes:_d2 length:3];
        NSDate* d3 = [NSDate date];
        NSString* tid;
        @autoreleasepool {
            OOCTypes* t = [OOCTypes create:@{
                               @"b1": @B1,
                               @"b2": @B2,
                               @"d1": @D1,
                               @"d2": d2,
                               @"d3": d3,
                               @"f1": @F1,
                               @"f2": @F2,
                               @"i1": @I1,
                               @"i2": @I2,
                               @"l1": @L1,
                               @"ll1": @LL1,
                               @"s1": S1,
                               }];
            tid = t.id;
        }
        XCTAssertFalse([OOCTypes isCached:tid]);
        OOCTypes* t = [OOCTypes get:tid];
        XCTAssertEqual(t.b1, B1);
        XCTAssertEqual(t.b2, B2);
        XCTAssertEqual(t.d1, D1);
        XCTAssertEqualObjects(t.d2, d2);
        XCTAssertEqualObjects(t.d3, d3);
        XCTAssertEqual(t.f1, F1);
        XCTAssertEqual(t.f2, F2);
        XCTAssertEqual(t.i1, I1);
        XCTAssertEqual(t.i2, I2);
        XCTAssertEqual(t.l1, L1);
        XCTAssertEqual(t.ll1, LL1);
        XCTAssertEqualObjects(t.s1, S1);
    });
});

SpecEnd