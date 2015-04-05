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
#import "OOCBook.h"
#import "OOCAuthor.h"
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
        XCTAssertEqualObjects(event1.id, @"1");
        XCTAssertEqualObjects(event2.id, @"2");
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
            c1 = nil;
            c2 = nil;
            p = nil;
            [Ohmoc flush];
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
    __block OOCUser* john;
    __block OOCUser* jane;
    beforeEach(^{
        john = nil;
        jane = nil;
        [Ohmoc flush];
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
        long card = [[Ohmoc command:@[@"SCARD", @"OOCUser:indices:status:"]] integerValue];
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
        for (OOCUser* user in res) {
            XCTAssertFalse([user.status isEqualToString:@"inactive"]);
        }
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

describe(@"book author", ^{
    __block OOCBook* b1;
    __block OOCBook* b2;
    beforeEach(^{
        b1 = nil;
        b2 = nil;
        [Ohmoc flush];
        b1 = [OOCBook create:@{}];
        b2 = [OOCBook create:@{}];

        [OOCAuthor create:@{@"book": b1, @"mood": @"happy"}];
        [OOCAuthor create:@{@"book": b1, @"mood": @"sad"}];
        [OOCAuthor create:@{@"book": b2, @"mood": @"sad"}];
    });

    it(@"straight up intersection + union", ^{
        OOCSet* res = [b1.authors find:@{@"mood": @"happy"}];
        XCTAssertEqual(1, res.size);
        res = [b1.authors find:@{@"book_id": b1.id, @"mood": @"sad"}];
        XCTAssertEqual(1, res.size);
        res = [[b1.authors find:@{@"mood": @"happy"}] union:@{@"book_id": b1.id, @"mood": @"sad"}];
        XCTAssertEqual(2, res.size);
    });
});

SpecEnd