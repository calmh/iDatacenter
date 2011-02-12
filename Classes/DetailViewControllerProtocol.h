//
// DetailViewControllerProtocol.h
// iDatacenter
//
// Created by Jakob Borg on 5/14/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@protocol DetailViewControllerProtocol

@required
- (void)setDetailObject:(NSManagedObject*)object;

@optional
- (void)visualize;

@end
