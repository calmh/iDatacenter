//
// InfrastructureManager.m
// iDatacenter
//
// Created by Jakob Borg on 5/2/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "InfrastructureManager+CoreData.h"
#import "InfrastructureManager.h"
#import "SOAP.h"
#import "SettingsManager.h"

@interface InfrastructureManager ()
- (void)invokeMobMethod:(NSString*)method onObjectId:(NSString*)objectId ofType:(NSString*)type withParameters:(NSArray*)parameters;
- (NSArray*)licenseEditions;
@end

@implementation InfrastructureManager

@synthesize delegate;

- (void)dealloc
{
        [managedObjectContext release];
        [managedObjectModel release];
        [updateQueue release];
        [restClients release];
        [baseUrl release];
        [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context model:(NSManagedObjectModel*)model
{
        if ((self = [super init])) {
                managedObjectContext = [context retain];
                managedObjectModel = [model retain];
                updateQueue = [[NSMutableDictionary alloc] init];
                restClients = [[NSMutableArray alloc] init];
                failures = 0;
                debugger = [[LinksDebugger alloc] init];
                settings = [SettingsManager instance];
        }
        return self;
}

- (FolderMO*)rootFolderObject
{
        return (FolderMO*) [self fetchObjectWithId:soap.rootFolderId];
}

- (void)start
{
        if (!soap) {
                username = [settings.username retain];
                password = [settings.password retain];
                DLOG(@"host: '%@'", settings.server);
                NSString *urlString = [NSString stringWithFormat:@"https://%@/sdk/vimService", settings.server];
                DLOG(@"urlString: '%@'", urlString);
                baseUrl = [[NSURL URLWithString:urlString] retain];
                soap = [[SOAP alloc] initWithServerUrl:baseUrl username:username password:password];
        }
        soap.delegate = self;
        [soap start];
}

- (void)testConnectionWithServer:(NSString*)host username:(NSString*)aUsername password:(NSString*)aPassword delegate:(NSObject<InfrastructureManagerDelegate>*)aDelegate
{
        NSString *urlString = [NSString stringWithFormat:@"https://%@/sdk/vimService", host];
        NSURL *url = [[NSURL URLWithString:urlString] retain];
        SOAP *testSoap = [[SOAP alloc] initWithServerUrl:url username:aUsername password:aPassword];
        [testSoap fetchServiceContentAndCallBlock:^(NSError * error) {
                 if (error)
                         [aDelegate connectionFailedWithError:error];
                 else {
                         [testSoap loginAndCallBlock:^(id content) {
                                  // !!!: Move this into SOAP
                                  if ([content isKindOfClass:[NSError class]])
                                          [aDelegate connectionFailedWithError:content];
                                  else {
                                          NSDictionary *processed = [SOAP tagToValue:content];
                                          NSDictionary *tag = nil;
                                          if ((tag = [processed objectForKey:@"soapenv:Fault"])) {
                                                  NSString *faultString = [tag objectForKey:@"faultstring"];
                                                  [aDelegate connectionFailedWithError:[NSError errorWithDomain:@"custom" code:-1 userInfo:[NSDictionary dictionaryWithObject:faultString forKey:NSLocalizedDescriptionKey]]];
                                          } else if ((tag = [processed objectForKey:@"LoginResponse"])) {
                                                  NSLog (@"Connection test OK");
                                                  soap = testSoap;
                                                  soap.loggedIn = YES;
                                                  [aDelegate connectionTestSucceeded];
                                          }
                                  }
                          }];
                 }
         }];
}

- (void)rebootGuest:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"RebootGuest" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)shutdownGuest:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"ShutdownGuest" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)powerCycleVM:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"ResetVM_Task" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)powerOnVM:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"PowerOnVM_Task" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)powerOffVM:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"PowerOffVM_Task" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)suspendVM:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"SuspendVM_Task" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:nil];
}

- (void)relocateVM:(NSString*)vmObjectId toDatastoreId:(NSString*)dsId
{
        NSMutableDictionary *spec = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"spec", @"tag",
                                     [NSMutableDictionary dictionaryWithObjectsAndKeys:@"VirtualMachineRelocateSpec", @"xsi:type", nil], @"attributes",
                                     [NSMutableDictionary dictionaryWithObjectsAndKeys:@"datastore", @"tag",
                                      [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Datastore", @"type", @"ManagedObjectReference", @"xsi:type", nil], @"attributes",
                                      dsId, @"content",
                                      nil], @"content",
                                     nil];
        [self invokeMobMethod:@"RelocateVM_Task" onObjectId:vmObjectId ofType:@"VirtualMachine" withParameters:[NSArray arrayWithObject:spec]];
}

- (void)enterHostMaintenanceMode:(NSString*)vmObjectId
{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"timeout", @"tag", @"60", @"content", nil];
        [self invokeMobMethod:@"EnterMaintenanceMode_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:[NSArray arrayWithObject:params]];
}

- (void)exitHostMaintenanceMode:(NSString*)vmObjectId
{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"timeout", @"tag", @"60", @"content", nil];
        [self invokeMobMethod:@"ExitMaintenanceMode_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:[NSArray arrayWithObject:params]];
}

- (void)rebootHost:(NSString*)vmObjectId
{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"force", @"tag", @"false", @"content", nil];
        [self invokeMobMethod:@"RebootHost_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:[NSArray arrayWithObject:params]];
}

- (void)disconnectHost:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"DisconnectHost_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:nil];
}

- (void)reconnectHost:(NSString*)vmObjectId
{
        [self invokeMobMethod:@"ReconnectHost_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:nil];
}

- (void)shutdownHost:(NSString*)vmObjectId
{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"force", @"tag", @"false", @"content", nil];
        [self invokeMobMethod:@"ShutdownHost_Task" onObjectId:vmObjectId ofType:@"HostSystem" withParameters:[NSArray arrayWithObject:params]];
}

- (NSSet*)privilegesForEffectiveRoleIds:(NSArray*)roleIds
{
        NSMutableSet *privileges = [NSMutableSet set];
        for (id roleIdObj in roleIds) {
                int roleId = [roleIdObj intValue];
                NSManagedObject *role = [self fetchRoleWithId:roleId];
                NSArray *privs = role.privileges;
                if ([privs count] == 0)
                        continue;
                if ([privs count] == 1 && [[privs lastObject] isEqualToString:@""])
                        continue;
                [privileges addObjectsFromArray:privs];
        }
        return privileges;
}

- (NSManagedObject*)fetchObjectWithId:(NSString*)objectId
{
        NSDictionary *variables = [NSDictionary dictionaryWithObject:objectId forKey:@"ID"];
        return [self fetchSingleObjectWithTemplate:@"objectWithId" andVariables:variables];
}

- (NSManagedObject*)fetchRoleWithId:(int)roleId
{
        NSDictionary *variables = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:roleId] forKey:@"ROLEID"];
        return [self fetchSingleObjectWithTemplate:@"roleWithId" andVariables:variables];
}

- (BOOL)permissionForOperation:(NSString*)operation withDisabler:(NSString*)disabler onObject:(NSManagedObject*)object
{
        NSArray *licenseEditions = [self licenseEditions];
        if ([licenseEditions count] == 1 && [[licenseEditions lastObject] isEqualToString:@"esxBasic"])
                return NO;
        NSSet *privileges = [self privilegesForEffectiveRoleIds:object.effectiveRoles];
        return [privileges containsObject:operation] && ![object.disabledMethods containsObject:disabler];
}

/*
 * Private methods only below
 */

- (void)invokeMobMethod:(NSString*)method onObjectId:(NSString*)objectId ofType:(NSString*)type withParameters:(NSArray*)parameters
{
        NSDictionary *this = [NSDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", objectId, @"content",
                              [NSDictionary dictionaryWithObjectsAndKeys:@"ManagedObjectReference", @"xsi:type", type, @"type", nil], @"attributes",
                              nil];
        NSArray *params = [[NSArray arrayWithObject:this] arrayByAddingObjectsFromArray:parameters];
        [soap performSoapAction:method withParameter:params block:^(id response) {
                 NSLog (@"%@", [response description]);
         }];
}

- (void)methodResponse:(id)content
{ }

- (NSArray*)licenseEditions
{
        NSManagedObject *content = [self fetchObjectWithId:@"content"];
        return content.licenseManager.editions;
}

/*
 * SOAP delegate stuff
 */

- (void)soapServer:(SOAP*)server didChangeObjects:(NSMutableDictionary*)updatedObjects
{
        for (NSString*objectId in [updatedObjects allKeys])
                [self createOrUpdateObjectId:objectId fromObjectData:updatedObjects];
        [managedObjectContext save:nil];
}

@end
