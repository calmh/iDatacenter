//
// BaseDetailViewController.h
// iDatacenter
//
// Created by Jakob Borg on 5/25/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DetailViewControllerProtocol.h"
#import "IDCApplicationDelegate.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class DetailTableViewController;
@class IDCApplicationDelegate;

@interface BaseDetailViewController : UIViewController <DetailViewControllerProtocol> {
        NSManagedObjectContext *managedObjectContext;
        NSManagedObjectModel *managedObjectModel;
        NSManagedObject *currentObject;
        IDCApplicationDelegate *delegate;
        NSFetchRequest *latestUpdateFr;
        NSDateFormatter *dateFormatter;
        NSTimer *timer;

        DetailTableViewController *detailsTableController;
}

@property (assign, nonatomic) IBOutlet IDCApplicationDelegate *delegate;
@property (nonatomic, retain) IBOutlet DetailTableViewController *detailsTableController;
@property (readonly) NSManagedObject *currentObject;

- (void)setDetailObject:(NSManagedObject*)object;
- (NSString*)localizedTimestampForDate:(NSDate*)date;
- (void)periodicUpdateView:(NSTimer*)timer;
- (void)invalidateCurrentObject:(NSNotification*)notification;

@end
