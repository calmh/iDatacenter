//
// GeneralDetailViewController.m
// iDatacenter
//
// Created by Jakob Borg on 5/16/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "EntityMasterViewController.h"
#import "GeneralDetailViewController.h"
#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import <QuartzCore/QuartzCore.h>

@interface GeneralDetailViewController ()
- (void)setContentFrame:(UIViewController*)controller;
- (void)addSelectionBarButtonItem:(UIBarButtonItem*)barButtonItem;
- (void)removeSelectionBarButtonItem;
@end

@implementation GeneralDetailViewController

@synthesize delegate;
@synthesize contentView;
@synthesize toolbar;
@synthesize popoverController;
@synthesize detailViewController;
@synthesize titleBar;
@synthesize datacenterDetailViewController;
@synthesize hostDetailViewController;
@synthesize vmDetailViewController;
@synthesize entityMasterViewController;

- (void)dealloc
{
        [contentView release];
        [toolbar release];
        [popoverController release];
        [titleBar release];
        [datacenterDetailViewController release];
        [hostDetailViewController release];
        [vmDetailViewController release];
        [entityMasterViewController release];
        [super dealloc];
}

- (void)viewDidLoad
{
        detailViewController = nil;
        NSMutableArray *buttons = [[[self toolbar] items] mutableCopy];
        visualizeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Visualize", nil) style:UIBarButtonItemStyleDone target:self action:@selector(visualize)];
        visualizeButton.enabled = NO;
        [buttons addObject:visualizeButton];
        self.toolbar.items = buttons;
}

- (void)setDetailObject:(NSManagedObject*)object
{
        if (object != previousMO) {
                if ([[[object entity] name] isEqualToString:@"folder"])
                        // Folders cannot be displayed yet.
                        return;

                [previousMO release];
                previousMO = [object retain];
                if ([[[object entity] name] isEqualToString:@"datacenter"])
                        self.detailViewController = datacenterDetailViewController;
                else if ([[[object entity] name] isEqualToString:@"hostsystem"])
                        self.detailViewController = hostDetailViewController;
                else if ([[[object entity] name] isEqualToString:@"virtualmachine"])
                        self.detailViewController = vmDetailViewController;
                [detailViewController setDetailObject:object];

                visualizeButton.enabled = [self canVisualize];

                NSString *objectTypeName = NSLocalizedString([[object entity] name], nil);
                NSString *objectFriendlyName = [object name];
                titleBar.title = [NSString stringWithFormat:@"%@: %@", objectTypeName, objectFriendlyName];
        }
}

- (void)setDetailViewController:(UIViewController<DetailViewControllerProtocol>*)controller
{
        if (detailViewController != controller) {
                CATransition *trans = [CATransition animation];
                [trans setType:kCATransitionFade];
                [trans setDuration:0.5];

                if (!detailViewController) {
                        // Remove temporary "select an object to view statistics" text etc.
                        for (UIView*subview in contentView.subviews)
                                [subview removeFromSuperview];
                } else {
                        [detailViewController viewWillDisappear:YES];
                        [detailViewController.view removeFromSuperview];
                        [detailViewController release];
                }

                detailViewController = [controller retain];

                [self setContentFrame:controller];
                [contentView addSubview:controller.view];
                [detailViewController viewWillAppear:YES];

                [[contentView layer] addAnimation:trans forKey:@"Transition"];
        }
}

- (void)setContentFrame:(UIViewController*)controller
{
        CGRect contentFrame = contentView.frame;
        controller.view.frame = CGRectMake(0.0f, 0.0f, contentFrame.size.width, contentFrame.size.height);
        [controller.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
}

- (void)viewDidAppear:(BOOL)animated
{
        DTRACE;
        [super viewDidAppear:YES];
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)  && selectionBarButtonIsVisible)
                [self removeSelectionBarButtonItem];
}

- (void)viewDidDisappear:(BOOL)animated
{
        DTRACE;
        [super viewDidDisappear:YES];
}

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController*)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc
{
        barButtonItem.title = NSLocalizedString(@"selection", nil);

        if (!selectionBarButtonIsVisible)
                [self addSelectionBarButtonItem:barButtonItem];
        pc.popoverContentSize = CGSizeMake(320, 700);
        self.popoverController = pc;
}

- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController*)aViewController invalidatingBarButtonItem:(UIBarButtonItem*)barButtonItem
{
        DTRACE;
        if (selectionBarButtonIsVisible)
                [self removeSelectionBarButtonItem];
        self.popoverController = nil;
}

- (void)addSelectionBarButtonItem:(UIBarButtonItem*)barButtonItem
{
        DTRACE;
        NSMutableArray *items = [toolbar.items mutableCopy];
        barButtonItem.title = NSLocalizedString(@"selection", nil);
        [items insertObject:barButtonItem atIndex:0];
        [toolbar setItems:items animated:YES];
        [items release];
        selectionBarButtonIsVisible = YES;
}

- (void)removeSelectionBarButtonItem
{
        DTRACE;
        NSMutableArray *items = [toolbar.items mutableCopy];
        [items removeObjectAtIndex:0];
        [toolbar setItems:items animated:YES];
        [items release];
        selectionBarButtonIsVisible = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)visualize
{
        if (self.popoverController)
                [self.popoverController dismissPopoverAnimated:YES];
        [detailViewController visualize];
}

- (BOOL)canVisualize
{
        return [detailViewController respondsToSelector:@selector(visualize)];
}

@end
