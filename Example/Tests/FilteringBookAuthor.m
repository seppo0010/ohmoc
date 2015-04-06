//
//  ohmoc
//
//  Created by Seppo on 4/6/15.
//  Copyright (c) 2015 Sebastian Waisbrot. All rights reserved.
//

#import "OhmocTests.h"

SpecBegin(filtering_book_author)

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

SpecEnd