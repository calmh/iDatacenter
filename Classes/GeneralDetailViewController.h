//
// GeneralDetailViewController.h
// iDatacenter
//
// Created by Jakob Borg on 5/16/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DetailViewControllerProtocol.h"
#import <UIKit/UIKit.h>

@class IDCApplicationDelegate;
@class EntityMasterViewController;

@interface GeneralDetailViewController : UIViewController<UISplitViewControllerDelegate> {
        IDCApplicationDelegate *delegate;
        UIView *contentView;
        UIToolbar *toolbar;
        UIPopoverController *popoverController;
        UIBarButtonItem *titleBar;
        UIViewController<DetailViewControllerProtocol> *detailViewController;
        UIViewController<DetailViewControllerProtocol> *datacenterDetailViewController;
        UIViewController<DetailViewControllerProtocol> *hostDetailViewController;
        UIViewController<DetailViewControllerProtocol> *vmDetailViewController;
        EntityMasterViewController *entityMasterViewController;
        NSManagedObject *previousMO;
        BOOL selectionBarButtonIsVisible;
        UIBarButtonItem *visualizeButton;
}

@property (nonatomic, assign) IBOutlet IDCApplicationDelegate *delegate;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIPopoverController *popoverController;
@property (nonatomic, assign) IBOutlet UIViewController<DetailViewControllerProtocol> *detailViewController;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *titleBar;
@property (nonatomic, retain) IBOutlet UIViewController<DetailViewControllerProtocol> *datacenterDetailViewController;
@property (nonatomic, retain) IBOutlet UIViewController<DetailViewControllerProtocol> *hostDetailViewController;
@property (nonatomic, retain) IBOutlet UIViewController<DetailViewControllerProtocol> *vmDetailViewController;
@property (nonatomic, retain) IBOutlet EntityMasterViewController *entityMasterViewController;

- (void)setDetailObject:(NSManagedObject*)object;
- (void)visualize;
- (BOOL)canVisualize;

@end
