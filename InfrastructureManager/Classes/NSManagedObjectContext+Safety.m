//
// NSManagedObjectContext+Safety.m
// InfrastructureManager
//
// Created by Jakob Borg on 7/22/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "NSManagedObjectContext+Safety.h"

@implementation NSManagedObjectContext (Safety)

- (NSManagedObject*)validateObjectId:(NSManagedObjectID*)objectID
{
        if (!objectID)
                return nil;

        NSManagedObject *objectForID = [self objectWithID:objectID];
        if (![objectForID isFault])
                return objectForID;

        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:[objectID entity]];

        NSPredicate *predicate =
                [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
                                                   rightExpression:[NSExpression expressionForConstantValue:objectForID]
                                                          modifier:NSDirectPredicateModifier
                                                              type:NSEqualToPredicateOperatorType
                                                           options:0];
        [request setPredicate:predicate];

        NSArray *results = [self executeFetchRequest:request error:nil];
        if ([results count] > 0)
                return [results objectAtIndex:0];

        return nil;
}

- (NSManagedObject*)objectWithURI:(NSURL*)uri
{
        NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:uri];

        if (!objectID)
                return nil;

        return [self validateObjectId:objectID];
}

- (BOOL)validateObject:(NSManagedObject*)object
{
        NSManagedObject *validatedObject = [self validateObjectId:[object objectID]];
        return validatedObject == object;
}

@end
