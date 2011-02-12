//
// iDatacenterAppDelegate.m
// iDatacenter
//
// Created by Jakob Borg on 5/2/10.
// Copyright Jakob Borg 2010. All rights reserved.
//

#import <unistd.h>
#import "DatacenterDetailViewController.h"
#import "EntityMasterViewController.h"
#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import "InitialSettingsController.h"
#import "RootViewController.h"
#import "NSDate+Parsing.h"
#import "IDCApplicationDelegate+Survey.h"
#import "SettingsManager.h"

@interface IDCApplicationDelegate ()
- (void)showInitialSettings;
- (NSString*)applicationDocumentsDirectory;
- (void)saveSelectionStack;
- (void)loadSelectionStack;
#if defined(ADHOC) || defined(DEBUG)
- (void)displayStartupMessage;
#endif
@end

@implementation IDCApplicationDelegate

@synthesize window;
@synthesize dashboardViewController;
@synthesize initialSettingsController;
@synthesize rootViewController;
@synthesize entityMasterViewController;
@synthesize infrastructureManager;

- (void)dealloc
{
        [managedObjectContext release];
        [managedObjectModel release];
        [persistentStoreCoordinator release];

        [window release];
        [dashboardViewController release];
        [initialSettingsController release];
        [rootViewController release];
        [entityMasterViewController release];
        [infrastructureManager release];

        [super dealloc];
}

- (void)showInitialSettings
{
        initialSettingsController.modalPresentationStyle = UIModalPresentationFormSheet;
        [rootViewController presentModalViewController:initialSettingsController animated:YES];
}

- (void)hideInitialSettings
{
        [initialSettingsController dismissModalViewControllerAnimated:YES];
        [infrastructureManager start];
}

- (void)connectionFailedWithError:(NSError*)error
{
        static BOOL showedAlert = NO;
        if (!showedAlert) {
                [self performSelectorOnMainThread:@selector(showConnectionErrorAlert:) withObject:error waitUntilDone:YES];
                showedAlert = YES;
        }
}

- (void)showConnectionErrorAlert:(NSError*)error
{
        NSInteger code = [error code];
        NSString *message = nil;

        if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                if (code == NSURLErrorCannotFindHost)
                        message = NSLocalizedString(@"cannot_find_server", nil);
                else if (code == NSURLErrorNotConnectedToInternet)
                        message = NSLocalizedString(@"could_not_connect", nil);
                else if (code == NSURLErrorUserCancelledAuthentication)
                        message = NSLocalizedString(@"refused_auth", nil);
                else if (code == NSURLErrorTimedOut || code == NSURLErrorCannotConnectToHost)
                        message = NSLocalizedString(@"timeout", nil);
        } else if ([[error domain] isEqualToString:@"custom"]) {
                if (code == 404)
                        message = NSLocalizedString(@"error_404", nil);
        }

        if (message == nil)
                message = [NSString stringWithFormat:@"%@ (%@ %d)", [error localizedDescription], [error domain], [error code]];
        else
                message = [NSString stringWithFormat:@"%@\n\n(%@ %d)", message, [error domain], [error code]];


        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"network_error", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease];
        [alert show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
        if (alertView.tag == SURVEY_ALERT_TAG)   // Survey prompt
                [self surveyAlertclickedButtonAtIndex:buttonIndex];
        else if (alertView.tag == BETA_ALERT_TAG) {   // Beta warning with twitter link
                if (buttonIndex == 1)
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/nymnetworks"]];
        }
}

- (void)saveSelectionStack
{
        NSMutableArray *currentSelectionStack = [NSMutableArray array];
        for (EntityMasterViewController*vc in entityMasterViewController.navigationController.viewControllers) {
                NSManagedObjectID *objectId = [vc.selectedObject objectID];
                if (objectId == nil)
                        break;
                NSURL *idUri = [objectId URIRepresentation];
                [currentSelectionStack addObject:[idUri description]];
        }
        NSString *filename = [NSString stringWithFormat:@"%@/stack.plist", [self applicationDocumentsDirectory]];
        [currentSelectionStack writeToFile:filename atomically:YES];
}

- (void)loadSelectionStack
{
        NSString *filename = [NSString stringWithFormat:@"%@/stack.plist", [self applicationDocumentsDirectory]];
        NSArray *selectionStack = [NSArray arrayWithContentsOfFile:filename];
        for (NSString*uriStr in selectionStack) {
                NSURL *idUri = [NSURL URLWithString:uriStr];
                NSManagedObject *object = [managedObjectContext objectWithURI:idUri];
                if (!object)
                        break;
                EntityMasterViewController *vc =  (EntityMasterViewController*) entityMasterViewController.navigationController.visibleViewController;
                [vc activateChildObject:object];
        }
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
        settings = [SettingsManager instance];

        // Attempt to delete the old core data store that is no longer needed.
        [[NSFileManager defaultManager] removeItemAtPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"iDatacenter.sqlite"] error:nil];

        [window addSubview:rootViewController.view];
        [window makeKeyAndVisible];

#if !defined(ADHOC) && !defined(DEBUG)
        [self conditionallyDisplaySurveyPrompt];
#endif

        if ([self managedObjectContext]) { // Only proceed if we can start the Core Data stack.
                infrastructureManager = [[InfrastructureManager alloc] initWithManagedObjectContext:self.managedObjectContext model:self.managedObjectModel];
                infrastructureManager.delegate = self;

                if (!settings.rememberPassword || !settings.server || [settings.server length] == 0)
                        [self showInitialSettings];
                else {
                        [infrastructureManager start];
#if defined(ADHOC) || defined(DEBUG)
                        [self displayStartupMessage];
#endif
                }
        }
        return YES;
}

/**
   applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication*)application
{
        NSError *error = nil;
        if (managedObjectContext != nil) {
                if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                        // Doesn't really matter if we fail to save, since it will be reloaded on next restart.
                }
        }

        [self saveSelectionStack];
}

#pragma mark Core Data stack

- (NSManagedObjectContext*)managedObjectContext
{
        if (managedObjectContext != nil)
                return managedObjectContext;

        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
                managedObjectContext = [[NSManagedObjectContext alloc] init];
                [managedObjectContext setPersistentStoreCoordinator:coordinator];
        }

        return managedObjectContext;
}

- (NSManagedObjectModel*)managedObjectModel
{
        if (managedObjectModel != nil)
                return managedObjectModel;

        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
        return managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
        if (persistentStoreCoordinator != nil)
                return persistentStoreCoordinator;

        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error]) {
                // This is going nowhere, alert user and halt.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unrecoverable error", nil) message:NSLocalizedString(@"dbError", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [alert show];
                return nil;
        }

        return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's Documents directory

/**
   Returns the path to the application's Documents directory.
 */
- (NSString*)applicationDocumentsDirectory
{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        return [paths lastObject];
}

#if defined(ADHOC) || defined(DEBUG)
- (void)displayStartupMessage
{
        NSString *message = nil;
        if (!settings.displayedBetaWarning) {
                message = NSLocalizedString(@"betaMessage", nil);
                settings.displayedBetaWarning = YES;
        }

        if (settings.installedTimeInterval > MAX_BETA_AGE)
                message = NSLocalizedString(@"oldBetaMessage", nil);

        if (message) {
                NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                NSString *title = [NSString stringWithFormat:@"iDatacenter %@", currentVersion];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:NSLocalizedString(@"Twitter", nil), nil];
                alert.tag = BETA_ALERT_TAG;
                [alert show];
                [alert release];
        }
}

#endif

@end
