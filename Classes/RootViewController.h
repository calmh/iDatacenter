//
// RootViewController.h
// iDatacenter
//
// Created by Jakob Borg on 5/14/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DetailViewControllerProtocol.h"
#import <UIKit/UIKit.h>

@class GeneralDetailViewController;

@interface RootViewController : UISplitViewController  {
        GeneralDetailViewController *generalDetailViewController;
}

@property (nonatomic, retain) IBOutlet GeneralDetailViewController *generalDetailViewController;

- (void)switchDetailViewController:(UIViewController*)controller;

@end
