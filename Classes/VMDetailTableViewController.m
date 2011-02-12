//
// VMDetailTableViewController.m
// iDatacenter
//
// Created by Jakob Borg on 7/29/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "EntityMasterViewController.h"
#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import "VMDetailTableViewController.h"
#import "VMDetailViewController.h"
#import "NSArray+Flatten.h"

@implementation VMDetailTableViewController

#define TAG_POWERSTATE 1
#define TAG_POWERONQUICK 2
#define TAG_RELOCATE 3
#define TAG_VIEWHOST 4
#define TAG_VMSETTINGS 5

@synthesize powerStateChangeEnabled;
@synthesize relocateStorageEnabled;

- (void)dealloc
{
        [super dealloc];
}

- (void)setPowerStateChangeEnabled:(BOOL)value
{
        if (value != powerStateChangedEnabled) {
                powerStateChangedEnabled = value;
                [self.tableView reloadData];
        }
}

- (void)setRelocateStorageEnabled:(BOOL)value
{
        if (value != relocateStorageEnabled) {
                relocateStorageEnabled = value;
                [self.tableView reloadData];
        }
}

- (void)updateWithObject:(NSManagedObject*)object
{
        [super updateWithObject:object];

        VirtualMachineMO *vm = (VirtualMachineMO*) object;

        NSMutableArray *t_sectionTitles = [NSMutableArray array];
        NSMutableArray *t_sectionValues = [NSMutableArray array];
        NSMutableArray *t_values = [NSMutableArray array];
        NSString *strValue;

        // Resource Usage section

        int value = [vm.hostMemoryUsageMB intValue];
        if (value >= 1024)
                strValue = [NSString stringWithFormat:@"%.02f GB", value / 1024.0];
        else
                strValue = [NSString stringWithFormat:@"%d MB", value];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Host Memory Usage", nil), @"title", strValue, @"value", nil]];

        value = [vm.cpuUsageMHz intValue];
        if (value >= 1000)
                strValue = [NSString stringWithFormat:@"%.02f GHz", value / 1000.0];
        else
                strValue = [NSString stringWithFormat:@"%d MHz", value];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Host CPU Usage", nil), @"title", strValue, @"value", nil]];

        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Current Host", nil), @"title", vm.host.name, @"value",
                             [NSArray arrayWithObjects:NSLocalizedString(@"View", nil), nil], @"commands",
                             [NSNumber numberWithInt:TAG_VIEWHOST], @"tag", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Resource Usage", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Configuration section

        NSString *memoryStr, *cpuStr, *versionStr;
        value = [vm.configuredMemoryMB intValue];
        if (value >= 1024)
                memoryStr = [NSString stringWithFormat:@"%.02f GB", value / 1024.0];
        else
                memoryStr = [NSString stringWithFormat:@"%d MB", value];
        value = [vm.configuredCpus intValue];
        if (value > 1)
                cpuStr = [NSString stringWithFormat:@"%d vCPUs", [vm.configuredCpus intValue]];
        else
                cpuStr = @"1 vCPU";
        versionStr = [NSString stringWithFormat:@"version %@", [vm.hardwareVersion stringByReplacingOccurrencesOfString:@"vmx-" withString:@""]];
        strValue = [NSString stringWithFormat:@"%@, %@, %@", memoryStr, cpuStr, versionStr];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Hardware", nil), @"title", strValue, @"value",
                             //[NSArray arrayWithObject:@"Change"], @"commands", [NSNumber numberWithInt:TAG_VMSETTINGS], @"tag",
                             nil]];

        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Guest Type", nil), @"title", vm.guestFullName, @"value", nil]];

        if ([vm.annotation length] > 0)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Annotation", nil), @"title", vm.annotation, @"value", nil]];

        strValue = [[[vm.ipAddresses arrayByFlattening] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "];
        if ([strValue length] > 0)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"IP Addresses", nil), @"title", strValue, @"value", nil]];

        strValue = [[[[vm.network allObjects] valueForKey:@"name"] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "];
        if ([strValue length] > 0)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Networks", nil), @"title", strValue, @"value", nil]];

        NSArray *datastoreNames = [[vm.datastores allObjects] valueForKey:@"name"];
        strValue = [datastoreNames componentsJoinedByString:@", "];
        NSString *title;
        if ([datastoreNames count] > 1)
                title = NSLocalizedString(@"Datastores", nil);
        else
                title = NSLocalizedString(@"Datastore", nil);
        if (relocateStorageEnabled)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", strValue, @"value",
                                     [NSArray arrayWithObjects:NSLocalizedString(@"Change", nil), nil], @"commands",
                                     [NSNumber numberWithInt:TAG_RELOCATE], @"tag", nil]];
        else
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", strValue, @"value", nil]];

        for (int i = 0; i < [vm.diskNames count]; i++) {
                NSString *strTitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Disk", nil), [vm.diskNames objectAtIndex:i]];
                long capacityMB = (long) ([[vm.diskCapacities objectAtIndex:i] longLongValue] / 1024 / 1024);
                long freeMB = (long) ([[vm.diskFreespace objectAtIndex:i] longLongValue] / 1024 / 1024);
                strValue = [NSString stringWithFormat:@"%@ %@, %@ %@",
                            [self formatStorageAmount:capacityMB], NSLocalizedString(@"total", nil),
                            [self formatStorageAmount:freeMB], NSLocalizedString(@"free", nil)];
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:strTitle, @"title", strValue, @"value", nil]];
        }

        [t_sectionTitles addObject:NSLocalizedString(@"Configuration", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Environment section

        if (powerStateChangedEnabled) {
                if ([vm.currentPowerState isEqualToString:@"poweredOff"] || [vm.currentPowerState isEqualToString:@"suspended"]) {
                        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power State", nil), @"title",
                                             NSLocalizedString(vm.currentPowerState, nil), @"value",
                                             [NSArray arrayWithObjects:NSLocalizedString(@"Power On", nil), nil], @"commands",
                                             GREEN_TINT, @"tintColor",
                                             [NSNumber numberWithInt:TAG_POWERONQUICK], @"tag", nil]];
                } else {
                        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power State", nil), @"title",
                                             NSLocalizedString(vm.currentPowerState, nil), @"value",
                                             [NSArray arrayWithObjects:NSLocalizedString(@"Change", nil), nil], @"commands",
                                             [NSNumber numberWithInt:TAG_POWERSTATE], @"tag", nil]];
                }
        } else
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power State", nil), @"title", NSLocalizedString(vm.currentPowerState, nil), @"value", nil]];

        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Tools Status", nil), @"title", NSLocalizedString(vm.toolsStatus, nil), @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Environment", nil)];
        [t_sectionValues addObject:t_values];

        [self->sectionTitles release];
        self->sectionTitles = [t_sectionTitles retain];
        [self->sectionValues release];
        self->sectionValues = [t_sectionValues retain];

        [self.tableView reloadData];
}

- (void)tappedButtonWithTag:(NSInteger)tag index:(NSInteger)idx rect:(CGRect)rect;
{
        if (tag == TAG_VIEWHOST && idx == 0) { // View Host
                HostMO *host = ((VirtualMachineMO*) self.delegate.currentObject).host;
                EntityMasterViewController *controller = ((IDCApplicationDelegate*) self.delegate.delegate).entityMasterViewController;
                controller = (EntityMasterViewController*) controller.navigationController.visibleViewController;
                [controller activateChildObject:host];
        } else if (tag == TAG_RELOCATE && idx == 0) // Relocate
                [(VMDetailViewController*)self.delegate presentRelocateStorageActionSheetFromRect:rect];
        else if (tag == TAG_POWERSTATE && idx == 0) // Change power state
                [(VMDetailViewController*)self.delegate presentPowerStateActionSheetFromRect:rect];
        else if (tag == TAG_POWERONQUICK && idx == 0) // Direct power on
                [(VMDetailViewController*)self.delegate powerStateOn];
        else if (tag == TAG_VMSETTINGS && idx == 0) // VM Settings
                [(VMDetailViewController*)self.delegate presentSettingsSheet];
}

@end
