//
//  ohmocTests.m
//  ohmocTests
//
//  Created by Sebastian Waisbrot on 04/01/2015.
//  Copyright (c) 2014 Sebastian Waisbrot. All rights reserved.
//

#import "OOCUser.h"
#import "OOCPost.h"
#import "OOCEvent.h"
#import "OOCContact.h"
#import "OOCComment.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"

SpecBegin(ohmoc)

describe(@"association", ^{
    beforeEach(^{
        [Ohmoc flush];
    });
    it(@"basic shake and bake", ^{
        OOCUser* u = [OOCUser create:@{}];
        OOCPost* p = [OOCPost create:@{@"user": u}];
        XCTAssert([u.posts contains:p]);
        OOCPost* p2 = [u.posts get:p.id];
        XCTAssertEqualObjects(u, p2.user);
    });
    it(@"weak memoization", ^{
        OOCUser* u;
        NSString* uid;
        OOCPost* p;
        NSString* pid;
        @autoreleasepool {
            u = [OOCUser create:@{}];
            p = [OOCPost create:@{@"user": u}];
            pid = p.id;
            uid = u.id;
            XCTAssert([OOCPost isCached:pid]);
            XCTAssert([OOCUser isCached:uid]);
            XCTAssertNotNil(p.user.id);
            u = nil;
            p = nil;
        }
        XCTAssertFalse([OOCUser isCached:uid]);
        XCTAssertFalse([OOCPost isCached:pid]);
        p = [OOCPost get:pid];
        XCTAssert([OOCPost isCached:pid]);
        XCTAssert([OOCPost isCached:uid]);
        XCTAssertNotNil(p.user.id);
    });
});

describe(@"connection", ^{
    beforeEach(^{
        [Ohmoc flush];
    });
    // TODO
});

describe(@"core", ^{
    beforeEach(^{
        [Ohmoc flush];
    });
    it(@"assign attributes from the hash", ^{
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        XCTAssertEqualObjects(event.name, @"Ruby Tuesday");
    });
    
    it(@"assign an ID and save the object", ^{
        OOCEvent* event1 = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        OOCEvent* event2 = [OOCEvent create:@{@"name": @"Ruby Meetup"}];
        // FIXME: these should be 1 and 2
        XCTAssertEqualObjects(event1.id, @"2");
        XCTAssertEqualObjects(event2.id, @"3");
    });
    
    it(@"save the attributes in UTF8", ^{
        NSString* eid;
        @autoreleasepool {
            OOCEvent* event = [OOCEvent create:@{@"name": @"32° Kisei-sen"}];
            eid = event.id;
        }
        XCTAssertFalse([OOCEvent isCached:eid]);
        OOCEvent* event = [OOCEvent get:eid];
        XCTAssertEqualObjects(event.name, @"32° Kisei-sen");
    });
});

describe(@"enumerable", ^{
    describe(@"set", ^{
        __block OOCContact* john;
        __block OOCContact* jane;
        
        beforeEach(^{
            [Ohmoc flush];
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

describe(@"filtering", ^{
    __block OOCUser* u1;
    __block OOCUser* u2;
    beforeEach(^{
        u1 = [OOCUser create:@{@"fname": @"John", @"lname": @"Doe", @"status": @"active"}];
        u2 = [OOCUser create:@{@"fname": @"Jane", @"lname": @"Doe", @"status": @"active"}];
    });
    it(@"findability", ^{
        NSUInteger size = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"John"}] size];
        XCTAssertEqual(1, size);
        BOOL contains = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"John"}] contains:u1];
        XCTAssert(contains);

        size = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"Jane"}] size];
        XCTAssertEqual(1, size);
        contains = [[OOCUser find:@{@"lname": @"Doe", @"fname": @"Jane"}] contains:u2];
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
});

SpecEnd
