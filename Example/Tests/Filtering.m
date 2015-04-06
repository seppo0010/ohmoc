//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(filtering)

describe(@"filtering", ^{
    __block OOCUser* john;
    __block OOCUser* jane;
    beforeEach(^{
        john = nil;
        jane = nil;
        [[Ohmoc instance] flush];
        john = [OOCUser create:@{@"fname": @"John", @"lname": @"Doe", @"status": @"active"}];
        jane = [OOCUser create:@{@"fname": @"Jane", @"lname": @"Doe", @"status": @"active"}];
    });
    it(@"findability", ^{
        NSUInteger size = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"John"}] size];
        XCTAssertEqual(1, size);
        BOOL contains = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"John"}] contains:john];
        XCTAssert(contains);
        
        size = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"Jane"}] size];
        XCTAssertEqual(1, size);
        contains = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"Jane"}] contains:jane];
        XCTAssert(contains);
    });
    it(@"sets aren't mutable", ^{
        OOCCollection* collection = [OOCUser find:@{@"lname": @"Doe"}];
        BOOL canAdd = [collection respondsToSelector:@selector(add:)];
        XCTAssertFalse(canAdd);
        
        collection = [OOCUser find:@{@"lname": @"Doe", @"fname": @"John"}];
        canAdd = [collection respondsToSelector:@selector(add:)];
        XCTAssertFalse(canAdd);
    });
    it(@"first", ^{
        OOCSet* set = [OOCUser find:@{@"lname": @"Doe", @"status": @"active"}];
        OOCUser* first = [set firstBy:@"fname" order:@"ALPHA"];
        XCTAssertEqual(first, jane);
        first = [set firstBy:@"fname" order:@"ALPHA DESC"];
        XCTAssertEqual(first, john);
        
        NSString* firstName = [set firstBy:@"fname" get:@"fname" order:@"ALPHA"];
        XCTAssertEqualObjects(firstName, jane.fname);
        firstName = [set firstBy:@"fname" get:@"fname" order:@"ALPHA DESC"];
        XCTAssertEqualObjects(firstName, john.fname);
    });
    
    it(@"contains", ^{
        OOCSet* set = [OOCUser find:@{@"lname": @"Doe", @"status": @"active"}];
        BOOL contains = [set contains:jane];
        XCTAssert(contains);
        contains = [set contains:john];
        XCTAssert(contains);
        
        set = [OOCUser find:@{@"fname": @"Jane", @"status": @"active"}];
        contains = [set contains:jane];
        XCTAssert(contains);
        contains = [set contains:john];
        XCTAssertFalse(contains);
    });
    it(@"except", ^{
        [OOCUser create:@{@"status": @"inactive", @"lname": @"Doe"}];
        OOCSet* res = [[OOCUser find:@{@"lname": @"Doe"}] except:@{@"status": @"inactive"}];
        XCTAssertEqual(res.size, 2);
        BOOL contains = [res contains:john];
        XCTAssert(contains);
        contains = [res contains:jane];
        XCTAssert(contains);
        
        res = [[OOCUser all] except:@{@"status": @"inactive"}];
        XCTAssertEqual(res.size, 2);
        contains = [res contains:john];
        XCTAssert(contains);
        contains = [res contains:jane];
        XCTAssert(contains);
    });
    it(@"except unions keys when passing an array", ^{
        OOCUser* expected = [OOCUser create:@{@"fname": @"Jean", @"status": @"inactive"}];
        
        OOCSet* res = [[OOCUser find:@{@"status": @"inactive"}] except:@{@"fname": @[john.fname, jane.fname]}];
        
        XCTAssertEqual(res.size, 1);
        BOOL contains = [res contains:expected];
        XCTAssert(contains);
        
        res = [[OOCUser all] except:@{@"fname": @[john.fname, jane.fname]}];
        XCTAssertEqual(res.size, 1);
        contains = [res contains:expected];
        XCTAssert(contains);
    });
    it(@"indices bug related to a nil attribute", ^{
        OOCUser* _out = [OOCUser create:@{@"lname": @"Doe"}];
        _out.status = @"inactive";
        [_out save];
        long card = [[[Ohmoc instance] command:@[@"SCARD", @"OOCUser:indices:status:"]] integerValue];
        XCTAssertEqual(0, card);
    });
    it(@"union", ^{
        [OOCUser create:@{@"status": @"super", @"lname": @"Doe"}];
        OOCUser* included = [OOCUser create:@{@"status": @"inactive", @"lname": @"Doe"}];
        OOCSet* res = [[OOCUser find:@{@"status": @"active"}] union:@{@"status": @"inactive"}];
        
        XCTAssertEqual(res.size, 3);
        BOOL contains = [res contains:john];
        XCTAssert(contains);
        contains = [res contains:jane];
        XCTAssert(contains);
        contains = [res contains:included];
        XCTAssert(contains);
        
        res = [[[OOCUser find:@{@"status": @"active"}] union:@{@"status": @"inactive"}] find:@{@"lname": @"Doe"}];
        BOOL hasInactive = false;
        for (OOCUser* user in res) {
            hasInactive = [user.status isEqualToString:@"inactive"];
            if (hasInactive) {
                break;
            }
        }
        XCTAssert(hasInactive);
    });
    it(@"combine", ^{
        OOCSet* res = [[OOCUser find:@{@"status": @"active"}] combine:@{@"fname": @[@"John", @"Jane"]}];
        XCTAssertEqual(res.size, 2);
        BOOL contains = [res contains:john];
        XCTAssert(contains);
        contains = [res contains:jane];
        XCTAssert(contains);
    });
});

SpecEnd