//
// NSManagedObjectContext+Safety.h
// InfrastructureManager
//
// Created by Jakob Borg on 7/22/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface NSManagedObjectContext (Safety)

- (NSManagedObject*)objectWithURI:(NSURL*)uri;
- (BOOL)validateObject:(NSManagedObject*)object;

@end
