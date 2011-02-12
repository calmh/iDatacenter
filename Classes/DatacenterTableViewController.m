//
// DatacenterTableViewController.m
// iDatacenter
//
// Created by Jakob Borg on 7/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DatacenterTableViewController.h"
#import "InfrastructureManager.h"

@implementation DatacenterTableViewController

- (void)dealloc
{
        [super dealloc];
}

- (void)updateWithObject:(NSManagedObject*)object
{
        [super updateWithObject:object];

        DatacenterMO *datacenter = (DatacenterMO*) object;
        int memoryUsedPercentage = ((float) datacenter.memoryUsedMB) / datacenter.memoryAvailableMB * 100;
        if (isnan(memoryUsedPercentage))
                memoryUsedPercentage = 0;
        int cyclesUsedPercentage = ((float) datacenter.cyclesUsedMHz) / datacenter.cyclesAvailableMHz * 100;
        if (isnan(cyclesUsedPercentage))
                cyclesUsedPercentage = 0;

        NSMutableArray *t_sectionTitles = [NSMutableArray array];
        NSMutableArray *t_sectionValues = [NSMutableArray array];
        NSMutableArray *t_values = [NSMutableArray array];
        NSString *strValue;
        int value;

        // Resources section

        strValue = [NSString stringWithFormat:@"%d%%", memoryUsedPercentage];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Used", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%d%%", cyclesUsedPercentage];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Cycles Used", nil), @"title", strValue, @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Resource Usage", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // Available Resources section

        strValue = [NSString stringWithFormat:@"%d", datacenter.totalHosts];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Hosts Available", nil), @"title", strValue, @"value", nil]];

        value = datacenter.totalCores;
        if (value > 1)
                strValue = [NSString stringWithFormat:@"%d %@, ", value, NSLocalizedString(@"cores", nil)];
        else
                strValue = [NSString stringWithFormat:@"1 %@, ", NSLocalizedString(@"core", nil)];
        strValue = [strValue stringByAppendingFormat:@"%3.01f GHz", datacenter.cyclesAvailableMHz / 1000.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"CPUs Available", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%3.01f GB", (datacenter.memoryAvailableMB / 1024.0)];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Available", nil), @"title", strValue, @"value", nil]];

        value = datacenter.totalDatastores;
        if (value > 1)
                strValue = [NSString stringWithFormat:@"%d %@, ", value, NSLocalizedString(@"datastores", nil)];
        else
                strValue = [NSString stringWithFormat:@"1 %@, ", NSLocalizedString(@"datastore", nil)];
        strValue = [strValue stringByAppendingFormat:@"%3.01f TB", datacenter.datastoreTotalMB / 1024.0 / 1024.0];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Datastores Available", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%3.01f TB", (datacenter.datastoreFreeMB / 1024.0 / 1024.0)];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Free Datastore Capacity", nil), @"title", strValue, @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Resources Available", nil)];
        [t_sectionValues addObject:t_values];
        t_values = [NSMutableArray array];

        // VMs section

        strValue = [NSString stringWithFormat:@"%d", datacenter.totalVMs];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"VMs in Use", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%3.01f GB", (datacenter.vmAllocatedMemoryMB / 1024.0)];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Memory Allocated", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%d", datacenter.vmAllocatedCPUs];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"vCPUs Allocated", nil), @"title", strValue, @"value", nil]];

        strValue = [NSString stringWithFormat:@"%3.01f GHz", (datacenter.cyclesUsedMHz / 1000.0)];
        [t_values addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Cycles Used", nil), @"title", strValue, @"value", nil]];

        [t_sectionTitles addObject:NSLocalizedString(@"Virtual Machines", nil)];
        [t_sectionValues addObject:t_values];

        [self->sectionTitles release];
        self->sectionTitles = [t_sectionTitles retain];
        [self->sectionValues release];
        self->sectionValues = [t_sectionValues retain];

        [self.tableView reloadData];
}

@end
