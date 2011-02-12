//
// VMDetailsViewController.m
// iDatacenter
//
// Created by Jakob Borg on 6/6/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import "SelectionTableViewController.h"
#import "VMDetailTableViewController.h"
#import "VMDetailViewController.h"
#import "VMSettingsViewController.h"

@interface VMDetailViewController ()
- (void)refreshPermissions;
- (void)relocateToDatastore:(NSManagedObject*)datastore;
- (void)powerStateOn;
- (void)powerStateOff;
- (void)powerStateSuspend;
- (void)rebootGuest;
- (void)shutdownGuest;
- (void)resetPower;
- (NSArray*)viableStorageRelocationDestinations;
@end

@implementation VMDetailViewController

@synthesize settingsVC;

- (void)dealloc
{
        [super dealloc];
}

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

- (void)viewDidLoad
{
        [super viewDidLoad];
        vmDetailsTVC = (VMDetailTableViewController*) detailsTableController;
        [self periodicUpdateView:nil];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
        [super viewDidUnload];
}

- (void)refreshPermissions
{
        InfrastructureManager *im = self.delegate.infrastructureManager;
        if ([((VirtualMachineMO*) currentObject).powerState isEqualToString:@"poweredOn"])
                actPowerStateOnOffPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.PowerOff" withDisabler:@"PowerOffVM_Task" onObject:currentObject];
        else
                actPowerStateOnOffPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.PowerOn" withDisabler:@"PowerOnVM_Task" onObject:currentObject];
        actPowerStateResetPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.Reset" withDisabler:@"ResetVM_Task" onObject:currentObject];
        actPowerStateRebootPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.Reset" withDisabler:@"RebootGuest" onObject:currentObject];
        actPowerStateShutdownPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.PowerOff" withDisabler:@"ShutdownGuest" onObject:currentObject];
        actPowerStateSuspendPrivilege = [im permissionForOperation:@"VirtualMachine.Interact.Suspend" withDisabler:@"SuspendVM_Task" onObject:currentObject];
        actRelocateStoragePrivilege = [im permissionForOperation:@"Resource.ColdMigrate" withDisabler:@"RelocateVM_Task" onObject:currentObject];

        vmDetailsTVC.powerStateChangeEnabled = (actPowerStateOnOffPrivilege || actPowerStateResetPrivilege || actPowerStateRebootPrivilege || actPowerStateShutdownPrivilege);
        vmDetailsTVC.relocateStorageEnabled = actRelocateStoragePrivilege && [[self viableStorageRelocationDestinations] count] > 0;

        [detailsTableController setDebugData:actPowerStateOnOffPrivilege ? @"yes":@"no" forKey:@"actualPowerStateOnOffPrivilege"];
        [detailsTableController setDebugData:actPowerStateResetPrivilege ? @"yes":@"no" forKey:@"actualPowerStateResetPrivilege"];
        [detailsTableController setDebugData:actPowerStateRebootPrivilege ? @"yes":@"no" forKey:@"actualPowerStateRebootPrivilege"];
        [detailsTableController setDebugData:actPowerStateSuspendPrivilege ? @"yes":@"no" forKey:@"actualPowerStateSuspendPrivilege"];
        [detailsTableController setDebugData:actPowerStateShutdownPrivilege ? @"yes":@"no" forKey:@"actualPowerStateShutdownPrivilege"];
        [detailsTableController setDebugData:actRelocateStoragePrivilege ? @"yes":@"no" forKey:@"actualRelocateStoragePrivilege"];
}

- (void)presentPowerStateActionSheetFromRect:(CGRect)rect
{
        VirtualMachineMO *vm = (VirtualMachineMO*) currentObject;
        SelectionTableViewController *stvc = [[SelectionTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        stvc.delegate = self;
        stvc.header = NSLocalizedString(@"Change Power State", nil);
        stvc.width = 190.0f;

        BOOL poweredOn = [vm.powerState isEqualToString:@"poweredOn"];
        if (poweredOn) {
                if (actPowerStateRebootPrivilege)
                        [stvc addOptionWithTitle:NSLocalizedString(@"Restart Guest", nil) tag:[NSValue valueWithPointer:@selector(rebootGuest)]];
                if (actPowerStateShutdownPrivilege)
                        [stvc addOptionWithTitle:NSLocalizedString(@"Shutdown Guest", nil) tag:[NSValue valueWithPointer:@selector(shutdownGuest)]];
                if (actPowerStateResetPrivilege)
                        [stvc addOptionWithTitle:NSLocalizedString(@"Reset", nil) tag:[NSValue valueWithPointer:@selector(resetPower)]];
                if (actPowerStateOnOffPrivilege)
                        [stvc addOptionWithTitle:NSLocalizedString(@"Power Off", nil) tag:[NSValue valueWithPointer:@selector(powerStateOff)]];
                if (actPowerStateSuspendPrivilege)
                        [stvc addOptionWithTitle:NSLocalizedString(@"Suspend", nil) tag:[NSValue valueWithPointer:@selector(powerStateSuspend)]];
        } else if (actPowerStateOnOffPrivilege)
                [stvc addOptionWithTitle:NSLocalizedString(@"Power On", nil) tag:[NSValue valueWithPointer:@selector(powerStateOn)]];

        popover = [[UIPopoverController alloc] initWithContentViewController:stvc];
        popover.delegate = self;
        [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
}

- (void)presentRelocateStorageActionSheetFromRect:(CGRect)rect
{
        NSArray *datastores = [self viableStorageRelocationDestinations];
        if ([datastores count] > 0) {
                SelectionTableViewController *stvc = [[[SelectionTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                stvc.delegate = self;
                stvc.header = NSLocalizedString(@"Relocate VM to Datastore", nil);
                stvc.width = 360.0f;

                NSSortDescriptor *byName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
                NSArray *descriptors = [NSArray arrayWithObjects:byName, nil];
                NSArray *sortedStores = [[datastores sortedArrayUsingDescriptors:descriptors] retain];

                for (NSManagedObject*ds in sortedStores) {
                        NSString *title = ds.name;
                        NSString *subTitle = nil;
                        float freeGB = [ds.freeMB intValue] / 1024.0f;
                        if (freeGB > 1024)
                                subTitle = [NSString stringWithFormat:@"%.02f TB", freeGB / 1024.0f];
                        else
                                subTitle = [NSString stringWithFormat:@"%.01f GB", freeGB];
                        [stvc addOptionWithTitle:title subTitle:subTitle tag:ds];
                }

                popover = [[UIPopoverController alloc] initWithContentViewController:stvc];
                popover.delegate = self;
                [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
        }
}

- (void)presentSettingsSheet
{
        self.settingsVC = [[VMSettingsViewController alloc] initWithNibName:@"VMSettingsViewController" bundle:nil];
        settingsVC.vm = (VirtualMachineMO*) currentObject;
        [delegate.rootViewController presentModalViewController:settingsVC animated:YES];
}

- (void)selectionTable:(SelectionTableViewController*)controller selectedTag:(NSObject*)tag
{
        [popover dismissPopoverAnimated:YES];
        if ([tag isKindOfClass:[NSManagedObject class]])
                [self relocateToDatastore:(NSManagedObject*) tag];
        else if ([tag isKindOfClass:[NSValue class]])
                [self performSelector:[(NSValue*) tag pointerValue]];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
        [popoverController release];
}

- (void)relocateToDatastore:(NSManagedObject*)datastore
{
        NSString *dsId = [datastore id];
        NSString *vmId = [currentObject id];
        [delegate.infrastructureManager relocateVM:vmId toDatastoreId:dsId];
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
}

- (void)powerStateOn
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager powerOnVM:currentObject.id];
}

- (void)powerStateOff
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager powerOffVM:currentObject.id];
}

- (void)powerStateSuspend
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager suspendVM:currentObject.id];
}

- (void)rebootGuest
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager rebootGuest:currentObject.id];
}

- (void)shutdownGuest
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager shutdownGuest:currentObject.id];
}

- (void)resetPower
{
        vmDetailsTVC.relocateStorageEnabled = NO;
        vmDetailsTVC.powerStateChangeEnabled = NO;
        lockButtonsIterations = 2;
        [delegate.infrastructureManager powerCycleVM:currentObject.id];
}

- (NSArray*)viableStorageRelocationDestinations
{
        VirtualMachineMO *vm = (VirtualMachineMO*) currentObject;
        HostMO *host = [vm host];
        NSArray *candidateDatastores = [host.datastore allObjects];
        NSArray *currentDatastores = [vm.datastores allObjects];
        if ([currentDatastores count] == 1) {
                NSMutableArray *viableDatastores = [NSMutableArray array];
                NSManagedObject *exclude = [currentDatastores lastObject];
                for (NSManagedObject*ds in candidateDatastores) {
                        if (![ds isEqual:exclude])
                                [viableDatastores addObject:ds];
                }
                return viableDatastores;
        } else
                return candidateDatastores;
}

@end
