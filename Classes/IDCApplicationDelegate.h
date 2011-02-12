//
// iDatacenterAppDelegate.h
// iDatacenter
//
// Created by Jakob Borg on 5/2/10.
// Copyright Jakob Borg 2010. All rights reserved.
//

#import "InfrastructureManager.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#define SURVEY_ALERT_TAG 1
#define BETA_ALERT_TAG 2

@class DatacenterDetailViewController;
@class EntityMasterViewController;
@class InitialSettingsController;
@class RootViewController;
@class SettingsManager;

@interface IDCApplicationDelegate : NSObject <UIApplicationDelegate, InfrastructureManagerDelegate> {
        NSManagedObjectModel *managedObjectModel;
        NSManagedObjectContext *managedObjectContext;
        NSPersistentStoreCoordinator *persistentStoreCoordinator;
        SettingsManager *settings;

        UIWindow *window;

        DatacenterDetailViewController *dashboardViewController;
        EntityMasterViewController *entityMasterViewController;
        InitialSettingsController *initialSettingsController;
        RootViewController *rootViewController;
        InfrastructureManager *infrastructureManager;
}

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) InfrastructureManager *infrastructureManager;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet DatacenterDetailViewController *dashboardViewController;
@property (nonatomic, retain) IBOutlet EntityMasterViewController *entityMasterViewController;
@property (nonatomic, retain) IBOutlet InitialSettingsController *initialSettingsController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;

- (void)hideInitialSettings;
- (void)showConnectionErrorAlert:(NSError*)error;

@end
