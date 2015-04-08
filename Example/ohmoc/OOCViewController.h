//
//  OOCViewController.h
//  ohmoc
//
//  Created by Sebastian Waisbrot on 04/01/2015.
//  Copyright (c) 2014 Sebastian Waisbrot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppInfo.h"

@interface OOCViewController : UIViewController <UITableViewDataSource> {
    IBOutlet UITableView *_tableView;
    AppInfo* appInfo;
    NSDateFormatter* formatter;
    NSArray* events;
}

@end