//
// DatacenterMO.m
// iDatacenter
//
// Created by Jakob Borg on 5/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DatacenterMO.h"
#import "HostMO.h"
#import "NSManagedObjectContext+Safety.h"
#import "NSManagedObjectMethods.h"
#import "VirtualMachineMO.h"

@interface DatacenterMO ()
- (void)refreshStatistics;
- (NSArray*)hosts;
- (NSArray*)hostsFromSubtree:(FolderMO*)folder;
- (NSArray*)vmsFromHosts:(NSArray*)hosts;
@end

@implementation DatacenterMO

@synthesize cyclesAvailableMHz;
@synthesize memoryAvailableMB;
@synthesize cyclesUsedMHz;
@synthesize memoryUsedMB;
@synthesize totalHosts;
@synthesize totalCores;
@synthesize totalVMs;
@synthesize vmAllocatedCPUs;
@synthesize vmAllocatedMemoryMB;
@synthesize totalDatastores;
@synthesize datastoreTotalMB;
@synthesize datastoreFreeMB;

- (void)didTurnIntoFault
{
        [super didTurnIntoFault];
        if (observerRegistered) {
                [self removeObserver:self forKeyPath:@"datastore"];
                [self removeObserver:self forKeyPath:@"hostFolder"];
                [self removeObserver:self forKeyPath:@"vmFolder"];
                observerRegistered = NO;
        }
}

- (void)awakeFromInsert
{
        [super awakeFromInsert];
        if (!observerRegistered) {
                [self addObserver:self forKeyPath:@"datastore" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:self forKeyPath:@"hostFolder" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:self forKeyPath:@"vmFolder" options:NSKeyValueObservingOptionNew context:nil];
                observerRegistered = YES;
        }
}

- (void)awakeFromFetch
{
        [super awakeFromFetch];
        [self refreshStatistics];
        if (!observerRegistered) {
                [self addObserver:self forKeyPath:@"datastore" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:self forKeyPath:@"hostFolder" options:NSKeyValueObservingOptionNew context:nil];
                [self addObserver:self forKeyPath:@"vmFolder" options:NSKeyValueObservingOptionNew context:nil];
                observerRegistered = YES;
        }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
        [self refreshStatistics];
}

- (void)refreshStatistics
{
        cyclesAvailableMHz = 0;
        memoryAvailableMB = 0;
        cyclesUsedMHz = 0;
        memoryUsedMB = 0;
        totalCores = 0;

        if (![[self managedObjectContext] validateObject:self])
                return;

        NSArray *hosts = [self hosts];
        totalHosts = [hosts count];
        for (HostMO*host in hosts) {
                if (![host managedObjectContext] || [host isDeleted])
                        continue;

                int hostCores = [[host numCoresPerCpu] intValue];
                int hostCPUs = [[host numCpus] intValue];
                totalCores += hostCores * hostCPUs;
                cyclesAvailableMHz += [[host cyclesPerCpuMHz] intValue] * hostCores * hostCPUs;
                memoryAvailableMB += [[host totalMemoryMB] intValue];
                cyclesUsedMHz += [[host cpuUsageMHz] intValue];
                memoryUsedMB += [[host memoryUsageMB] intValue];
        }

        vmAllocatedCPUs = 0;
        vmAllocatedMemoryMB = 0;
        totalVMs = 0;
        NSArray *vms = [self vmsFromHosts:hosts];
        for (VirtualMachineMO*vm in vms) {
                if (![vm managedObjectContext] || [vm isDeleted])
                        continue;

                NSString *powerState = [vm powerState];
                BOOL normalVm = ![[vm isTemplate] isEqualToString:@"true"];
                if (normalVm) {
                        if ([powerState isEqualToString:@"poweredOn"]) {
                                vmAllocatedCPUs += [[vm configuredCpus] intValue];
                                vmAllocatedMemoryMB += [[vm configuredMemoryMB] intValue];
                        }
                        totalVMs++;
                }
        }

        datastoreTotalMB = 0;
        datastoreFreeMB = 0;
        NSSet *dss = [self datastore];
        totalDatastores = [dss count];
        for (NSManagedObject*ds in dss) {
                datastoreTotalMB += [[ds totalMB] intValue];
                datastoreFreeMB += [[ds freeMB] intValue];
        }
}

- (NSArray*)children
{
        NSMutableArray *results = [NSMutableArray array];

        if (![[self managedObjectContext] validateObject:self])
                return results;

        NSMutableArray *hostResults = [NSMutableArray array];
        for (NSManagedObject*child in self.hostFolder.childEntity) {
                if (![[child managedObjectContext] validateObject:child])
                        continue;

                if ([[[child entity] name] isEqualToString:@"computeresource"] ||
                    [[[child entity] name] isEqualToString:@"clustercomputeresource"])
                        [hostResults addObjectsFromArray:[[child host] allObjects]];
                else
                        [hostResults addObject:child];
        }
        if ([hostResults count] > 0) {
                NSDictionary *hostsItem = [NSDictionary dictionaryWithObjectsAndKeys:@"hostsystem", @"group", hostResults, @"items", nil];
                [results addObject:hostsItem];
        }

        NSMutableArray *vmResults = [NSMutableArray array];
        NSArray *vms = [self.vmFolder.childEntity allObjects];
        for (NSManagedObject*child in vms) {
                if (![[child managedObjectContext] validateObject:child])
                        continue;

                if ([[[child entity] name] isEqualToString:@"virtualmachine"]) {
                        if (![[(VirtualMachineMO*) child isTemplate] isEqualToString:@"true"])
                                [vmResults addObject:child];
                } else
                        [vmResults addObject:child];
        }
        if ([vmResults count] > 0) {
                NSDictionary *vmsItem = [NSDictionary dictionaryWithObjectsAndKeys:@"virtualmachine", @"group", vmResults, @"items", nil];
                [results addObject:vmsItem];
        }

        return results;
}

- (NSArray*)hosts
{
        return [self hostsFromSubtree:[self hostFolder]];
}

- (NSArray*)hostsFromSubtree:(FolderMO*)folder
{
        NSMutableArray *results = [NSMutableArray array];
        for (FolderMO*child in [folder childEntity]) {
                if ([[[child entity] name] isEqualToString:@"folder"])
                        [results addObjectsFromArray:[self hostsFromSubtree:child]];
                else if ([[[child entity] name] isEqualToString:@"computeresource"] ||
                         [[[child entity] name] isEqualToString:@"clustercomputeresource"])
                        [results addObjectsFromArray:[[child host] allObjects]];
        }
        return results;
}

- (NSArray*)vmsFromHosts:(NSArray*)hosts
{
        NSMutableArray *results = [NSMutableArray array];
        for (HostMO*host in hosts)
                [results addObjectsFromArray:[[host vm] allObjects]];
        return results;
}

- (NSSet*)allRecentTasks
{
        NSMutableSet *allTasks = [NSMutableSet setWithSet:[self recentTasks]];
        for (HostMO*host in [self hosts])
                [allTasks unionSet:[host allRecentTasks]];
        return allTasks;
}

@end
