//
// VMDetailTableViewController.h
// iDatacenter
//
// Created by Jakob Borg on 7/29/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DetailTableViewController.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class VMDetailViewController;

@interface VMDetailTableViewController : DetailTableViewController {
        BOOL powerStateChangedEnabled;
        BOOL relocateStorageEnabled;
}

@property (nonatomic, assign) BOOL powerStateChangeEnabled;
@property (nonatomic, assign) BOOL relocateStorageEnabled;

@end
