//
// HostDetailViewController.m
// iDatacenter
//
// Created by Jakob Borg on 5/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "HostDetailTableViewController.h"
#import "HostDetailViewController.h"
#import "InfrastructureManager.h"
#import "SelectionTableViewController.h"
#import "VisualizationViewController.h"

@interface HostDetailViewController ()

- (void)refreshPermissions;

@end


@implementation HostDetailViewController

- (void)setDetailObject:(NSManagedObject*)object
{
        [super setDetailObject:object];
        [self refreshPermissions];
        [detailsTableController updateWithObject:object];
}

- (void)periodicUpdateView:(NSTimer*)sourceTimer
{
        [super periodicUpdateView:sourceTimer];
        if (lockButtonsIterations > 0)
                lockButtonsIterations--;
        else
                [self refreshPermissions];
}

- (void)refreshPermissions
{
        InfrastructureManager *im = self.delegate.infrastructureManager;

        actEnterMaintenanceModePrivilege = [im permissionForOperation:@"Host.Config.Maintenance" withDisabler:@"EnterMaintenanceMode_Task" onObject:currentObject];
        actExitMaintenanceModePrivilege = [im permissionForOperation:@"Host.Config.Maintenance" withDisabler:@"ExitMaintenanceMode_Task" onObject:currentObject];
        actReconnectPrivilege = [im permissionForOperation:@"Host.Config.Connection" withDisabler:@"ReconnectHost_Task" onObject:currentObject];
        actDisconnectPrivilege = [im permissionForOperation:@"Host.Config.Connection" withDisabler:@"DisconnectHost_Task" onObject:currentObject];
        actRebootPrivilege = [im permissionForOperation:@"Host.Config.Maintenance" withDisabler:@"RebootHost_Task" onObject:currentObject];
        actShutdownPrivilege = [im permissionForOperation:@"Host.Config.Maintenance" withDisabler:@"ShutdownHost_Task" onObject:currentObject];

        [(HostDetailTableViewController*) detailsTableController setPowerStateChangeEnabled:actEnterMaintenanceModePrivilege | actExitMaintenanceModePrivilege | actReconnectPrivilege | actDisconnectPrivilege | actRebootPrivilege];

        [detailsTableController setDebugData:actEnterMaintenanceModePrivilege ? @"yes":@"no" forKey:@"actualEnterMaintenanceModePrivilege"];
        [detailsTableController setDebugData:actExitMaintenanceModePrivilege ? @"yes":@"no" forKey:@"actualExitMaintenanceModePrivilege"];
        [detailsTableController setDebugData:actReconnectPrivilege ? @"yes":@"no" forKey:@"actualReconnectPrivilege"];
        [detailsTableController setDebugData:actDisconnectPrivilege ? @"yes":@"no" forKey:@"actualDisconnectPrivilege"];
        [detailsTableController setDebugData:actRebootPrivilege ? @"yes":@"no" forKey:@"actualRebootPrivilege"];
        [detailsTableController setDebugData:actShutdownPrivilege ? @"yes":@"no" forKey:@"actualShutdownPrivilege"];
}

- (void)presentPowerActionSheetFromRect:(CGRect)rect
{
        SelectionTableViewController *stvc = [[[SelectionTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        stvc.delegate = self;
        stvc.header = NSLocalizedString(@"Change Power State", nil);
        stvc.width = 260.0f;

        if (actEnterMaintenanceModePrivilege)
                [stvc addOptionWithTitle:NSLocalizedString(@"Enter Maintenance Mode", nil) tag:[NSNumber numberWithInt:1]];
        if (actExitMaintenanceModePrivilege)
                [stvc addOptionWithTitle:NSLocalizedString(@"Exit Maintenance Mode", nil) tag:[NSNumber numberWithInt:2]];
        if (actReconnectPrivilege)
                [stvc addOptionWithTitle:NSLocalizedString(@"Reconnect Host", nil) tag:[NSNumber numberWithInt:3]];
        if (actDisconnectPrivilege)
                [stvc addOptionWithTitle:NSLocalizedString(@"Disconnect Host", nil) tag:[NSNumber numberWithInt:4]];

        HostMO *host = (HostMO*) currentObject;
        if (actRebootPrivilege && [host.inMaintenanceMode isEqualToString:@"true"])
                [stvc addOptionWithTitle:NSLocalizedString(@"Reboot Host", nil) tag:[NSNumber numberWithInt:5]];
        if (actShutdownPrivilege && [host.inMaintenanceMode isEqualToString:@"true"])
                [stvc addOptionWithTitle:NSLocalizedString(@"Shutdown Host", nil) tag:[NSNumber numberWithInt:6]];

        popover = [[UIPopoverController alloc] initWithContentViewController:stvc];
        popover.delegate = self;
        [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
}

- (void)visualize
{
        VisualizationViewController *vc = [[VisualizationViewController alloc] initWithNibName:@"VisualizationViewController" bundle:nil];
        RootViewController *presentationParent = self.delegate.rootViewController;
        [presentationParent presentModalViewController:vc animated:YES];
        [vc visualizeHost:(HostMO*) currentObject];
        [vc autorelease];
}

- (void)selectionTable:(SelectionTableViewController*)controller selectedTag:(NSObject*)tag
{
        [popover dismissPopoverAnimated:YES];
        int itag = [(NSNumber*) tag intValue];
        if (itag == 1)
                [delegate.infrastructureManager enterHostMaintenanceMode:[currentObject id]];
        else if (itag == 2)
                [delegate.infrastructureManager exitHostMaintenanceMode:[currentObject id]];
        else if (itag == 3)
                [delegate.infrastructureManager reconnectHost:[currentObject id]];
        else if (itag == 4)
                [delegate.infrastructureManager disconnectHost:[currentObject id]];
        else if (itag == 5)
                [delegate.infrastructureManager rebootHost:[currentObject id]];
        else if (itag == 6)
                [delegate.infrastructureManager shutdownHost:[currentObject id]];
        lockButtonsIterations = 3;
        [(HostDetailTableViewController*) detailsTableController setPowerStateChangeEnabled:NO];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
        [popoverController release];
}

@end
