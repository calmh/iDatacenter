//
// VMDetailsViewController.h
// iDatacenter
//
// Created by Jakob Borg on 6/6/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "BaseDetailViewController.h"
#import "SelectionTableViewController.h"
#import <UIKit/UIKit.h>

@class VMSettingsViewController;

@interface VMDetailViewController : BaseDetailViewController<UIPopoverControllerDelegate, SelectionTableDelegate> {
        VMDetailTableViewController *vmDetailsTVC;

        BOOL actPowerStateOnOffPrivilege;
        BOOL actPowerStateResetPrivilege;
        BOOL actPowerStateRebootPrivilege;
        BOOL actPowerStateShutdownPrivilege;
        BOOL actPowerStateSuspendPrivilege;
        BOOL actRelocateStoragePrivilege;
        NSInteger lockButtonsIterations;
        UIPopoverController *popover;
        VMSettingsViewController *settingsVC;
}

@property (nonatomic, retain) IBOutlet VMSettingsViewController *settingsVC;

- (void)presentPowerStateActionSheetFromRect:(CGRect)rect;
- (void)presentRelocateStorageActionSheetFromRect:(CGRect)rect;
- (void)presentSettingsSheet;
- (void)powerStateOn;
- (void)powerStateOff;
- (void)rebootGuest;
- (void)shutdownGuest;
- (void)resetPower;

@end
