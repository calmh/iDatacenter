//
// InfrastructureManager.h
// iDatacenter
//
// Created by Jakob Borg on 5/2/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DatacenterMO.h"
#import "FolderMO.h"
#import "HostMO.h"
#import "LinksDebugger.h"
#import "NSManagedObjectContext+Safety.h"
#import "NSManagedObjectMethods.h"
#import "VirtualMachineMO.h"
#import "SOAP.h"

@protocol InfrastructureManagerDelegate
@optional
- (void)connectionTestSucceeded;
- (void)connectionFailedWithError:(NSError*)error;
@end

@class LinksDebugger;
@class SettingsManager;

@interface InfrastructureManager : NSObject<SOAPDelegate> {
        NSObject<InfrastructureManagerDelegate> *delegate;
        BOOL inConnectionTest;
        NSMutableDictionary *updateQueue;
        NSMutableArray *restClients;
        NSURL *baseUrl;
        NSString *username;
        NSString *password;
        int failures;
        int updatedObjects;
        NSManagedObjectContext *managedObjectContext;
        NSManagedObjectModel *managedObjectModel;
        LinksDebugger *debugger;
        SOAP *soap;
        SettingsManager *settings;
}

@property (nonatomic, assign) IBOutlet NSObject<InfrastructureManagerDelegate> *delegate;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context model:(NSManagedObjectModel*)model;
- (void)start;
- (FolderMO*)rootFolderObject;
- (void)testConnectionWithServer:(NSString*)host username:(NSString*)username password:(NSString*)password delegate:(NSObject<InfrastructureManagerDelegate>*)aDelegate;
- (void)rebootGuest:(NSString*)vmObjectId;
- (void)shutdownGuest:(NSString*)vmObjectId;
- (void)powerCycleVM:(NSString*)vmObjectId;
- (void)powerOnVM:(NSString*)vmObjectId;
- (void)powerOffVM:(NSString*)vmObjectId;
- (void)suspendVM:(NSString*)vmObjectId;
- (void)relocateVM:(NSString*)vmObjectId toDatastoreId:(NSString*)dsId;
- (void)enterHostMaintenanceMode:(NSString*)vmObjectId;
- (void)exitHostMaintenanceMode:(NSString*)vmObjectId;
- (void)rebootHost:(NSString*)vmObjectId;
- (void)disconnectHost:(NSString*)vmObjectId;
- (void)reconnectHost:(NSString*)vmObjectId;
- (void)shutdownHost:(NSString*)vmObjectId;
- (NSSet*)privilegesForEffectiveRoleIds:(NSArray*)roleIds;
- (NSManagedObject*)fetchObjectWithId:(NSString*)objectId;
- (NSManagedObject*)fetchRoleWithId:(int)roleId;
- (BOOL)permissionForOperation:(NSString*)operation withDisabler:(NSString*)disabler onObject:(NSManagedObject*)object;

@end
