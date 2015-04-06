//
//  ohmocTests.m
//  ohmocTests
//
//  Created by Sebastian Waisbrot on 04/01/2015.
//  Copyright (c) 2014 Sebastian Waisbrot. All rights reserved.
//

#import "OOCUser.h"
#import "OOCUser2.h"
#import "OOCPost.h"
#import "OOCEvent.h"
#import "OOCContact.h"
#import "OOCComment.h"
#import "OOCBook.h"
#import "OOCAuthor.h"
#import "OOCNode.h"
#import "OOCPerson.h"
#import "Ohmoc.h"
#import "ObjCHirlite.h"
#import "NSArray+arrayWithFastEnumeration.h"

SpecBegin(ohmoc)

describe(@"association", ^{
    [Ohmoc create];
    beforeEach(^{
        [[Ohmoc instance] flush];
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
        [[Ohmoc instance] flush];
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

describe(@"book author", ^{
    __block OOCBook* b1;
    __block OOCBook* b2;
    beforeEach(^{
        b1 = nil;
        b2 = nil;
        [[Ohmoc instance] flush];
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

    it(@"appending an empty set via union", ^{
        OOCSet* res = [[[OOCAuthor find:@{@"book_id": b1.id, @"mood": @"happy"}]
                        union:@{@"book_id": b2.id, @"mood": @"sad"}]
                       union:@{@"book_id": b2.id, @"mood": @"happy"}];
        XCTAssertEqual(2, res.size);
    });

    it(@"revert by applying the original intersection", ^{
        OOCSet* res = [[[OOCAuthor find:@{@"book_id": b1.id, @"mood": @"happy"}]
                        union:@{@"book_id": b2.id, @"mood": @"sad"}]
                       except:@{@"book_id": b1.id, @"mood": @"happy"}];
        XCTAssertEqual(1, res.size);
        for (OOCAuthor* author in res) {
            XCTAssertEqualObjects(author.mood, @"sad");
            XCTAssertEqual(author.book, b2);
        }
    });

    it(@"@myobie usecase", ^{
        OOCSet* res = [[b1.authors find:@{@"mood": @"happy"}] union:@{@"mood": @"sad", @"book_id": b1.id}];
        XCTAssertEqual(res.size, 2);
    });
});

describe(@"indices", ^{
    __block OOCUser* u1, *u2, *u3;
    beforeEach(^{
        u1 = u2 = u3 = nil;
        [[Ohmoc instance] flush];
        u1 = [OOCUser create:@{@"email": @"foo", @"activationCode": @"bar", @"update": @"baz"}];
        u2 = [OOCUser create:@{@"email": @"bar"}];
        u3 = [OOCUser create:@{@"email": @"baz qux"}];
    });

    it(@"be able to find by the given attribute", ^{
        OOCUser* first = [[OOCUser find:@{@"email": @"foo"}] first];
        XCTAssertEqual(first, u1);
    });

    it(@"raise if the index doesn't exist", ^{
        XCTAssertThrowsSpecific([OOCUser find:@{@"address": @"foo"}], OOCIndexNotFoundException);
    });

    it(@"avoid intersections with the all collection", ^{
        [[OOCUser find:@{@"email": @"foo"}] blockWithKey:^(NSString* mykey) {
            XCTAssertEqualObjects(mykey, @"OOCUser:indices:email:foo");
        }];
    });

    it(@"allow multiple chained finds", ^{
        NSUInteger size = [[[[OOCUser find:@{@"email": @"foo"}] find:@{@"activationCode": @"bar"}] find:@{@"update": @"baz"}] size];
        XCTAssertEqual(size, 1);
    });

    it(@"return nil if no results are found", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"foobar"}];
        XCTAssert([res isEmpty]);
        XCTAssertNil([res first]);
    });

    it(@"update indices when changing attribute values", ^{
        u1.email = @"baz";
        [u1 save];

        OOCSet* res = [OOCUser find:@{@"email": @"foo"}];
        XCTAssertEqual(res.size, 0);
        res = [OOCUser find:@{@"email": @"baz"}];
        XCTAssertEqual(res.size, 1);
        XCTAssertEqual(res.first, u1);
    });

    it(@"remove from the index after deleting", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"bar"}];
        XCTAssertEqual(res.size, 1);
        [u2 delete];
        res = [OOCUser find:@{@"email": @"bar"}];
        XCTAssertEqual(res.size, 0);
    });
    it(@"work with attributes that contain spaces", ^{
        OOCSet* res = [OOCUser find:@{@"email": @"baz qux"}];
        XCTAssertEqual(res.size, 1);
        XCTAssertEqual(res.first, u3);
    });
});

describe(@"indices2", ^{
    __block OOCUser* u1, *u2, *u3;
    beforeEach(^{
        u1 = u2 = u3 = nil;
        [[Ohmoc instance] flush];
        u1 = [OOCUser create:@{@"email": @"foo@gmail.com"}];
        u2 = [OOCUser create:@{@"email": @"bar@gmail.com"}];
        u3 = [OOCUser create:@{@"email": @"bazqux@yahoo.com"}];
    });

    it(@"allow indexing by an arbitrary attribute", ^{
        OOCSet* res = [OOCUser find:@{@"emailProvider": @"gmail.com"}];
        NSArray* arr = [NSArray arrayWithFastEnumeration:[res sortBy:@"id"]];
        NSArray* arr2 = @[u1, u2];
        XCTAssertEqualObjects(arr, arr2);
    });
});

describe(@"indices3", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"index bug", ^{
        OOCNode* n = [OOCNode create:@{}];
        n.capacity = 91;
        [n save];

        OOCSet* res = [OOCNode find:@{@"available": @TRUE}];
        XCTAssertEqual(res.size, 0);
        res = [OOCNode find:@{@"available": @FALSE}];
        XCTAssertEqual(res.size, 1);
    });

    it(@"uniques bug", ^{
        OOCNode* n = [OOCNode create:@{}];
        n.capacity = 91;
        [n save];

        OOCNode* n2 = [OOCNode with:@"available" is:@TRUE];
        XCTAssertNil(n2);
        n2 = [OOCNode with:@"available" is:@FALSE];
        XCTAssertEqual(n, n2);
    });
});

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

describe(@"set", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"exists returns false if the given id is not included in the set", ^{
        OOCUser* user = [OOCUser create];
        OOCPost* post = [OOCPost create];
        XCTAssertFalse([user.posts contains:post]);
    });

    it(@"exists returns true if the given id is included in the set", ^{
        OOCUser* user = [OOCUser create];
        OOCPost* post = [OOCPost create];
        post.user = user;
        [post save];
        XCTAssert([user.posts contains:post]);
    });

    it(@"ids returns an array with the ids", ^{
        NSArray* users = @[
                             [OOCUser create:@{@"fname": @"John"}],
                             [OOCUser create:@{@"fname": @"Jane"}],
                             ];
        XCTAssertEqualObjects([users valueForKey:@"id"], [[OOCUser all].ids sortedArrayUsingSelector:@selector(compare:)]);

        OOCSet* res = [[OOCUser find:@{@"fname": @"John"}] union:@{@"fname": @"Jane"}];
        XCTAssertEqualObjects([users valueForKey:@"id"], [res.ids sortedArrayUsingSelector:@selector(compare:)]);
    });
});

describe(@"uniques", ^{
    __block OOCUser2* u;
    beforeEach(^{
        u = nil;
        [[Ohmoc instance] flush];
        u = [OOCUser2 create:@{@"email": @"a@a.com"}];
    });

    it(@"findability", ^{
        XCTAssertEqual([OOCUser2 with:@"email" is:@"a@a.com"], u);
    });

    it(@"raises when it already exists during create", ^{
        XCTAssertThrowsSpecific([OOCUser2 create:@{@"email": @"a@a.com"}], OOCUniqueIndexViolationException);
    });

    it(@"raises when it already exists during save", ^{
        OOCUser2* u2 = [OOCUser2 create:@{@"email": @"b@b.com"}];
        u2.email = @"a@a.com";
        XCTAssertThrowsSpecific([u2 save], OOCUniqueIndexViolationException);
    });
    it(@"raises if the index doesn't exist", ^{
        XCTAssertThrowsSpecific([OOCUser2 find:@{@"address": @"a@a.com"}], OOCIndexNotFoundException);
    });
    it(@"doesn't raise when saving again and again", ^{
        [u save];
    });
    it(@"removes the previous index when changing", ^{
        id exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssertFalse([exists isKindOfClass:[NSNull class]]);

        u.email = @"b@b.com";
        [u save];

        XCTAssertNil([OOCUser2 with:@"email" is:@"a@a.com"]);
        exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);
        XCTAssertEqual(u, [OOCUser2 with:@"email" is:@"b@b.com"]);

        u.email = nil;
        [u save];

        XCTAssertNil([OOCUser2 with:@"email" is:@"b@b.com"]);
        exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"b@b.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);
    });
    it(@"removes the previous index when deleting", ^{
        [u delete];
        XCTAssertNil([OOCUser2 with:@"email" is:@"a@a.com"]);
        id exists = [[Ohmoc instance] command:@[@"HGET", @"OOCUser2:uniques:email", @"a@a.com"]];
        XCTAssert([exists isKindOfClass:[NSNull class]]);

    });
    it(@"unique virtual attribute", ^{
        OOCUser2* u2 = [OOCUser2 create:@{@"email": @"foo@yahoo.com"}];
        XCTAssertEqual([OOCUser2 with:@"provider" is:@"yahoo.com"], u2);

        u.email = @"bar@yahoo.com";
        XCTAssertThrowsSpecific([u save], OOCUniqueIndexViolationException);

        XCTAssertThrowsSpecific([OOCUser2 create:@{@"email": @"baz@yahoo.com"}], OOCUniqueIndexViolationException);
    });
});

describe(@"model", ^{
    beforeEach(^{
        [[Ohmoc instance] flush];
    });
    it(@"booleans", ^{
        NSString* pid;
        @autoreleasepool {
            OOCPost* p = [OOCPost create:@{@"body": @"true", @"published": @FALSE}];
            pid = p.id;
            XCTAssertEqualObjects(p.body, @"true");
            XCTAssertEqual(p.published, false);
            p = nil; // flush cache
        }
        OOCPost* p = [OOCPost get:pid];
        XCTAssertEqualObjects(p.body, @"true");
        XCTAssertEqual(p.published, false);
    });
    it(@"empty model is ok", ^{
        [OOCPost create];
    });
    it(@"get", ^{
        OOCEvent* e = [OOCEvent create:@{@"name": @"Foo"}];
        e.name = @"Bar";
        XCTAssertEqualObjects([e get:@"name"], @"Foo");
        XCTAssertEqualObjects(e.name, @"Foo");
    });
    it(@"set", ^{
        OOCEvent* e;
        @autoreleasepool {
            e = [OOCEvent create:@{@"name": @"Foo"}];
            [e set:@"name" value:@"Bar"];
            XCTAssertEqualObjects([e get:@"name"], @"Bar");
            e = nil;
        }

        @autoreleasepool {
            e = [[OOCEvent all] first];
            XCTAssertEqualObjects([e get:@"name"], @"Bar");
            
            [e set:@"name" value:nil];
            XCTAssertNil(e.name);
            e = nil;
        }

        e = [[OOCEvent all] first];
        XCTAssertNil(e.name);
        int exists = [[[Ohmoc instance] command:@[@"HEXISTS", @"OOCEvent:1", @"name"]] intValue];
        XCTAssertEqual(exists, 0);
    });
    it(@"assign attributes from the hash", ^{
        OOCEvent* e = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        XCTAssertEqualObjects(e.name, @"Ruby Tuesday");
    });
    it(@"assign an ID and save the object", ^{
        OOCEvent* e1 = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        OOCEvent* e2 = [OOCEvent create:@{@"name": @"Ruby Meetup"}];
        XCTAssertEqualObjects(e1.id, @"1");
        XCTAssertEqualObjects(e2.id, @"2");
    });
    it(@"updates attributes", ^{
        OOCEvent* e = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [e applyDictionary:@{@"name": @"Ruby Meetup"}];
        XCTAssertEqualObjects(e.name, @"Ruby Meetup");
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
    it(@"delete the attribute if set to nil", ^{
        OOCEvent* e = [OOCEvent create:@{@"name": @"Ruby Tuesday", @"location": @"Los Angeles"}];
        [e applyDictionary:@{@"location": [NSNull null]}];
        XCTAssertNil(e.location);
    });
    it(@"allow arbitrary id", ^{
        [OOCEvent create:@{@"id": @"abc123", @"name": @"Concert"}];
        XCTAssertEqual([OOCEvent all].size, 1);
        XCTAssertEqualObjects([OOCEvent get:@"abc123"].name, @"Concert");
    });

    it(@"return an instance of Event", ^{
        [[Ohmoc instance] command:@[@"SADD", @"OOCEvent:all", @"1"]];
        [[Ohmoc instance] command:@[@"HSET", @"OOCEvent:1", @"name", @"Concert"]];
        OOCEvent* u = [OOCEvent get:@"1"];
        XCTAssert([u isKindOfClass:[OOCEvent class]]);
        XCTAssertEqualObjects(u.id, @"1");
        XCTAssertEqualObjects(u.name, @"Concert");
    });
    it(@"return an instance of User", ^{
        [[Ohmoc instance] command:@[@"SADD", @"OOCUser:all", @"1"]];
        [[Ohmoc instance] command:@[@"HSET", @"OOCUser:1", @"email", @"albert@example.com"]];
        OOCUser* u = [OOCUser get:@"1"];
        XCTAssert([u isKindOfClass:[OOCUser class]]);
        XCTAssertEqualObjects(u.id, @"1");
        XCTAssertEqualObjects(u.email, @"albert@example.com");
    });
    it(@"change its attributes", ^{
        [[Ohmoc instance] command:@[@"SADD", @"OOCUser:all", @"1"]];
        [[Ohmoc instance] command:@[@"HSET", @"OOCUser:1", @"email", @"albert@example.com"]];
        OOCUser* u = [OOCUser get:@"1"];
        u.email = @"maria@example.com";
        XCTAssertEqualObjects(u.email, @"maria@example.com");
    });
    it(@"save the new values", ^{
        [[Ohmoc instance] command:@[@"SADD", @"OOCUser:all", @"1"]];
        [[Ohmoc instance] command:@[@"HSET", @"OOCUser:1", @"email", @"albert@example.com"]];
        @autoreleasepool {
            OOCUser* u = [OOCUser get:@"1"];
            u.email = @"maria@example.com";
            [u save];
            u.email = @"maria@example.com";
            [u save];
            u = nil;
        }
        XCTAssertFalse([OOCUser isCached:@"1"]);
        XCTAssertEqualObjects([OOCUser get:@"1"].email, @"maria@example.com");
    });
    it(@"create the model if it is new", ^{
        NSString* eid;
        @autoreleasepool {
            OOCEvent* e = [[OOCEvent alloc] initWithOhmoc:[Ohmoc instance]];
            [e applyDictionary:@{@"name": @"Foo"}];
            [e save];
            eid = e.id;
        }
        XCTAssertEqualObjects([OOCEvent get:eid].name, @"Foo");
    });
    it(@"allow to hook into save", ^{
        @autoreleasepool {
            [OOCEvent create:@{@"name": @"Foo"}];
        }
        XCTAssertEqualObjects([[[OOCEvent all] first] slug], @"foo");
    });
    it(@"delete an existing model", ^{
        OOCUser* u = [OOCUser create:@{@"fname": @"John"}];
        [u.posts1 add:[OOCPost create]];
        [u.posts2 add:[OOCPost create]];
        NSString* id = u.id;

        NSString* key = [NSString stringWithFormat:@"OOCUser:%@", id];
        BOOL exists = [[[Ohmoc instance] command:@[@"EXISTS", key]] boolValue];
        XCTAssert(exists);
        exists = [[[Ohmoc instance] command:@[@"EXISTS", [NSString stringWithFormat:@"%@:posts1", key]]] boolValue];
        XCTAssert(exists);
        exists = [[[Ohmoc instance] command:@[@"EXISTS", [NSString stringWithFormat:@"%@:posts2", key]]] boolValue];
        XCTAssert(exists);

        [u delete];

        exists = [[[Ohmoc instance] command:@[@"EXISTS", key]] boolValue];
        XCTAssertFalse(exists);
        exists = [[[Ohmoc instance] command:@[@"EXISTS", [NSString stringWithFormat:@"%@:posts1", key]]] boolValue];
        XCTAssertFalse(exists);
        exists = [[[Ohmoc instance] command:@[@"EXISTS", [NSString stringWithFormat:@"%@:posts2", key]]] boolValue];
        XCTAssertFalse(exists);

        XCTAssertEqual([OOCUser all].size, 0);
    });
    it(@"no leftover keys", ^{
        NSArray* keys = [[Ohmoc instance] command:@[@"KEYS", @"*"]];
        XCTAssertEqualObjects(@[], keys);
        OOCEvent* e = [OOCEvent create:@{@"name": @"Bar"}];

        keys = [[[Ohmoc instance] command:@[@"KEYS", @"*"]] sortedArrayUsingSelector:@selector(compare:)];
        NSArray* expected = @[@"OOCEvent:1:_indices", @"OOCEvent:1", @"OOCEvent:all", @"OOCEvent:id", @"OOCEvent:indices:name:Bar"];
        XCTAssertEqualObjects([expected sortedArrayUsingSelector:@selector(compare:)], keys);

        [e delete];
        keys = [[Ohmoc instance] command:@[@"KEYS", @"*"]];
        XCTAssertEqualObjects(@[@"OOCEvent:id"], keys);

        e = [OOCEvent create:@{@"name": @"Baz"}];
        [[Ohmoc instance] command:@[@"SET", @"OOCEvent:2:attendees", @"something"]];
        keys = [[[Ohmoc instance] command:@[@"KEYS", @"*"]] sortedArrayUsingSelector:@selector(compare:)];
        expected = @[@"OOCEvent:2:_indices", @"OOCEvent:2", @"OOCEvent:all", @"OOCEvent:id", @"OOCEvent:indices:name:Baz", @"OOCEvent:2:attendees"];
        XCTAssertEqualObjects([expected sortedArrayUsingSelector:@selector(compare:)], keys);

        [e delete];
        keys = [[Ohmoc instance] command:@[@"KEYS", @"*"]];
        XCTAssertEqualObjects(@[@"OOCEvent:id"], keys);
    });
    it(@"find all", ^{
        [OOCEvent create:@{@"name": @"Ruby Meetup"}];
        [OOCEvent create:@{@"name": @"Ruby Tuesday"}];

        OOCSet* res = [OOCEvent all];
        NSMutableArray* names = [NSMutableArray arrayWithCapacity:2];
        for (OOCEvent* event in res) {
            [names addObject:event.name];
        }
        NSArray* objs = [names sortedArrayUsingSelector:@selector(compare:)];
        NSArray* expected = @[@"Ruby Meetup", @"Ruby Tuesday"];
        XCTAssertEqualObjects(expected, objs);
    });
    it(@"fetch ids", ^{
        OOCEvent* e1 = [OOCEvent create:@{@"name": @"Ruby Meetup"}];
        OOCEvent* e2 = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        NSArray* objs = [[OOCCollection collectionWithIds:@[e1.id, e2.id] ohmoc:[Ohmoc instance] modelClass:[OOCEvent class]] arrayValue];
        NSArray* expected = @[e1, e2];
        XCTAssertEqualObjects(expected, objs);

    });
    it(@"sort all", ^{
        [OOCPerson create:@{@"name": @"D"}];
        [OOCPerson create:@{@"name": @"C"}];
        [OOCPerson create:@{@"name": @"B"}];
        [OOCPerson create:@{@"name": @"A"}];

        id objects = [[OOCPerson all] sortBy:@"name" get:nil limit:0 offset:0 order:@"ALPHA" store:nil];
        id expected = @[@"A", @"B", @"C", @"D"];
        XCTAssertEqualObjects([[objects arrayValue] valueForKey:@"name"], expected);
    });
    it(@"return an empty array if there are no elements to sort", ^{
        XCTAssertEqualObjects([[[OOCPerson all] sortBy:@"name"] arrayValue], @[]);
    });
    it(@"return the first element sorted by id when using first", ^{
        [OOCPerson create:@{@"name": @"A"}];
        [OOCPerson create:@{@"name": @"B"}];
        XCTAssertEqualObjects([[[OOCPerson all] first] name], @"A");
    });
    it(@"return the first element sorted by name if first receives a sorting option", ^{
        [OOCPerson create:@{@"name": @"B"}];
        [OOCPerson create:@{@"name": @"A"}];
        XCTAssertEqualObjects([[[OOCPerson all] firstBy:@"name" order:@"ALPHA"] name], @"A");
    });
    it(@"return attribute values when the get parameter is specified", ^{
        [OOCPerson create:@{@"name": @"B"}];
        [OOCPerson create:@{@"name": @"A"}];
        NSArray* expected = @[@"A", @"B"];
        XCTAssertEqualObjects([[OOCPerson all] sortBy:@"name" get:@"name" limit:0 offset:0 order:@"ALPHA" store:nil], expected);
    });
    it(@"work on lists", ^{
        OOCPost* post = [OOCPost create:@{@"body": @"Hello world!"}];
        for (NSString* body in @[@"C", @"B", @"A"]) {
            OOCPost* related = [OOCPost create:@{@"body": body}];
            [[Ohmoc instance] command:@[@"RPUSH", [NSString stringWithFormat:@"OOCPost:%@:related", post.id], related.id]];
        }
        OOCList* res = [post.related sortBy:@"body" limit:0 offset:0 order:@"ALPHA ASC" store:nil];
        NSArray* bodies = [[res arrayValue] valueForKey:@"body"];
        NSArray* expected = @[@"A", @"B", @"C"];
        XCTAssertEqualObjects(bodies, expected);
    });

    it(@"finding by one entry in the enumerable", ^{
        OOCPost* p = [OOCPost create:@{@"tags": @"foo bar baz"}];
        NSUInteger size = [[OOCPost find:@{@"tag": @"foo"}] size];
        XCTAssertEqual(size, 1);
        XCTAssert([[OOCPost find:@{@"tag": @"foo"}] contains:p]);
        XCTAssert([[OOCPost find:@{@"tag": @"bar"}] contains:p]);
        XCTAssert([[OOCPost find:@{@"tag": @"baz"}] contains:p]);
        XCTAssertFalse([[OOCPost find:@{@"tag": @"oof"}] contains:p]);
    });
    
    it(@"finding by multiple entries in the enumerable", ^{
        OOCPost* p = [OOCPost create:@{@"tags": @"foo bar baz"}];
        BOOL contains = [[OOCPost find:@{@"tag": @[@"foo", @"bar"]}] contains:p];
        XCTAssert(contains);
        contains = [[OOCPost find:@{@"tag": @[@"foo", @"bar"]}] contains:p];
        XCTAssert(contains);
        contains = [[OOCPost find:@{@"tag": @[@"bar", @"baz"]}] contains:p];
        XCTAssert(contains);
        OOCSet* res = [OOCPost find:@{@"tag": @[@"baz", @"oof"]}];
        XCTAssertFalse([res contains:p]);
        XCTAssertEqual([res size], 0);
    });
    it(@"filter elements", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCPerson* p2 = [OOCPerson create:@{@"name": @"Bertrand"}];
        [OOCPerson create:@{@"name": @"Charles"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];
        [event.attendees add:p2];

        NSArray* attendeesA = [[event.attendees find:@{@"initial": @"A"}] arrayValue];
        NSArray* expected = @[p1];
        XCTAssertEqualObjects(attendeesA, expected);

        NSArray* attendeesB = [[event.attendees find:@{@"initial": @"B"}] arrayValue];
        expected = @[p2];
        XCTAssertEqualObjects(attendeesB, expected);

        NSArray* attendeesC = [[event.attendees find:@{@"initial": @"C"}] arrayValue];
        expected = @[];
        XCTAssertEqualObjects(attendeesC, expected);
    });
    it(@"delete elements", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCPerson* p2 = [OOCPerson create:@{@"name": @"Bertrand"}];
        [OOCPerson create:@{@"name": @"Charles"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];
        [event.attendees add:p2];

        XCTAssertEqual(event.attendees.size, 2);

        [event.attendees remove:p2];
        XCTAssertEqual(event.attendees.size, 1);
    });
    it(@"not be available if the model is new", ^{
        OOCEvent* event = [[OOCEvent alloc] initWithDictionary:@{@"name": @"Ruby Tuesday"} ohmoc:[Ohmoc instance]];
        XCTAssertThrowsSpecific([event.attendees size], OOCMissingIDException);
    });
    it(@"return true if the set includes some member", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCPerson* p2 = [OOCPerson create:@{@"name": @"Bertrand"}];
        OOCPerson* p3 = [OOCPerson create:@{@"name": @"Charles"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];
        [event.attendees add:p2];

        XCTAssert([event.attendees contains:p1]);
        XCTAssert([event.attendees contains:p2]);
        XCTAssertFalse([event.attendees contains:p3]);
    });
    it(@"return instances of the passed model", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];

        XCTAssertEqualObjects(@[p1], [event.attendees arrayValue]);
        XCTAssertEqual(p1, [event.attendees get:p1.id]);
    });
    it(@"return the size of the set", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCPerson* p2 = [OOCPerson create:@{@"name": @"Bertrand"}];
        OOCPerson* p3 = [OOCPerson create:@{@"name": @"Charles"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];
        [event.attendees add:p2];
        [event.attendees add:p3];
        XCTAssertEqual(3, [event.attendees size]);
    });
    it(@"empty the set", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];

        [[Ohmoc instance] command:@[@"DEL", @"OOCEvent:1:attendees"]];
        XCTAssertEqual([event.attendees size], 0);
    });
    it(@"replace the values in the set", ^{
        OOCPerson* p1 = [OOCPerson create:@{@"name": @"Albert"}];
        OOCPerson* p2 = [OOCPerson create:@{@"name": @"Bertrand"}];
        OOCPerson* p3 = [OOCPerson create:@{@"name": @"Charles"}];
        OOCEvent* event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
        [event.attendees add:p1];
        XCTAssertEqualObjects(@[p1], [event.attendees arrayValue]);

        [event.attendees replace:@[p2, p3]];
        NSSet* expected = [NSSet setWithObjects:p2, p3, nil];
        XCTAssertEqualObjects(expected, [NSSet setWithArray:[event.attendees arrayValue]]);
    });
    describe(@"Sorting lists and sets by model attributes", ^{
        __block OOCEvent* event;
        beforeEach(^{
            [[Ohmoc instance] flush];
            event = [OOCEvent create:@{@"name": @"Ruby Tuesday"}];
            char letter = 'D';
            for (NSNumber *logins in @[@4, @2, @5, @3]) {
                OOCPerson* p = [OOCPerson create:@{
                                    @"name": [NSString stringWithFormat:@"%c", letter--],
                                    @"logins": logins,
                                    }];
                [event.attendees add:p];
            }
        });
        after(^{
            event = nil;
        });
        it(@"sort the model instances by the values provided", ^{
            NSArray* names = [[[event.attendees sortBy:@"name" order:@"ALPHA"] arrayValue] valueForKey:@"name"];
            NSArray* expected = @[@"A", @"B", @"C", @"D"];
            XCTAssertEqualObjects(names, expected);
        });
        it(@"accept a number in the limit parameter", ^{
            NSArray* names = [[[event.attendees sortBy:@"name" limit:2 offset:0 order:@"ALPHA"] arrayValue] valueForKey:@"name"];
            NSArray* expected = @[@"A", @"B"];
            XCTAssertEqualObjects(names, expected);
        });
        it(@"use the start parameter as an offset if the limit is provided", ^{
            NSArray* names = [[[event.attendees sortBy:@"name" limit:2 offset:1 order:@"ALPHA"] arrayValue] valueForKey:@"name"];
            NSArray* expected = @[@"B", @"C"];
            XCTAssertEqualObjects(names, expected);
        });
        it(@"use logins attribute for sorting", ^{
            NSArray* names = [[[event.attendees sortBy:@"logins" limit:3 offset:0 order:@"ALPHA"] arrayValue] valueForKey:@"name"];
            NSArray* expected = @[@"C", @"A", @"D"];
            XCTAssertEqualObjects(names, expected);
        });
        it(@"use logins attribute for sorting with key option", ^{
            NSArray* logins = (NSArray*)[event.attendees sortBy:@"logins" get:@"logins" limit:3 offset:0 order:@"ALPHA" store:nil];
            NSArray* expected = @[@"2", @"3", @"4"];
            XCTAssertEqualObjects(logins, expected);
        });
    });

    describe(@"Collections initialized with a Model parameter", ^{
        __block OOCUser* u;
        beforeEach(^{
            [[Ohmoc instance] flush];
            u = [OOCUser create:@{@"email": @"albert@example.com"}];
            [OOCPost create:@{@"body": @"D", @"user": u}];
            [OOCPost create:@{@"body": @"C", @"user": u}];
            [OOCPost create:@{@"body": @"B", @"user": u}];
            [OOCPost create:@{@"body": @"A", @"user": u}];
        });
        afterEach(^{
            u = nil;
        });
        it(@"return instances of the passed model", ^{
            XCTAssertEqual([[u.posts first] class], [OOCPost class]);
        });
        it(@"remove an object from the set", ^{
            OOCPost* p = [u.posts first];
            XCTAssert([u.posts contains:p]);

            [[Ohmoc instance] command:@[@"SREM", @"OOCPost:indices:user_id:1", p.id]];
            XCTAssertFalse([u.posts contains:p]);
        });
    });
});

SpecEnd