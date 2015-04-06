//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(model)

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

describe(@"multi-ohmoc", ^{
    __block Ohmoc* ohmoc1;
    __block Ohmoc* ohmoc2;
    beforeEach(^{
        ohmoc1 = [[Ohmoc alloc] initAllowDuplicates:TRUE];
        ohmoc2 = [[Ohmoc alloc] initAllowDuplicates:TRUE];
    });
    it(@"create two objects in two ohmoc creates no overlap", ^{
        OOCComment* c1 = [ohmoc1 create:@{} model:[OOCComment class]];
        OOCComment* c2 = [ohmoc2 create:@{} model:[OOCComment class]];
        XCTAssertEqualObjects(c1.id, c2.id);
    });
    it(@"create two objects in two ohmoc and query", ^{
        OOCComment* c1 = [ohmoc1 create:@{} model:[OOCComment class]];
        OOCComment* c2 = [ohmoc2 create:@{} model:[OOCComment class]];
        OOCComment* c = [ohmoc1 get:c1.id model:[OOCComment class]];
        XCTAssertEqual(c, c1);
        c = [ohmoc2 get:c2.id model:[OOCComment class]];
        XCTAssertEqual(c, c2);
    });
    it(@"create objects in two ohmoc and count", ^{
        [ohmoc1 create:@{} model:[OOCComment class]];
        [ohmoc1 create:@{} model:[OOCComment class]];
        [ohmoc2 create:@{} model:[OOCComment class]];
        NSUInteger size = [[ohmoc1 allModels:[OOCComment class]] size];
        XCTAssertEqual(size, 2);
        size = [[ohmoc2 allModels:[OOCComment class]] size];
        XCTAssertEqual(size, 1);
    });
});

SpecEnd