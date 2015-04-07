//
//  OOCViewController.m
//  ohmoc
//
//  Created by Sebastian Waisbrot on 04/01/2015.
//  Copyright (c) 2014 Sebastian Waisbrot. All rights reserved.
//

#import "OOCViewController.h"

@interface OOCViewController ()

@end

@implementation OOCViewController

- (void) awakeFromNib {
    [super awakeFromNib];
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    formatter.timeStyle = NSDateFormatterLongStyle;
}

- (void)viewDidLoad {
    _tableView.dataSource = self;
    appInfo = [[AppInfo all] first];
    [[NSNotificationCenter defaultCenter] addObserver:_tableView selector:@selector(reloadData) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    AppEvent* event = [appInfo.events objectAtIndex:indexPath.row];
    cell.textLabel.text = event.name;
    cell.detailTextLabel.text = [formatter stringFromDate:event.date];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return appInfo.events.size;
}

@end
