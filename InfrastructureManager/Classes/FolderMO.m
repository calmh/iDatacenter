//
// FolderMO.m
// InfrastructureManager
//
// Created by Jakob Borg on 6/26/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "FolderMO.h"
#import "NSManagedObjectContext+Safety.h"
#import "NSManagedObjectMethods.h"

@implementation FolderMO

- (NSArray*)children
{
        NSMutableArray *children = [NSMutableArray array];
        if (![[self managedObjectContext] validateObject:self])
                return children;

        NSSet *ce = self.childEntity;
        for (FolderMO*object in ce) {
                if (![[object managedObjectContext] validateObject:object])
                        continue;

                if ([[[object entity] name] isEqualToString:@"computeresource"] ||
                    [[[object entity] name] isEqualToString:@"clustercomputeresource"])
                        [children addObjectsFromArray:[[object host] allObjects]];
                else
                        [children addObject:object];
        }

        NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:children, @"items", nil];
        return [NSArray arrayWithObject:item];
}

@end
