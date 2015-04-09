# Ohmoc

[![CI Status](http://img.shields.io/travis/seppo0010/ohmoc.svg?style=flat)](https://travis-ci.org/seppo0010/ohmoc)
[![Version](https://img.shields.io/cocoapods/v/ohmoc.svg?style=flat)](http://cocoapods.org/pods/ohmoc)
[![License](https://img.shields.io/cocoapods/l/ohmoc.svg?style=flat)](http://cocoapods.org/pods/ohmoc)
[![Platform](https://img.shields.io/cocoapods/p/ohmoc.svg?style=flat)](http://cocoapods.org/pods/ohmoc)

Easy persistence and query for iOS and OS X.

## Example

```objective-c
#import "Event.h"
#import "Person.h"

- (void) myCode {
  // Create some persons
  Person* mariano = [Person create:@{@"name": @"Mariano"}]
  Person* julio = [Person create:@{@"name": @"Julio"}]
  Person* michel = [Person create:@{@"name": @"Michel"}]

  // Create some events
  Event* nscoderba = [Event create:@{@"name": @"NSCoderBA", @"location": @"Buenos Aires"}];
  Event* rubymeetup = [Event create:@{@"name": @"Ruby Meetup", @"location": @"Paris"}];

  // Some people want go to some events
  [nscoderba.attendees add:mariano];
  [nscoderba.attendees add:julio];
  [rubymeetup.attendees add:michel];

  // ...

  // Let's run some queries to fetch these values  
  [[Event all] arrayValue]; // @[nscoderba, rubymeetup]

  for (Event* ev in [Event find:@{@"location": @"Buenos Aires"}]) {
      NSLog(@"%@", ev.name); // NSCoderBA
    }

  Event* nsCoderBa = [Event with:@"name" is:@"NSCoderBA"];
  NSLog(@"%@", nsCoderBa.location); // Buenos Aires
}
```

## Documentation

Documentation available in http://ohmoc.readme.io/docs/

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

ohmoc is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ohmoc"
```

## License

Copyright (c) 2015 Sebastian Waisbrot <seppo0010@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
