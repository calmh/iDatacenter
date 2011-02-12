//
// InfrastructureManager+CoreData.m
// iDatacenter
//
// Created by Jakob Borg on 5/20/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "InfrastructureManager+CoreData.h"
#import "LinksDebugger.h"
#import "NSDate+Parsing.h"
#import "NSManagedObjectMethods.h"
#import "NSString+XMLEntities.h"

@implementation InfrastructureManager (CoreData)

- (void)updateRolesFromData:(NSDictionary*)content
{
        for (NSString*roleId in [content allKeys]) {
                NSArray *privileges = [content valueForKey:roleId];
                [self updateRole:[roleId intValue] withPrivileges:privileges];
        }
        [managedObjectContext save:nil];
}

- (void)updateRole:(int)roleId withPrivileges:(NSArray*)privileges
{
        NSManagedObject *roleObject = [self fetchRoleWithId:roleId];
        if (roleObject == nil) {
                NSString *roleIdStr = [NSString stringWithFormat:@"role.%d", roleId];
                roleObject = [self unsafeCreateObjectWithId:roleIdStr ofType:@"roleList"];
                roleObject.id = roleIdStr;
                roleObject.roleId = [NSNumber numberWithInt:roleId];
                roleObject.privileges = privileges;
        }
}

- (NSManagedObject*)createOrUpdateObjectId:(NSString*)objectId fromObjectData:(NSDictionary*)objectData
{
        NSDictionary *od = [objectData objectForKey:objectId];
        if (!od)
                return nil;

        NSString *objectType = [[od objectForKey:@"objectData.attributes.type"] lowercaseString];
        NSManagedObject *mo = [self createObjectWithId:objectId ofType:objectType];
        NSAssert(mo, @"Newly created object cannot be null.");
        [self updatePropertiesForObject:mo fromObjectData:objectData];
        mo.fetchedDate = [NSDate date];
        return mo;
}

- (void)updatePropertiesForObject:(NSManagedObject*)object fromObjectData:(NSDictionary*)objectData
{
        DLOG(@"Update properties for %@ %@", object.id, object.name);
        NSArray *properties = [[object entity] properties];
        for (NSPropertyDescription*property in properties) {
                if ([property isKindOfClass:[NSAttributeDescription class]])
                        [self updateAttributeProperty:property fromObjectData:objectData inObject:object];
                else if ([property isKindOfClass:[NSRelationshipDescription class]])
                        [self updateRelationsshipProperty:property fromObjectData:objectData inObject:object];
        }
}

- (void)updateRelationsshipProperty:(NSPropertyDescription*)property fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object
{
        NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription*) property;

        if (![relationshipDescription isToMany])
                [self updateToOneRelationshipProperty:relationshipDescription fromObjectData:objectData inObject:object];
        else
                [self updateToManyRelationshipProperty:relationshipDescription fromObjectData:objectData inObject:object];
}

- (void)updateAttributeProperty:(NSPropertyDescription*)property fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object
{
        NSDictionary *thisData = [objectData objectForKey:object.id];
        NSString *mobKey = [self mobKeyForProperty:property];
        id attributeValue = [thisData objectForKey:mobKey];
        if (attributeValue) {
                NSAttributeDescription *attributeDescription = (NSAttributeDescription*) property;
                NSAttributeType attrType = [attributeDescription attributeType];
                switch (attrType) {
                case NSStringAttributeType:
                        [object setValue:attributeValue forKey:[property name]];
                        break;

                case NSInteger16AttributeType:
                case NSInteger32AttributeType:
                case NSInteger64AttributeType:
                {
                        long long lvalue = [attributeValue longLongValue];
                        NSNumber *multiplier = [[property userInfo] valueForKey:@"mobMultiplier"];
                        if (multiplier != nil) {
                                long long imult = [multiplier longLongValue];
                                lvalue *= imult;
                        }
                        NSNumber *divisor = [[property userInfo] valueForKey:@"mobDivisor"];
                        if (divisor != nil) {
                                long long idiv = [divisor longLongValue];
                                lvalue /= idiv;
                        }
                        [object setValue:[NSNumber numberWithLongLong:lvalue] forKey:[property name]];
                        break;
                }

                case NSDateAttributeType:
                {
                        NSDate *date = [NSDate dateByParsingXmlFormat:attributeValue];
                        [object setValue:date forKey:[property name]];
                        break;
                }
                case NSTransformableAttributeType:
                        if (![attributeValue isKindOfClass:[NSArray class]])
                                attributeValue = [NSArray arrayWithObject:attributeValue];
                        [object setValue:attributeValue forKey:[property name]];
                        break;

                default:
                        NSAssert(NO, @"Unknown property type");
                }
        }
}

- (void)updateToOneRelationshipProperty:(NSRelationshipDescription*)relationshipDescription fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object
{
        NSString *mobKey = [self mobKeyForProperty:relationshipDescription];
        NSDictionary *thisData = [objectData objectForKey:object.id];
        id attributeValue = [thisData objectForKey:mobKey];
        if (attributeValue) {
                NSString *relationshipName = [relationshipDescription name];
                NSManagedObject *relation = [self fetchObjectWithId:attributeValue];
                if (!relation)
                        relation = [self createOrUpdateObjectId:attributeValue fromObjectData:objectData];
                if (relation)
                        [object setValue:relation forKey:relationshipName];
                else
                        NSLog(@"Failed to link entity '%@'", attributeValue);
        }
}

- (void)updateToManyRelationshipProperty:(NSRelationshipDescription*)relationshipDescription fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object
{
        NSString *mobKey = [self mobKeyForProperty:relationshipDescription];
        NSDictionary *thisData = [objectData objectForKey:object.id];
        id attributeValue = [thisData objectForKey:mobKey];
        if (attributeValue) {
                NSString *relationshipName = [relationshipDescription name];

                NSMutableSet *children = [object mutableSetValueForKey:relationshipName];
                NSMutableSet *actualChildren = [NSMutableSet set];
                if (![attributeValue isKindOfClass:[NSArray class]])
                        attributeValue = [NSArray arrayWithObject:attributeValue];
                for (id childId in attributeValue) {
                        NSManagedObject *child = [self fetchObjectWithId:childId];
                        if (!child)
                                child = [self createOrUpdateObjectId:childId fromObjectData:objectData];
                        if (child == nil) {
                                DLOG(@"Failed to multilink entity '%@'", childId);
                                return;
                        }

                        BOOL exists = NO;
                        for (NSManagedObject*existingChild in children) {
                                if ([existingChild isEqual:child]) {
                                        exists = YES;
                                        break;
                                }
                        }
                        if (!exists)
                                [children addObject:child];

                        [actualChildren addObject:child];
                }

                NSMutableSet *toRemove = [NSMutableSet set];
                for (NSManagedObject*existingChild in children) {
                        BOOL exists = NO;
                        for (NSManagedObject*candidate in actualChildren) {
                                if ([existingChild isEqual:candidate]) {
                                        exists = YES;
                                        break;
                                }
                        }
                        if (!exists)
                                [toRemove addObject:existingChild];
                }

                for (NSManagedObject*removeChild in toRemove)
                        [children removeObject:removeChild];
        }
}

- (NSManagedObject*)fetchSingleObjectWithTemplate:(NSString*)template andVariables:(NSDictionary*)variables
{
        NSFetchRequest *fetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:template substitutionVariables:variables];
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];

        if ([results count] == 1)
                return [results objectAtIndex:0];
        return nil;
}

- (NSArray*)runningTasks
{
        NSFetchRequest *fetchRequest = [managedObjectModel fetchRequestTemplateForName:@"runningTasks"];
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
        return results;
}

- (NSManagedObject*)createObjectWithId:(NSString*)objectId ofType:(NSString*)type
{
        NSManagedObject *existing = [self fetchObjectWithId:objectId];
        if (existing != nil)
                return existing;
        return [self unsafeCreateObjectWithId:objectId ofType:type];
}

- (NSManagedObject*)unsafeCreateObjectWithId:(NSString*)objectId ofType:(NSString*)type
{
        if (![self entityExists:type])
                return nil;
        NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:type inManagedObjectContext:managedObjectContext];
        [created setValue:objectId forKey:@"id"];
        return created;
}

- (BOOL)entityExists:(NSString*)entityName
{
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        return entity != nil;
}

- (BOOL)deleteObjectWithId:(NSString*)objectId
{
        NSManagedObject *existing = [self fetchObjectWithId:objectId];
        if (existing != nil) {
                [managedObjectContext deleteObject:existing];
                updatedObjects++;
                return YES;
        }
        return NO;
}

- (NSString*)mobKeyForProperty:(NSPropertyDescription*)property
{
        NSString *mobKey = [[property userInfo] valueForKey:@"mobKey"];
        if (mobKey != nil)
                return mobKey;
        else
                return [property name];
}

- (NSArray*)mobKeysForEntity:(NSString*)entityName
{
        NSMutableArray *mobKeys = [NSMutableArray array];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        NSArray *properties = [entity properties];
        for (NSPropertyDescription*property in properties) {
                NSString *mobKey = [[property userInfo] valueForKey:@"mobKey"];
                if (mobKey)
                        [mobKeys addObject:mobKey];
        }
        return mobKeys;
}

@end
