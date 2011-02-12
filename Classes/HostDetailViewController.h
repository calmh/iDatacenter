//
// HostsDetailViewController.h
// iDatacenter
//
// Created by Jakob Borg on 5/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "BaseDetailViewController.h"
#import "DetailViewControllerProtocol.h"
#import "SelectionTableViewController.h"
#import <UIKit/UIKit.h>

@class ResourceMeterView;

@interface HostDetailViewController : BaseDetailViewController<UIPopoverControllerDelegate, SelectionTableDelegate> {
        UIPopoverController *popover;
        BOOL actEnterMaintenanceModePrivilege;
        BOOL actExitMaintenanceModePrivilege;
        BOOL actReconnectPrivilege;
        BOOL actDisconnectPrivilege;
        BOOL actRebootPrivilege;
        BOOL actShutdownPrivilege;
        int lockButtonsIterations;
}

- (void)presentPowerActionSheetFromRect:(CGRect)rect;

@end
