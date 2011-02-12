//
// HostDetailTableViewController.m
// iDatacenter
//
// Created by Jakob Borg on 7/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "HostDetailTableViewController.h"
#import "HostDetailViewController.h"
#import "InfrastructureManager.h"

@implementation HostDetailTableViewController

@synthesize powerStateChangeEnabled;

- (void)dealloc
{
        [super dealloc];
}

- (void)setPowerStateChangeEnabled:(BOOL)value
{
        powerStateChangeEnabled = value;
        [self.tableView reloadData];
}

- (void)updateWithObject:(NSManagedObject*)object
{
        [super updateWithObject:object];

        HostMO *host = (HostMO*) object;

        NSMutableArray *t_sectionTitles = [NSMutableArray array];
        NSMutableArray *t_sectionValues = [NSMutableArray array];
        NSMutableArray *t_values = [NSMutableArray array];
        NSString *strValue;
        int value;

        // Resource Usage section

        strValue = [NSString stringWithFormat:@"%d%%", host.memoryUsedPercent];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Used", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%d%%", host.cyclesUsedPercent];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Cycles Used", nil), @"title", strValue, @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Resource Usage", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Hardware section

        NSArray *commands = [NSArray arrayWithObject:@"Change"];
        strValue = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(host.connectionInformation, nil), NSLocalizedString(host.powerState, nil)];
        if ([host.inMaintenanceMode isEqualToString:@"true"])
                strValue = [strValue stringByAppendingFormat:@", %@", NSLocalizedString(@"Maintenance Mode", nil)];
        if (powerStateChangeEnabled)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power State", nil), @"title", strValue, @"value",
                                     commands, @"commands", [NSNumber numberWithInt:1], @"tag", nil]];
        else
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Power State", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%@ %@", host.hwVendor, host.hwModel];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Hardware", nil), @"title", strValue, @"value", nil]];

        strValue = host.prodFullName;
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Software", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%.01f GB", [host.totalMemoryMB intValue] / 1024.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Available", nil), @"title", strValue, @"value", nil]];

        value = [host.numCpus intValue] * [host.numCoresPerCpu intValue];
        if (value > 1)
                strValue = [NSString stringWithFormat:@"%d %@", value, NSLocalizedString(@"cores", nil)];
        else
                strValue = [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"core", nil)];
        strValue = [strValue stringByAppendingFormat:@" %@ %.01f GHz", NSLocalizedString(@"at", nil), [host.cyclesPerCpuMHz intValue] / 1000.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"CPUs Available", nil), @"title", strValue, @"value", nil]];

        [self setDebugData:[host.numCpus stringValue] forKey:@"numCPUs"];
        [self setDebugData:[host.numCoresPerCpu stringValue] forKey:@"numCoresPerCPU"];

        strValue = [host.hwNumNICs stringValue];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Network Interfaces Available", nil), @"title", strValue, @"value", nil]];

        NSMutableDictionary *datastores = [[[NSMutableDictionary alloc] init] autorelease];
        for (NSManagedObject*ds in host.datastore) {
                NSString *strTitle = [NSString stringWithFormat:@"%@ '%@'", NSLocalizedString(@"Datastore", nil), ds.name];
                strValue = [NSString stringWithFormat:@"%@ total, %@ free",
                            [self formatStorageAmount:[ds.totalMB intValue]],
                            [self formatStorageAmount:[ds.freeMB intValue]]];
                [datastores setObject:strValue forKey:strTitle];
        }
        NSArray *datastore_keys = [[datastores allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString*key in datastore_keys)
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"title", [datastores objectForKey:key], @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Hardware & Software", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Virtual Machines

        strValue = [NSString stringWithFormat:@"%d", host.totalVMs];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"VMs in Use", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%.01f GB", host.vmAllocatedMemoryMB / 1024.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Allocated", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%d", host.vmAllocatedCPUs];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"vCPUs Allocated", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%.01f GHz", [host.cpuUsageMHz intValue] / 1000.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Cycles Used", nil), @"title", strValue, @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Virtual Machines", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Networks

        NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(compare:)] autorelease];
        NSArray *sortedNetworks = [[host.network allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];

        for (NSManagedObject*network in sortedNetworks) {
                int numVms = [network.vm count];
                if (numVms == 0)
                        strValue = NSLocalizedString(@"Unused", nil);
                else if (numVms == 1)
                        strValue = [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"VM", nil)];
                else
                        strValue = [NSString stringWithFormat:@"%d %@", numVms, NSLocalizedString(@"VMs", nil)];
                NSString *strKey = [NSString stringWithFormat:@"%@ '%@'", NSLocalizedString(@"Network", nil), network.name];
                [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:strKey, @"title", strValue, @"value", nil]];
        }

        [t_sectionTitles addObject:NSLocalizedString(@"Networks", nil)];
        [t_sectionValues addObject:t_values];

        [self->sectionTitles release];
        self->sectionTitles = [t_sectionTitles retain];
        [self->sectionValues release];
        self->sectionValues = [t_sectionValues retain];

        [self.tableView reloadData];
}

- (void)tappedButtonWithTag:(NSInteger)tag index:(NSInteger)idx rect:(CGRect)rect;
{
        if (tag == 1 && idx == 0) // Change Power State
                [(HostDetailViewController*)self.delegate presentPowerActionSheetFromRect:rect];
}

@end
