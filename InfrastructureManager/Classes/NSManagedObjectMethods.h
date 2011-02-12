/*
 *  NSManagedObjectMethods.h
 *  iDatacenter
 *
 *  Created by Jakob Borg on 5/29/10.
 *  Copyright 2010 Jakob Borg. All rights reserved.
 *
 */

@class DatacenterMO;
@class HostMO;
@class FolderMO;
@class VirtualMachineMO;

@interface NSManagedObject (Generic)
- (NSArray*)children;
@end

@interface NSManagedObject (ContentCoreDataGeneratedAccessors)
@property (nonatomic, retain) FolderMO *rootFolder;
@property (nonatomic, retain) NSString *authorizationManagerId;
@property (nonatomic, retain) NSManagedObject *licenseManager;
@end

@interface NSManagedObject (RefreshableObjectCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSArray *configIssues;
@property (nonatomic, retain) NSDate *fetchedDate;
@property (nonatomic, retain) NSString *id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *disabledMethods;
@property (nonatomic, retain) NSArray *effectiveRoles;
@property (nonatomic, retain) NSString *overallStatus;
@property (nonatomic, retain) NSSet *recentTasks;
- (void)addRecentTasksObject:(NSManagedObject*)value;
- (void)removeRecentTasksObject:(NSManagedObject*)value;
- (void)addRecentTasks:(NSSet*)value;
- (void)removeRecentTasks:(NSSet*)value;
@end

@interface NSManagedObject (DatastoreCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSNumber *totalMB;
@property (nonatomic, retain) NSNumber *freeMB;
@property (nonatomic, retain) NSString *dsType;
@property (nonatomic, retain) DatacenterMO *datacenter;
@property (nonatomic, retain) NSSet *vms;
@property (nonatomic, retain) NSSet *host;
- (void)addHostObject:(HostMO*)value;
- (void)removeHostObject:(HostMO*)value;
- (void)addHost:(NSSet*)value;
- (void)removeHost:(NSSet*)value;
- (void)addVmsObject:(VirtualMachineMO*)value;
- (void)removeVmsObject:(VirtualMachineMO*)value;
- (void)addVms:(NSSet*)value;
- (void)removeVms:(NSSet*)value;
@end

@interface NSManagedObject (ComputeResourceCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSSet *host;
- (void)addHostObject:(HostMO*)value;
- (void)removeHostObject:(HostMO*)value;
- (void)addHost:(NSSet*)value;
- (void)removeHost:(NSSet*)value;
@end

@interface NSManagedObject (RoleListCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSString *id;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *privileges;
@property (nonatomic, retain) NSNumber *roleId;
@property (nonatomic, retain) NSString *summary;
@end

@interface NSManagedObject (TaskCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSString *cancelable;
@property (nonatomic, retain) NSString *cancelled;
@property (nonatomic, retain) NSString *descriptionId;
@property (nonatomic, retain) NSNumber *eventChainId;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSManagedObject *belongsTo;
@property (nonatomic, retain) NSDate *completed;
@property (nonatomic, retain) NSDate *queued;
@property (nonatomic, retain) NSDate *started;
@property (nonatomic, retain) NSNumber *progress;
@end

@interface NSManagedObject (LicenseManagerCoreDataGeneratedAccessors)
@property (nonatomic, retain) id editions;
@end

@interface NSManagedObject (NetworkCoreDataGeneratedAccessors)
@property (nonatomic, retain) NSSet *host;
@property (nonatomic, retain) NSSet *vm;
@property (nonatomic, retain) NSString *name;
@end
