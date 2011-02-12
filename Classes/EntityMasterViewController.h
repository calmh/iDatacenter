//
// HostsMasterViewController.h
// iDatacenter
//
// Created by Jakob Borg on 5/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "MasterViewControllerProtocol.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class IDCApplicationDelegate;
@class GeneralDetailViewController;
@class MBProgressHUD;

@interface EntityMasterViewController : UITableViewController <MasterViewControllerProtocol, NSFetchedResultsControllerDelegate, UISearchBarDelegate> {
        IDCApplicationDelegate *delegate;
        GeneralDetailViewController *detailViewController;
        UISearchBar *searchBar;
        NSManagedObject *parentObject;
        NSManagedObject *selectedObject;
        NSArray *currentObjects;
        UIView *backgroundView;
        MBProgressHUD *hud;
}

@property (nonatomic, assign) IBOutlet IDCApplicationDelegate *delegate;
@property (nonatomic, retain) IBOutlet GeneralDetailViewController *detailViewController;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (readonly) NSManagedObject *selectedObject;

- (void)selectEntityObject:(NSManagedObject*)object;
- (void)activateChildObject:(NSManagedObject*)object;

@end
