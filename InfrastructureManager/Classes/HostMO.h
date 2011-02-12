//
// HostMO.h
// iDatacenter
//
// Created by Jakob Borg on 5/29/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "FolderMO.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class VirtualMachineMO;

@interface HostMO : NSManagedObject {
        int totalVMs;
        int vmAllocatedCPUs;
        int vmAllocatedMemoryMB;

        BOOL observerRegistered;
}

@property (readonly) int vmAllocatedCPUs;
@property (readonly) int vmAllocatedMemoryMB;
@property (readonly) int totalVMs;
@property (readonly) int cyclesAvailable;
@property (readonly) int cyclesUsedPercent;
@property (readonly) int memoryUsedPercent;

- (NSSet*)allRecentTasks;

@end

@interface HostMO (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSString *connectionInformation;
@property (nonatomic, retain) NSNumber *cpuUsageMHz;
@property (nonatomic, retain) NSString *inMaintenanceMode;
@property (nonatomic, retain) NSNumber *cyclesPerCpuMHz;
@property (nonatomic, retain) NSNumber *memoryUsageMB;
@property (nonatomic, retain) NSNumber *numCoresPerCpu;
@property (nonatomic, retain) NSNumber *numCpus;
@property (nonatomic, retain) NSNumber *numThreadsPerCore;
@property (nonatomic, retain) NSString *powerState;
@property (nonatomic, retain) NSString *prodBuild;
@property (nonatomic, retain) NSString *prodFullName;
@property (nonatomic, retain) NSString *prodName;
@property (nonatomic, retain) NSString *prodVersion;
@property (nonatomic, retain) NSString *hwCpuModel;
@property (nonatomic, retain) NSString *hwModel;
@property (nonatomic, retain) NSNumber *hwNumHBAs;
@property (nonatomic, retain) NSNumber *hwNumNICs;
@property (nonatomic, retain) NSString *hwVendor;
@property (nonatomic, retain) NSNumber *totalMemoryMB;
@property (nonatomic, retain) NSManagedObject *parent;
@property (nonatomic, retain) NSSet *vm;
@property (nonatomic, retain) NSSet *datastore;
@property (nonatomic, retain) NSSet *network;
- (void)addDatastoreObject:(NSManagedObject*)value;
- (void)removeDatastoreObject:(NSManagedObject*)value;
- (void)addDatastore:(NSSet*)value;
- (void)removeDatastore:(NSSet*)value;
- (void)addVmObject:(VirtualMachineMO*)value;
- (void)removeVmObject:(VirtualMachineMO*)value;
- (void)addVm:(NSSet*)value;
- (void)removeVm:(NSSet*)value;
@end
