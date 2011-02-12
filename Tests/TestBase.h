//
// TestBase.h
// iDatacenter
//
// Created by Jakob Borg on 5/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@interface TestBase : SenTestCase {
        NSManagedObjectModel *managedObjectModel;
        NSPersistentStoreCoordinator *persistentStoreCoordinator;
        NSManagedObjectContext *managedObjectContext;
}

- (NSString*)bundlePath;

@end
