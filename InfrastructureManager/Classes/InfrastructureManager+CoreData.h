//
// InfrastructureManager+CoreData.h
// iDatacenter
//
// Created by Jakob Borg on 5/20/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "InfrastructureManager.h"
#import "TBXML.h"
#import <Foundation/Foundation.h>

@interface InfrastructureManager (CoreData)
- (void)updateRolesFromData:(NSDictionary*)content;
- (void)updateRole:(int)roleId withPrivileges:(NSArray*)privileges;
- (void)updatePropertiesForObject:(NSManagedObject*)object fromObjectData:(NSDictionary*)objectData;
- (void)updateRelationsshipProperty:(NSPropertyDescription*)property fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object;
- (void)updateAttributeProperty:(NSPropertyDescription*)property fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object;
- (void)updateToOneRelationshipProperty:(NSRelationshipDescription*)relationshipDescription fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object;
- (void)updateToManyRelationshipProperty:(NSRelationshipDescription*)relationshipDescription fromObjectData:(NSDictionary*)objectData inObject:(NSManagedObject*)object;
- (NSManagedObject*)fetchSingleObjectWithTemplate:(NSString*)template andVariables:(NSDictionary*)variables;
- (NSArray*)runningTasks;
- (NSArray*)fetchObjectsOlderThan:(NSInteger)seconds ofEntity:(NSString*)entityName;
- (NSManagedObject*)createObjectWithId:(NSString*)name ofType:(NSString*)type;
- (NSManagedObject*)unsafeCreateObjectWithId:(NSString*)objectId ofType:(NSString*)type;
- (BOOL)entityExists:(NSString*)entityName;
- (BOOL)deleteObjectWithId:(NSString*)name;
- (NSString*)mobKeyForProperty:(NSPropertyDescription*)property;
- (void)errorWhenParsingTag:(NSString*)tag forObjectId:(NSString*)objectId;
- (NSArray*)mobKeysForEntity:(NSString*)entityName;
@end
