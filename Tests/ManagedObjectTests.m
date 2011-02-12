//
// DatacenterTests.m
// iDatacenter
//
// Created by Jakob Borg on 5/4/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "ManagedObjectTests.h"

@interface ManagedObjectTests ()
- (DatacenterMO*)createDatacenterWithFoldersAndId:(NSString*)objectId;
- (NSSet*)setOfxFolders:(int)numFolders;
- (NSArray*)addHostsToFolders:(NSSet*)folders;
- (FolderMO*)computeResourceHostWithCores:(int)cores mhz:(int)mhz memory:(int)memory usedMhz:(int)usedMhz usedMemory:(int)usedMemory;
- (void)addVMsToFolders:(NSSet*)folders andHost:(HostMO*)host;
- (VirtualMachineMO*)virtualMachineWithCPUs:(int)cpus memory:(int)memory powerState:(NSString*)powerState isTemplate:(NSString*)template;
- (void)addDatastoresToDatacenter:(DatacenterMO*)dc;
- (NSManagedObject*)datastoreWithCapacity:(int)capacity freeSpace:(int)freeSpace;
- (NSManagedObject*)taskWithDescriptionId:(NSString*)descriptionId;
@end

@implementation ManagedObjectTests

- (void)setUp
{
        [super setUp];

        // Create a datacenter with a few folders and physical hosts.
        datacenter = [self createDatacenterWithFoldersAndId:@"dc-1"];
        NSSet *fiveFolders = [self setOfxFolders:5];
        NSArray *hosts = [self addHostsToFolders:fiveFolders];
        host = [hosts lastObject];
        [[datacenter hostFolder] setValue:fiveFolders forKey:@"childEntity"];

        fiveFolders = [self setOfxFolders:5];
        [self addVMsToFolders:fiveFolders andHost:host];
        vm = [[[fiveFolders anyObject] childEntity] anyObject];
        [[datacenter vmFolder] setValue:fiveFolders forKey:@"childEntity"];

        [self addDatastoresToDatacenter:datacenter];

        // And another, whose hosts should not count in the tests below.
        DatacenterMO *otherDc = [self createDatacenterWithFoldersAndId:@"dc-2"];
        fiveFolders = [self setOfxFolders:5];
        hosts = [self addHostsToFolders:fiveFolders];
        [[otherDc hostFolder] setValue:fiveFolders forKey:@"childEntity"];

        fiveFolders = [self setOfxFolders:5];
        [self addVMsToFolders:fiveFolders andHost:[hosts lastObject]];
        [[otherDc vmFolder] setValue:fiveFolders forKey:@"childEntity"];

        [self addDatastoresToDatacenter:otherDc];

        NSError *error = nil;
        [managedObjectContext save:&error];
        STAssertNil(error, nil);
}

- (DatacenterMO*)createDatacenterWithFoldersAndId:(NSString*)objectId
{
        DatacenterMO *dc = (DatacenterMO*) [NSEntityDescription insertNewObjectForEntityForName:@"datacenter" inManagedObjectContext:managedObjectContext];
        [dc setValue:objectId forKey:@"id"];
        NSManagedObject *hostFolder = [NSEntityDescription insertNewObjectForEntityForName:@"folder" inManagedObjectContext:managedObjectContext];
        [hostFolder setValue:@"hostFolder" forKey:@"id"];
        [dc setValue:hostFolder forKey:@"hostFolder"];
        NSManagedObject *vmFolder = [NSEntityDescription insertNewObjectForEntityForName:@"folder" inManagedObjectContext:managedObjectContext];
        [vmFolder setValue:@"vmFolder" forKey:@"id"];
        [dc setValue:vmFolder forKey:@"vmFolder"];
        [dc addRecentTasksObject:[self taskWithDescriptionId:@"datacenter.created"]];
        return dc;
}

- (NSSet*)setOfxFolders:(int)numFolders
{
        NSMutableSet *set = [NSMutableSet set];
        for (int i = 0; i < numFolders; i++) {
                FolderMO *folder = (FolderMO*) [NSEntityDescription insertNewObjectForEntityForName:@"folder" inManagedObjectContext:managedObjectContext];
                folder.id = @"auto-folder";
                [set addObject:folder];
        }
        return set;
}

- (NSArray*)addHostsToFolders:(NSSet*)folders
{
        NSMutableArray *hosts = [NSMutableArray array];
        for (FolderMO*folder in folders) {
                FolderMO *cr1 = [self computeResourceHostWithCores:1 mhz:1500 memory:4 * 1024 usedMhz:1000 usedMemory:768];
                [hosts addObject:[[cr1 host] anyObject]];
                [folder addChildEntityObject:cr1];
                FolderMO *cr2 = [self computeResourceHostWithCores:2 mhz:2000 memory:8 * 1024 usedMhz:1500 usedMemory:1024];
                [hosts addObject:[[cr2 host] anyObject]];
                [folder addChildEntityObject:cr2];
        }
        return hosts;
}

- (FolderMO*)computeResourceHostWithCores:(int)cores mhz:(int)mhz memory:(int)memory usedMhz:(int)usedMhz usedMemory:(int)usedMemory
{
        HostMO *hostSystem = [NSEntityDescription insertNewObjectForEntityForName:@"hostsystem" inManagedObjectContext:managedObjectContext];
        hostSystem.id = @"hs1";
        hostSystem.numCpus = [NSNumber numberWithInt:1];
        hostSystem.numCoresPerCpu = [NSNumber numberWithInt:cores];
        hostSystem.cyclesPerCpuMHz = [NSNumber numberWithInt:mhz];
        hostSystem.totalMemoryMB = [NSNumber numberWithInt:memory];
        hostSystem.cpuUsageMHz = [NSNumber numberWithInt:usedMhz];
        hostSystem.memoryUsageMB = [NSNumber numberWithInt:usedMemory];
        [hostSystem addRecentTasksObject:[self taskWithDescriptionId:@"hostsystem.created"]];

        FolderMO *computeResource = [NSEntityDescription insertNewObjectForEntityForName:@"computeresource" inManagedObjectContext:managedObjectContext];
        [computeResource setId:@"id"];
        [computeResource addHostObject:hostSystem];
        return computeResource;
}

- (void)addVMsToFolders:(NSSet*)folders andHost:(HostMO*)theHost;
{
        for (FolderMO*folder in folders) {
                VirtualMachineMO *vm1 = [self virtualMachineWithCPUs:1 memory:1024 powerState:@"poweredOff" isTemplate:@"false"];
                [theHost addVmObject:vm1];
                [folder addChildEntityObject:vm1];
                VirtualMachineMO *vm2 = [self virtualMachineWithCPUs:2 memory:1538 powerState:@"poweredOn" isTemplate:@"false"];
                [theHost addVmObject:vm2];
                [folder addChildEntityObject:vm2];
                VirtualMachineMO *vm3 = [self virtualMachineWithCPUs:2 memory:1538 powerState:@"poweredOff" isTemplate:@"true"];
                [theHost addVmObject:vm3];
                [folder addChildEntityObject:vm3];
        }
}

- (VirtualMachineMO*)virtualMachineWithCPUs:(int)cpus memory:(int)memory powerState:(NSString*)powerState isTemplate:(NSString*)template
{
        VirtualMachineMO *tvm = [NSEntityDescription insertNewObjectForEntityForName:@"virtualmachine" inManagedObjectContext:managedObjectContext];
        tvm.id = @"vm-1";
        tvm.configuredCpus = [NSNumber numberWithInt:cpus];
        tvm.configuredMemoryMB = [NSNumber numberWithInt:memory];
        tvm.powerState = powerState;
        tvm.isTemplate = template;
        if (![template isEqualToString:@"true"])
                [tvm addRecentTasksObject:[self taskWithDescriptionId:@"virtualmachine.created"]];
        return tvm;
}

- (void)addDatastoresToDatacenter:(DatacenterMO*)dc
{
        int tb = 1024 * 1024;
        NSManagedObject *ds1 = [self datastoreWithCapacity:4 * tb freeSpace:3 * tb];
        NSManagedObject *ds2 = [self datastoreWithCapacity:2 * tb freeSpace:1 * tb];
        NSSet *stores = [NSSet setWithObjects:ds1, ds2, nil];
        [dc setValue:stores forKey:@"datastore"];
}

- (NSManagedObject*)datastoreWithCapacity:(int)capacity freeSpace:(int)freeSpace
{
        NSManagedObject *datastore = [NSEntityDescription insertNewObjectForEntityForName:@"datastore" inManagedObjectContext:managedObjectContext];
        datastore.id = @"ds-1";
        datastore.totalMB = [NSNumber numberWithInt:capacity];
        datastore.freeMB = [NSNumber numberWithInt:freeSpace];
        [datastore addRecentTasksObject:[self taskWithDescriptionId:@"datastore.created"]];
        return datastore;
}

- (NSManagedObject*)taskWithDescriptionId:(NSString*)descriptionId
{
        NSManagedObject *task = [NSEntityDescription insertNewObjectForEntityForName:@"task" inManagedObjectContext:managedObjectContext];
        task.id = @"task-1";
        task.descriptionId = descriptionId;
        return task;
}

- (void)tearDown
{
        [super tearDown];
}

- (void)testDatacenterIsCorrectObject
{
        STAssertEqualObjects([datacenter id], @"dc-1", nil);
}

- (void)testDatacenter_totalCores
{
        STAssertEquals(datacenter.totalCores, 5 * 1 + 5 * 2, nil);
}

- (void)testDatacenter_cyclesAvailableMHz
{
        STAssertEquals(datacenter.cyclesAvailableMHz, 5 * 1 * 1500 + 5 * 2 * 2000, nil);
}

- (void)testDatacenter_memoryAvailableMB
{
        STAssertEquals(datacenter.memoryAvailableMB, 5 * 4 * 1024 + 5 * 8 * 1024, nil);
}

- (void)testDatacenter_cyclesUsedMHz
{
        STAssertEquals(datacenter.cyclesUsedMHz, 5 * 1000 + 5 * 1500, nil);
}

- (void)testDatacenter_memoryUsedMB
{
        STAssertEquals(datacenter.memoryUsedMB, 5 * 1 * 768 + 5 * 1024, nil);
}

- (void)testDatacenter_totalHosts
{
        STAssertEquals(datacenter.totalHosts, 10, nil);
}

- (void)testDatacenter_totalVMs
{
        STAssertEquals(datacenter.totalVMs, 1 * 5 + 1 * 5, nil);
}

- (void)testDatacenter_vmAllocatedCPUs
{
        STAssertEquals(datacenter.vmAllocatedCPUs, 0 * 5 * 1 + 1 * 5 * 2, nil);
}

- (void)testDatacenter_vmAllocatedMemoryMB
{
        STAssertEquals(datacenter.vmAllocatedMemoryMB, 0 * 5 * 1024 + 1 * 5 * 1538, nil);
}

- (void)testDatacenter_totalDatastores
{
        STAssertEquals(datacenter.totalDatastores, 2, nil);
}

- (void)testDatacenter_datastoreTotalMB
{
        int tb = 1024 * 1024;
        STAssertEquals(datacenter.datastoreTotalMB, 4 * tb + 2 * tb, nil);
}

- (void)testDatacenter_datastoreFreeMB
{
        int tb = 1024 * 1024;
        STAssertEquals(datacenter.datastoreFreeMB, 3 * tb + 1 * tb, nil);
}

- (void)testDatacenter_recentTasks
{
        STAssertEquals([datacenter.recentTasks count], 1u, nil);
}

- (void)testDatacenter_allRecentTasks
{
        STAssertEquals([[datacenter allRecentTasks] count], 1u + 10u + 10u, nil);
}

- (void)testHost_numCpus
{
        STAssertEquals([host.numCpus intValue], 1, nil);
}

- (void)testHost_totalVMs
{
        STAssertEquals(host.totalVMs, 5 * 2, nil);
}

- (void)testHost_vmAllocatedCPUs
{
        STAssertEquals(host.vmAllocatedCPUs, 5 * 3, nil);
}

- (void)testHost_vmAllocatedMemoryMB
{
        STAssertEquals(host.vmAllocatedMemoryMB, 5 * 1024 + 5 * 1538, nil);
}

- (void)testHost_cyclesAvailable
{
        STAssertEquals(host.cyclesAvailable, 1 * 2 * 2000, nil);
}

- (void)testHost_cyclesUsedPercent
{
        STAssertEquals(host.cyclesUsedPercent, 100 * 1500 / (1 * 2 * 2000), nil);
}

- (void)testHost_memoryUsedPercent
{
        STAssertEquals(host.memoryUsedPercent, 100 * 1024 / 8192, nil);
}

- (void)testHost_recentTasks
{
        STAssertEquals([host.recentTasks count], 1u, nil);
}

- (void)testHost_allRecentTasks
{
        STAssertEquals([[host allRecentTasks] count], 1u + 10u, nil);
}

- (void)testDateParsing
{
        NSDate *testDate = [NSDate dateByParsingXmlFormat:@"2010-07-24T10:10:14.091484Z"];
        STAssertEqualsWithAccuracy([testDate timeIntervalSince1970], (NSTimeInterval) 1279966214.09, 0.01, nil);
}

@end
