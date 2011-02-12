//
// RootViewController.m
// iDatacenter
//
// Created by Jakob Borg on 5/14/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "GeneralDetailViewController.h"
#import "MasterViewControllerProtocol.h"
#import "RootViewController.h"

@implementation RootViewController

@synthesize generalDetailViewController;

- (void)dealloc
{
        [generalDetailViewController release];
        [super dealloc];
}

- (void)viewDidLoad
{
        [super viewDidLoad];
}

- (void)switchDetailViewController:(UIViewController<DetailViewControllerProtocol>*)controller
{
        generalDetailViewController.detailViewController = controller;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
        [super viewDidUnload];
}

@end
