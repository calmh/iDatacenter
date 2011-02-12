//
// HostDetailTableViewController.h
// iDatacenter
//
// Created by Jakob Borg on 7/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DetailTableViewController.h"
#import <Foundation/Foundation.h>

@interface HostDetailTableViewController : DetailTableViewController {
        BOOL powerStateChangeEnabled;
}

@property (nonatomic, assign) BOOL powerStateChangeEnabled;

@end
