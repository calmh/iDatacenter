//
// VirtualMachineMO.h
// InfrastructureManager
//
// Created by Jakob Borg on 6/26/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "FolderMO.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class HostMO;
@class DatacenterMO;

@interface VirtualMachineMO : NSManagedObject { }

@property (readonly) NSString *currentPowerState;

- (NSComparisonResult)compareNames:(VirtualMachineMO*)other;

@end

@interface VirtualMachineMO (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSString *annotation;
@property (nonatomic, retain) NSNumber *configuredMemoryMB;
@property (nonatomic, retain) NSNumber *configuredCpus;
@property (nonatomic, retain) NSString *powerState;
@property (nonatomic, retain) NSString *guestFamily;
@property (nonatomic, retain) NSString *guestFullName;
@property (nonatomic, retain) NSString *guestHeartbeat;
@property (nonatomic, retain) NSNumber *guestMemoryUsageMB;
@property (nonatomic, retain) NSString *hardwareVersion;
@property (nonatomic, retain) NSNumber *hostMemoryUsageMB;
@property (nonatomic, retain) NSNumber *cpuDemandMHz;
@property (nonatomic, retain) NSNumber *cpuUsageMHz;
@property (nonatomic, retain) HostMO *host;
@property (nonatomic, retain) NSString *toolsStatus;
@property (nonatomic, retain) NSString *isTemplate;
@property (nonatomic, retain) NSArray *ipAddresses;
@property (nonatomic, retain) NSSet *datastores;
@property (nonatomic, retain) NSSet *network;
@property (nonatomic, retain) NSArray *diskCapacities;
@property (nonatomic, retain) NSArray *diskFreespace;
@property (nonatomic, retain) NSArray *diskNames;
@property (nonatomic, retain) NSNumber *cpuLimit;
@property (nonatomic, retain) NSNumber *cpuReservation;
@property (nonatomic, retain) NSNumber *memoryLimit;
@property (nonatomic, retain) NSNumber *memoryReservation;
- (void)addDatastoresObject:(NSManagedObject*)value;
- (void)removeDatastoresObject:(NSManagedObject*)value;
- (void)addDatastores:(NSSet*)value;
- (void)removeDatastores:(NSSet*)value;
@end
