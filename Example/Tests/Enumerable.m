//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(enumerable)

describe(@"enumerable", ^{
    describe(@"set", ^{
        __block OOCContact* john;
        __block OOCContact* jane;
        
        beforeEach(^{
            [[Ohmoc instance] flush];
            john = [OOCContact create:@{@"name": @"John Doe"}];
            jane = [OOCContact create:@{@"name": @"John Doe"}];
        });
        afterEach(^{
            john = nil;
            jane = nil;
        });
        
        it(@"Set as an Enumerator", ^{
            NSUInteger count = 0;
            for (OOCContact* contact in [OOCContact all]) {
                count++;
                if (contact != john && contact != jane) {
                    [NSException raise:@"UnknownContact" format:@"Expected contact to be john or jane, got %@ instead", contact];
                }
            }
            XCTAssertEqual(count, 2);
        });
        it(@"select", ^{
            // todo?
        });
    });
    describe(@"list", ^{
        __block OOCComment* c1;
        __block OOCComment* c2;
        __block OOCPost* p;
        
        beforeEach(^{
            c1 = nil;
            c2 = nil;
            p = nil;
            [[Ohmoc instance] flush];
            c1 = [OOCComment create:@{}];
            c2 = [OOCComment create:@{}];
            p = [OOCPost create:@{}];
            [p.comments push:c1];
            [p.comments push:c2];
        });
        
        it(@"List size", ^{
            XCTAssertEqual(p.comments.size, 2);
        });
        it(@"List as Enumerator", ^{
            NSUInteger count = 0;
            for (OOCComment* c in p.comments) {
                count++;
                if (c != c1 && c != c2) {
                    [NSException raise:@"UnknownComment" format:@"Expected comment to be c1 or c2, got %@ instead", c];
                }
            }
            XCTAssertEqual(count, 2);
        });
    });
});

SpecEnd