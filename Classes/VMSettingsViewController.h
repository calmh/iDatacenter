//
// VMSettingsViewController.h
// iDatacenter
//
// Created by Jakob Borg on 8/15/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "PickerController.h"
#import <UIKit/UIKit.h>

@class VirtualMachineMO;

@interface VMSettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, PickerControlDelegate> {
        UISegmentedControl *applyButton;
        UISegmentedControl *cancelButton;
        UITableView *tableView;
        VirtualMachineMO *vm;
        NSMutableDictionary *newValues;
}

@property (nonatomic, retain) IBOutlet UISegmentedControl *applyButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *cancelButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet VirtualMachineMO *vm;

- (IBAction)applyPressed:(id)sender;
- (IBAction)cancelPressed:(id)sender;

@end
