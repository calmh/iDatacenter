//
// HostMO.m
// iDatacenter
//
// Created by Jakob Borg on 5/29/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "HostMO.h"
#import "NSManagedObjectContext+Safety.h"
#import "NSManagedObjectMethods.h"
#import "VirtualMachineMO.h"

@interface HostMO ()
- (void)refreshStatistics;
@end

@implementation HostMO

@synthesize vmAllocatedCPUs;
@synthesize vmAllocatedMemoryMB;
@synthesize totalVMs;

- (void)didTurnIntoFault
{
        [super didTurnIntoFault];
        if (observerRegistered) {
                [self removeObserver:self forKeyPath:@"vm"];
                observerRegistered = NO;
        }
}

- (void)awakeFromInsert
{
        [super awakeFromInsert];
        if (!observerRegistered) {
                [self addObserver:self forKeyPath:@"vm" options:NSKeyValueObservingOptionNew context:nil];
                observerRegistered = YES;
        }
}

- (void)awakeFromFetch
{
        [super awakeFromFetch];
        [self refreshStatistics];
        if (!observerRegistered) {
                [self addObserver:self forKeyPath:@"vm" options:NSKeyValueObservingOptionNew context:nil];
                observerRegistered = YES;
        }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
        [self refreshStatistics];
}

- (int)cyclesAvailable
{
        int pkgs = [[self numCpus] intValue];
        int cores = [[self numCoresPerCpu] intValue];
        int mhz = [[self cyclesPerCpuMHz] intValue];
        return pkgs * cores * mhz;
}

- (int)cyclesUsedPercent
{
        float cyclesUsed = [[self cpuUsageMHz] intValue] / (float) [self cyclesAvailable];

        if (isnan(cyclesUsed))
                return 0;
        return 100 * cyclesUsed;
}

- (int)memoryUsedPercent
{
        float memoryUsed = [[self memoryUsageMB] intValue] / (float) [[self totalMemoryMB] intValue];
        if (isnan(memoryUsed))
                return 0;
        return 100 * memoryUsed;
}

- (void)refreshStatistics
{
        totalVMs = 0;
        vmAllocatedCPUs = 0;
        vmAllocatedMemoryMB = 0;

        if (![[self managedObjectContext] validateObject:self])
                return;

        NSSet *vms = [self vm];
        for (VirtualMachineMO*vm in vms) {
                if (![vm managedObjectContext] || [vm isDeleted])
                        continue;

                if ([vm.isTemplate isEqualToString:@"true"])
                        continue;

                totalVMs++;
                vmAllocatedCPUs += [[vm configuredCpus] intValue];
                vmAllocatedMemoryMB += [[vm configuredMemoryMB] intValue];
        }
}

- (NSArray*)children
{
        NSMutableArray *results = [NSMutableArray array];
        if (![[self managedObjectContext] validateObject:self])
                return results;
        if (![self.connectionInformation isEqualToString:@"connected"])
                return results;

        NSSet *children = [self vm];
        for (NSManagedObject*child in children) {
                if (![[child managedObjectContext] validateObject:child])
                        continue;

                if ([[[child entity] name] isEqualToString:@"virtualmachine"]) {
                        if (![[(VirtualMachineMO*) child isTemplate] isEqualToString:@"true"])
                                [results addObject:child];
                } else
                        [results addObject:child];
        }

        NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:@"virtualmachine", @"group", results, @"items", nil];
        return [NSArray arrayWithObject:item];
}

- (NSSet*)allRecentTasks
{
        NSMutableSet *allTasks = [NSMutableSet setWithSet:[self recentTasks]];
        for (VirtualMachineMO*vm in [self vm])
                [allTasks unionSet:[vm recentTasks]];
        return allTasks;
}

@end
