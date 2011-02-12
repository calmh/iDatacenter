//
// DatacenterMO.h
// iDatacenter
//
// Created by Jakob Borg on 5/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "FolderMO.h"
#import "NSManagedObjectMethods.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class FolderMO;

@interface DatacenterMO : NSManagedObject {
        int cyclesAvailableMHz;
        int memoryAvailableMB;
        int cyclesUsedMHz;
        int memoryUsedMB;
        int totalHosts;
        int totalCores;

        int totalVMs;
        int vmAllocatedCPUs;
        int vmAllocatedMemoryMB;

        int totalDatastores;
        int datastoreTotalMB;
        int datastoreFreeMB;

        BOOL observerRegistered;
}

@property (readonly) int cyclesAvailableMHz;
@property (readonly) int memoryAvailableMB;
@property (readonly) int cyclesUsedMHz;
@property (readonly) int memoryUsedMB;
@property (readonly) int totalHosts;
@property (readonly) int totalCores;

@property (readonly) int totalVMs;
@property (readonly) int vmAllocatedCPUs;
@property (readonly) int vmAllocatedMemoryMB;

@property (readonly) int totalDatastores;
@property (readonly) int datastoreTotalMB;
@property (readonly) int datastoreFreeMB;

- (NSSet*)allRecentTasks;

@end

@interface DatacenterMO (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSSet *datastore;
@property (nonatomic, retain) FolderMO *hostFolder;
@property (nonatomic, retain) FolderMO *vmFolder;

- (void)addDatastoreObject:(NSManagedObject*)value;
- (void)removeDatastoreObject:(NSManagedObject*)value;
- (void)addDatastore:(NSSet*)value;
- (void)removeDatastore:(NSSet*)value;
@end
