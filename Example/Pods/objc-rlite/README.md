# objc-rlite

[![CI Status](http://img.shields.io/travis/seppo0010/objc-rlite.svg?style=flat)](https://travis-ci.org/seppo0010/objc-rlite)
[![Version](https://img.shields.io/cocoapods/v/objc-rlite.svg?style=flat)](http://cocoadocs.org/docsets/objc-rlite)
[![License](https://img.shields.io/cocoapods/l/objc-rlite.svg?style=flat)](http://cocoadocs.org/docsets/objc-rlite)
[![Platform](https://img.shields.io/cocoapods/p/objc-rlite.svg?style=flat)](http://cocoadocs.org/docsets/objc-rlite)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### API

```objectivec
#import <objc-rlite/ObjCHirlite.h>

// ...

- (void) myMethod {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"mydb.rld"];

    ObjCHirlite* rlite = [[ObjCHirlite alloc] initWithPath:path];
    [rlite command:@[@"set", @"key", @"value"]];
    NSLog(@"%@", [rlite command:@[@"get", @"key"]]); // @"value"

    [rlite command:@[@"rpush", @"list", @1, @2, @3]]
    NSLog(@"%@", [rlite command:@[@"lrange", @"list", @0, @-1]]); // @[@"1", @"2", @"3"]
}

```

ObjCHirlite.command: receives an array of arguments that will be sent directly
to rlite, transforming every object into an instance of NSData using
ObjCHirlite.encoding (NSUTF8StringEncoding by default).

Responses will be transformed into the corresponding objective-c class.

Notice that retrieving a value that was set as a number will return a string
object, since the number was serialized as a string.

To retrieve binary data from the database set binary to true in the call to
ObjCHirlite.command:binary: and the response will be an instance (or an array
of instances) of NSData instead of NSString.

## Requirements

## Installation

objc-rlite is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "objc-rlite"

## Author

Sebastian Waisbrot, seppo0010@gmail.com

## License

objc-rlite is available under the MIT license. See the LICENSE file for more info.

