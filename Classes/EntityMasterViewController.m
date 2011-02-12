//
// HostsMasterViewController.m
// iDatacenter
//
// Created by Jakob Borg on 5/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "EntityMasterViewController.h"
#import "GeneralDetailViewController.h"
#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import "MBProgressHUD.h"

@interface EntityMasterViewController ()
- (int)totalItems;
- (int)totalItemsInArray:(NSArray*)objects;
- (EntityMasterViewController*)newViewControllerForObject:(NSManagedObject*)object;
- (NSArray*)currentObjects;
- (void)refreshCurrentObjects;
- (void)dismissKeyboard;
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void)setCellDetailText:(NSManagedObject*)managedObject cell:(UITableViewCell*)cell;
- (NSArray*)currentObjects;
- (void)managedObjectContextDidSave:(NSNotification*)notification;
@end

@implementation EntityMasterViewController

@synthesize delegate;
@synthesize detailViewController;
@synthesize searchBar;
@synthesize selectedObject;
@synthesize backgroundView;

- (void)dealloc
{
        [detailViewController release];
        [searchBar release];
        [super dealloc];
}

- (EntityMasterViewController*)newViewControllerForObject:(NSManagedObject*)object
{
        EntityMasterViewController *vc = [[EntityMasterViewController alloc] initWithNibName:@"EntityMasterViewController" bundle:nil];
        vc.delegate = delegate;
        vc.detailViewController = detailViewController;
        [vc selectEntityObject:object];
        return vc;
}

- (void)selectEntityObject:(NSManagedObject*)object
{
        [currentObjects release];
        currentObjects = nil;
        if (object != parentObject) {
                [parentObject release];
                parentObject = [object retain];
        }
        [self navigationItem].title = parentObject.name;
        [detailViewController setDetailObject:object];
}

- (void)activateChildObject:(NSManagedObject*)object
{
        if (selectedObject != object) {
                [selectedObject release];
                selectedObject = [object retain];
        }

        if ([self totalItemsInArray:[object children]] > 0) {
                EntityMasterViewController *nextController = [self newViewControllerForObject:object];
                [nextController autorelease];
                [[self navigationController] pushViewController:nextController animated:YES];
        } else {
                // This is a leaf node
                [detailViewController setDetailObject:object];
                // If we are in a popover, dismiss it.
                if (detailViewController.popoverController)
                        [detailViewController.popoverController dismissPopoverAnimated:YES];
        }
}

- (NSArray*)currentObjects
{
        if (currentObjects != nil)
                return currentObjects;

        if (!parentObject)
                return nil;

        NSArray *tmpObjects = [[[parentObject children] copy] autorelease];
        NSMutableArray *newObjects = [[NSMutableArray alloc] init];

        for (NSDictionary*dict in tmpObjects) {
                NSArray *items = [dict objectForKey:@"items"];
                if ([searchBar.text length] != 0) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", searchBar.text];
                        items = [items filteredArrayUsingPredicate:predicate];
                }

                NSSortDescriptor *byType = [[[NSSortDescriptor alloc] initWithKey:@"entity.name" ascending:YES] autorelease];
                NSSortDescriptor *byName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
                NSArray *descriptors = [NSArray arrayWithObjects:byType, byName, nil];
                NSArray *sortedItems = [items sortedArrayUsingDescriptors:descriptors];

                NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                [newDict setObject:sortedItems forKey:@"items"];
                [newObjects addObject:newDict];
        }

        [currentObjects release];
        currentObjects = newObjects;
        return currentObjects;
}

- (void)refreshCurrentObjects
{
        [currentObjects release];
        currentObjects = nil;
        if (![delegate.managedObjectContext validateObject:parentObject]) {
                parentObject = nil;
                [detailViewController setDetailObject:nil];
                [[self navigationController] popToRootViewControllerAnimated:YES];
                return;
        }
        [self navigationItem].title = parentObject.name;
}

- (int)totalItems
{
        return [self totalItemsInArray:[self currentObjects]];
}

- (int)totalItemsInArray:(NSArray*)objects
{
        int total = 0;
        for (NSDictionary*dic in objects)
                total += [[dic objectForKey:@"items"] count];
        return total;
}

/*
 * View life cycle methods.
 */

- (void)viewDidAppear:(BOOL)animated
{
        [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        self.tableView.backgroundView = backgroundView;
        (void) [self toolbarItems];
        self.contentSizeForViewInPopover = CGSizeMake(320, 350);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)viewDidUnload
{
        [super viewDidUnload];
        [currentObjects release];
        currentObjects = nil;
        [parentObject release];
        parentObject = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

/*
 * UITableView delegate methods.
 */

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
        NSManagedObject *object = [[[[self currentObjects] objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];

        [self dismissKeyboard];
        [self activateChildObject:object];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
        return [[self currentObjects] count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
        return [[[[self currentObjects] objectAtIndex:section] objectForKey:@"items"] count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
        static NSString *CellIdentifier = @"Cell";

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
                cell.backgroundColor = GRAY_CELL_BACKGROUND;
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
        }

        [self configureCell:cell atIndexPath:indexPath];

        return cell;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
        NSString *key = [[[self currentObjects] objectAtIndex:section] objectForKey:@"group"];
        if (key == nil)
                return nil;
        NSString *toLocalize = [NSString stringWithFormat:@"%@_plural", key];
        return NSLocalizedString(toLocalize, nil);
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
        [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
        [[cell detailTextLabel] setBackgroundColor:[UIColor clearColor]];
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
        NSManagedObject *managedObject = [[[[self currentObjects] objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
        [delegate.managedObjectContext refreshObject:managedObject mergeChanges:NO];

        cell.textLabel.text = [managedObject name];
        NSString *entityName = [[managedObject entity] name];
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"tvc-%@-%@.png", entityName, [managedObject overallStatus]]];
        if (!image && [managedObject respondsToSelector:@selector(inMaintenanceMode)] && [[managedObject performSelector:@selector(inMaintenanceMode)] isEqualToString:@"true"])
                image = [UIImage imageNamed:[NSString stringWithFormat:@"tvc-%@-maintenance-mode.png", entityName]];
        if (!image && [managedObject respondsToSelector:@selector(powerState)])
                image = [UIImage imageNamed:[NSString stringWithFormat:@"tvc-%@-%@.png", entityName, [managedObject performSelector:@selector(powerState)]]];
        if (!image)
                image = [UIImage imageNamed:[NSString stringWithFormat:@"tvc-%@.png", entityName]];
        cell.imageView.image = image;

        [self setCellDetailText:managedObject cell:cell];
}

- (void)setCellDetailText:(NSManagedObject*)managedObject cell:(UITableViewCell*)cell
{
        NSString *currentEntityName = [[managedObject entity] name];
        if ([currentEntityName isEqualToString:@"datacenter"]) {
                DatacenterMO *dc = (DatacenterMO*) managedObject;
                int hosts = [dc totalHosts];
                int vms = [dc totalVMs];
                if (hosts == 0)
                        cell.textLabel.textColor = [UIColor grayColor];
                else
                        cell.textLabel.textColor = [UIColor darkTextColor];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d hosts, %d VMs", hosts, vms];
        } else if ([currentEntityName isEqualToString:@"folder"]) {
                int children = [self totalItemsInArray:[managedObject children]];
                if (children == 0)
                        cell.textLabel.textColor = [UIColor grayColor];
                else
                        cell.textLabel.textColor = [UIColor darkTextColor];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d items", children];
        } else if ([currentEntityName isEqualToString:@"virtualmachine"])
                cell.detailTextLabel.text = nil;
        else if ([currentEntityName isEqualToString:@"hostsystem"]) {
                cell.detailTextLabel.text = nil;
                int vms = ((HostMO*) managedObject).totalVMs;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d VMs", vms];
        }
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)managedObjectContextDidSave:(NSNotification*)notification
{
        if (parentObject == nil) {
                NSManagedObject *root = [delegate.infrastructureManager rootFolderObject];

                if (!root) {
                        if (!hud) {
                                hud = [[MBProgressHUD alloc] initWithView:self.view];
                                [hud setLabelText:NSLocalizedString(@"Loading...", nil)];
                                self.view.alpha = 0.8f;
                                [self.view addSubview:hud];
                                [hud show:YES];
                        }
                } else {
                        [hud hide:YES];
                        self.view.alpha = 1.0f;

                        [delegate.managedObjectContext refreshObject:root mergeChanges:NO];
                        [self selectEntityObject:root];
                }
        }
        [self refreshCurrentObjects];
        [self.tableView reloadData];
}

/*
 * NSFetchedController delegate methods.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
        [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
       atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
        switch (type) {
        case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

        case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath*)newIndexPath
{
        UITableView *tableView = self.tableView;

        switch (type) {
        case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

        case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

        case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                break;

        case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
        [self.tableView endUpdates];
}

// UISearchBar delegate methods.

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
        DLOG(@"%@", searchText);
        [self refreshCurrentObjects];
        [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
        [self dismissKeyboard];
}

- (void)dismissKeyboard
{
        if ([searchBar isFirstResponder])
                [searchBar resignFirstResponder];
}

@end
