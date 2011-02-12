//
// BaseDetailViewController.m
// iDatacenter
//
// Created by Jakob Borg on 5/25/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "BaseDetailViewController.h"
#import "IDCApplicationDelegate.h"
#import "VMDetailTableViewController.h"

@interface BaseDetailViewController ()
- (NSArray*)sortedRecentTaskList;
@end

@implementation BaseDetailViewController

@synthesize delegate;
@synthesize detailsTableController;
@synthesize currentObject;

- (void)dealloc
{
        [currentObject release];
        [latestUpdateFr release];
        [dateFormatter release];
        [super dealloc];
}

- (void)setDetailObject:(NSManagedObject*)object
{
        if (object != currentObject) {
                [currentObject release];
                currentObject = [object retain];
                [detailsTableController setDebugData:[currentObject.effectiveRoles componentsJoinedByString:@", "] forKey:@"effectiveRoles"];
                [detailsTableController setDebugData:[NSString stringWithFormat:@"%d", [[delegate.infrastructureManager privilegesForEffectiveRoleIds:currentObject.effectiveRoles] count]] forKey:@"numPrivileges"];
                [detailsTableController setDebugData:[NSString stringWithFormat:@"%d", [currentObject.disabledMethods count]] forKey:@"numDisabledMethods"];
                [self periodicUpdateView:nil];
                [detailsTableController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
}

- (NSString*)localizedTimestampForDate:(NSDate*)date
{
        if (!dateFormatter)
                dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        return [dateFormatter stringFromDate:date];
}

- (void)periodicUpdateView:(NSTimer*)timer
{
        if (![[currentObject managedObjectContext] validateObject:currentObject]) {
                currentObject = nil;
                return;
        }

        [detailsTableController updateRecentTasks:[self sortedRecentTaskList]];
        [detailsTableController updateConfigurationIssues:[currentObject configIssues]];
        [detailsTableController updateWithObject:currentObject];
}

- (void)invalidateCurrentObject:(NSNotification*)notification
{
        if (currentObject != nil)
                [managedObjectContext refreshObject:currentObject mergeChanges:NO];
}

/*
 * Private methods below.
 */

- (NSArray*)sortedRecentTaskList
{
        NSSet *tasks = nil;

        if ([currentObject respondsToSelector:@selector(allRecentTasks)])
                tasks = [(id) currentObject allRecentTasks];
        else
                tasks = [currentObject recentTasks];

        NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"queued" ascending:NO selector:@selector(compare:)] autorelease];
        NSArray *sortedTasks = [[tasks allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
        return sortedTasks;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
        [super viewWillAppear:animated];
        timer = [NSTimer timerWithTimeInterval:UI_REFRESH_INTERVAL target:self selector:@selector(periodicUpdateView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated
{
        [super viewWillDisappear:animated];
        [timer invalidate];
        timer = nil;
}

- (void)viewDidLoad
{
        [super viewDidLoad];

        managedObjectModel = [[delegate managedObjectModel] retain];
        managedObjectContext = [[delegate managedObjectContext] retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateCurrentObject:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)viewDidUnload
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [managedObjectModel release];
        [managedObjectContext release];
        [super viewDidUnload];
}

@end
