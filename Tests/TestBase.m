//
// TestBase.m
// iDatacenter
//
// Created by Jakob Borg on 5/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "TestBase.h"

@implementation TestBase

- (void)setUp
{
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]]] retain];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
}

- (void)tearDown
{
        [managedObjectContext release];
        [managedObjectModel release];
        [persistentStoreCoordinator release];
}

- (NSString*)bundlePath
{
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSString *bundlePath = [myBundle bundlePath];
        return bundlePath;
}

@end
