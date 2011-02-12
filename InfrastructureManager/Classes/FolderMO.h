//
// FolderMO.h
// InfrastructureManager
//
// Created by Jakob Borg on 6/26/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class DatacenterMO;

@interface FolderMO : NSManagedObject { }

@end

@interface FolderMO (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSSet *childEntity;
@property (nonatomic, retain) DatacenterMO *hostsForDC;
@property (nonatomic, retain) FolderMO *parent;
@property (nonatomic, retain) NSManagedObject *rootFolderForContent;
@property (nonatomic, retain) DatacenterMO *vmsForDC;
- (void)addChildEntityObject:(FolderMO*)value;
- (void)removeChildEntityObject:(FolderMO*)value;
- (void)addChildEntity:(NSSet*)value;
- (void)removeChildEntity:(NSSet*)value;
@end
