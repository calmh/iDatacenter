//
// SOAP.m
// iDatacenter
//
// Created by Jakob Borg on 8/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "SOAP.h"
#import "TBXML.h"
#import "NSURLConnectionWithUserInfo.h"
#import "InfrastructureManager.h"
#import "InfrastructureManager+CoreData.h"

@interface SOAP ()
+ (NSString*)render:(NSDictionary*)tag;
+ (NSString*)render:(NSDictionary*)tag withIndent:(int)indent;
+ (NSString*)renderDictionary:(NSDictionary*)tag withIndent:(int)indent;
+ (NSString*)indentForLevel:(int)indent;
+ (NSString*)xmlHeader;
+ (NSMutableDictionary*)envelope;
+ (NSMutableDictionary*)body;
+ (NSMutableDictionary*)dictionaryFromElement:(TBXMLElement*)element;
+ (NSString*)renderRequestWithParameter:(NSDictionary*)parameter;
+ (NSDictionary*)flattenDictionary:(NSDictionary*)inputDictionary;
+ (void)foldDictionary:(NSDictionary*)object intoDictionary:(NSMutableDictionary*)resultDictionary behindKey:(id)key;
- (void)performSoapAction:(NSString*)action withParameter:(id)parameter block:(void (^)(id))block;
- (void)performSoapAction:(NSString*)action withParameter:(id)parameter target:(id)target selector:(SEL)selector;
- (void)fetchServiceContentAndCallBlock:(void (^)(NSError*))block;
- (void)fetchServiceContentTo:(void (^)(id))block;
- (void)login;
- (void)loginAndCallBlock:(void (^)(id))block;
- (void)loginFailedResponse:(id)content;
- (void)loginSucceededResponse:(id)content;
- (void)beginPullingData;
- (void)retrieveRoles;
- (void)retrieveRolesResponse:(id)content;
- (void)createFilter;
- (NSDictionary*)selectSetTagWithName:(NSString*)name type:(NSString*)type path:(NSString*)path children:(NSArray*)children;
- (void)createFilterResponse:(id)content;
- (void)checkForUpdatesFromVersion:(NSString*)version;
- (void)checkForUpdatesResponse:(id)content;
- (void)retrievePerformanceData;
- (void)retrievePerformanceDataResponse:(id)content;
@end

@implementation SOAP

@synthesize delegate;
@synthesize rootFolderId;
@synthesize loggedIn;

- (id)initWithServerUrl:(NSURL*)_serverUrl username:(NSString*)_username password:(NSString*)_password
{
        if ((self = [super init])) {
                serverUrl = [_serverUrl retain];
                username = [_username retain];
                password = [_password retain];
                performanceUpdateInterval = 60;
        }
        return self;
}

- (void)start
{
        DTRACE;
        if (!loggedIn)
                [self login];
        else
                [self beginPullingData];
}

/*
 * Private methods
 */

+ (NSString*)xmlHeader
{
        return @"<?xml version=\"1.0\" encoding=\"utf-8\"?>";
}

+ (NSMutableDictionary*)envelope
{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@"soap:Envelope" forKey:@"tag"];
        NSMutableDictionary *attr = [NSMutableDictionary dictionary];
        [attr setObject:@"http://www.w3.org/2001/XMLSchema-instance" forKey:@"xmlns:xsi"];
        [attr setObject:@"http://www.w3.org/2001/XMLSchema" forKey:@"xmlns:xsd"];
        [attr setObject:@"http://schemas.xmlsoap.org/soap/envelope/" forKey:@"xmlns:soap"];
        [attr setObject:@"urn:vim2" forKey:@"xmlns"];
        [dict setObject:attr forKey:@"attributes"];
        return dict;
}

+ (NSMutableDictionary*)body
{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@"soap:Body" forKey:@"tag"];
        return dict;
}

+ (NSString*)render:(NSDictionary*)tag
{
        NSMutableString *result = [NSMutableString stringWithFormat:@"%@\n", [SOAP xmlHeader]];
        [result appendString:[SOAP render:tag withIndent:0]];
        return result;
}

+ (NSString*)render:(NSDictionary*)tag withIndent:(int)indent
{
        NSMutableString *result = [NSMutableString string];

        if ([tag isKindOfClass:[NSDictionary class]])
                [result appendString:[SOAP renderDictionary:tag withIndent:indent]];
        else if ([tag isKindOfClass:[NSArray class]]) {
                for (NSDictionary*child in tag)
                        [result appendString:[SOAP renderDictionary:child withIndent:indent]];
        }

        return result;
}

+ (NSString*)renderDictionary:(NSDictionary*)tag withIndent:(int)indent
{
        NSString *spacer = [SOAP indentForLevel:indent];
        NSMutableString *result = [NSMutableString string];

        [result appendFormat:@"%@<%@", spacer, [tag objectForKey:@"tag"]];
        NSDictionary *attributes = [tag objectForKey:@"attributes"];
        if (attributes) {
                for (NSString*attribute in [[attributes allKeys] sortedArrayUsingSelector : @selector(compare:)]) {
                        NSString *attributeValue = [attributes objectForKey:attribute];
                        [result appendFormat:@" %@=\"%@\"", attribute, attributeValue];
                }
        }

        id content = [tag objectForKey:@"content"];
        if (content) {
                if ([content isKindOfClass:[NSString class]])
                        [result appendFormat:@">%@</%@>\n", content, [tag objectForKey:@"tag"]];
                else {
                        [result appendString:@">\n"];
                        [result appendString:[SOAP render:content withIndent:indent + 1]];
                        [result appendFormat:@"%@</%@>\n", spacer, [tag objectForKey:@"tag"]];
                }
        } else
                [result appendString:@"/>\n"];


        return result;
}

+ (NSString*)indentForLevel:(int)indent
{
        NSMutableString *result = [NSMutableString string];
        for (int i = 0; i < indent; i++)
                [result appendString:@"  "];
        return result;
}

+ (NSMutableDictionary*)dictionaryFromElement:(TBXMLElement*)element
{
        NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
        [elementDictionary setObject:[TBXML elementName:element] forKey:@"tag"];

        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        TBXMLAttribute *attribute = element->firstAttribute;
        while (attribute) {
                [attributes setObject:[TBXML attributeValue:attribute] forKey:[TBXML attributeName:attribute]];
                attribute = attribute->next;
        }
        if ([attributes count] > 0)
                [elementDictionary setObject:attributes forKey:@"attributes"];

        int numChildElements = 0;
        NSMutableArray *childElementsArray = [NSMutableArray array];
        TBXMLElement *childElement = element->firstChild;
        while (childElement) {
                numChildElements++;
                NSMutableDictionary *childElementDictionary = [SOAP dictionaryFromElement:childElement];
                [childElementsArray addObject:childElementDictionary];
                childElement = childElement->nextSibling;
        }

        if (numChildElements == 0)
                [elementDictionary setObject:[TBXML textForElement:element] forKey:@"content"];
        else if (numChildElements == 1)
                [elementDictionary setObject:[childElementsArray lastObject] forKey:@"content"];
        else if (numChildElements > 1)
                [elementDictionary setObject:childElementsArray forKey:@"content"];
        return elementDictionary;
}

+ (NSString*)renderRequestWithParameter:(NSDictionary*)parameter
{
        NSMutableDictionary *body = [SOAP body];
        [body setObject:parameter forKey:@"content"];
        NSMutableDictionary *envelope = [SOAP envelope];
        [envelope setObject:body forKey:@"content"];
        return [SOAP render:envelope];
}

+ (id)tagToValue:(id)tag
{
        if ([tag isKindOfClass:[NSString class]])
                return tag;
        else if ([tag isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray array];
                int total = 0, numDicts = 0, dictObjects = 0;
                NSMutableDictionary *totalDict = [NSMutableDictionary dictionary];
                for (id object in tag) {
                        id value = [SOAP tagToValue:object];
                        if ([value isKindOfClass:[NSDictionary class]]) {
                                numDicts++;
                                [totalDict addEntriesFromDictionary:value];
                                dictObjects += [value count];
                        }
                        [array addObject:value];
                        total++;
                }

                if (total == numDicts && dictObjects == [totalDict count])
                        return totalDict;
                else
                        return array;
        } else if ([tag isKindOfClass:[NSDictionary class]]) {
                NSString *name = [tag objectForKey:@"tag"];
                NSString *value = [SOAP tagToValue:[tag objectForKey:@"content"]];
                return [NSDictionary dictionaryWithObject:value forKey:name];
        }
        NSAssert(NO, @"Unpossible!");
        return nil;
}

+ (NSDictionary*)flattenDictionary:(NSDictionary*)inputDictionary
{
        NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
        NSEnumerator *enumerator = [inputDictionary keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
                id object = [inputDictionary objectForKey:key];
                if ([object isKindOfClass:[NSString class]])
                        [resultDictionary setObject:object forKey:key];
                else if ([object isKindOfClass:[NSDictionary class]])
                        [self foldDictionary:object intoDictionary:resultDictionary behindKey:key];
                else if ([object isKindOfClass:[NSArray class]]) {
                        for (NSDictionary*arrayMember in object) {
                                NSDictionary *flattenedDict = [SOAP flattenDictionary:arrayMember];
                                for (NSString*subKey in [flattenedDict allKeys]) {
                                        NSString *fullKey = [NSString stringWithFormat:@"%@.%@", key, subKey];
                                        id newValue = [flattenedDict objectForKey:subKey];
                                        id currentValue = [resultDictionary objectForKey:fullKey];
                                        if (!currentValue)
                                                [resultDictionary setObject:newValue forKey:fullKey];
                                        else if ([currentValue isKindOfClass:[NSMutableArray class]])
                                                [currentValue addObject:newValue];
                                        else {
                                                NSMutableArray *newArray = [NSMutableArray arrayWithObjects:currentValue, newValue, nil];
                                                [resultDictionary setObject:newArray forKey:fullKey];
                                        }
                                }
                        }
                }
        }
        return resultDictionary;
}

+ (void)foldDictionary:(NSDictionary*)object intoDictionary:(NSMutableDictionary*)resultDictionary behindKey:(id)key
{
        NSDictionary *halfFlatDictionary = [SOAP flattenDictionary:object];
        NSEnumerator *halfFlatKeyEnum = [halfFlatDictionary keyEnumerator];
        id halfFlatKey;
        while ((halfFlatKey = [halfFlatKeyEnum nextObject])) {
                NSString *flattedKey = [NSString stringWithFormat:@"%@.%@", key, halfFlatKey];
                [resultDictionary setObject:[halfFlatDictionary objectForKey:halfFlatKey] forKey:flattedKey];
        }
}

- (void)performSoapAction:(NSString*)action withParameter:(id)parameter block:(void (^)(id))block
{
        NSLog(@"Action: %@", action);
        DLOG(@"%@", serverUrl);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        [request setHTTPMethod:@"POST"];
        [request setHTTPShouldHandleCookies:YES];

        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers setValue:@"text/html; charset=utf-8" forKey:@"Content-Type"];
        [headers setValue:@"close" forKey:@"Connection"];
        [headers setValue:@"urn:vim25/4.0" forKey:@"SOAPAction"];
        [request setAllHTTPHeaderFields:headers];

        NSMutableDictionary *enclosedParam = [NSMutableDictionary dictionaryWithObjectsAndKeys:action, @"tag", parameter, @"content", nil];
        NSString *body = [SOAP renderRequestWithParameter:enclosedParam];
        DLOG(@"%@", body);
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

        NSURLConnectionWithUserInfo *conn = [[NSURLConnectionWithUserInfo alloc] initWithRequest:request delegate:self startImmediately:YES];
        conn.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:Block_copy(block), @"block", [NSMutableData data], @"data", [NSDate date], @"startTime", nil];
        if (!conn) {
                DTRACE;
                NSError *error = [[NSError alloc] initWithDomain:@"custom" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"Unable to initalize connection." forKey:NSLocalizedDescriptionKey]];
                [error autorelease];
                block(error);
        }
}

- (void)performSoapAction:(NSString*)action withParameter:(id)parameter target:(id)target selector:(SEL)selector
{
        [self performSoapAction:action withParameter:parameter block:^(id content) {
                 if (target && [target respondsToSelector:selector])
                         [target performSelector:selector withObject:content];
         }];
}

- (void)fetchServiceContentAndCallBlock:(void (^)(NSError*))block
{
        [self fetchServiceContentTo:^(id content) {
                 if ([content isKindOfClass:[NSError class]]) {
                         NSLog (@"%@", [(NSError*) content localizedDescription]);
                         block ((NSError*) content);
                 } else {
                         id innerContent = [(NSDictionary*) content objectForKey:@"content"];
                         NSAssert ([innerContent isKindOfClass:[NSDictionary class]], @"Inner content must be dictionary");
                         NSAssert ([[innerContent objectForKey:@"tag"] isEqualToString:@"returnval"], @"Inner content must be returnval tag.");
                         NSArray *tags = [innerContent objectForKey:@"content"];
                         for (NSDictionary * tag in tags) {
                                 NSString *tagName = [tag objectForKey:@"tag"];
                                 if ([tagName isEqualToString:@"sessionManager"])
                                         sessionManagerId = [[tag objectForKey:@"content"] copy];
                                 if ([tagName isEqualToString:@"rootFolder"])
                                         rootFolderId = [[tag objectForKey:@"content"] copy];
                                 if ([tagName isEqualToString:@"propertyCollector"])
                                         propertyCollectorId = [[tag objectForKey:@"content"] copy];
                                 if ([tagName isEqualToString:@"authorizationManager"])
                                         authManagerId = [[tag objectForKey:@"content"] copy];
                         }

                         block (nil);
                 }
         }];
}

- (void)fetchServiceContentTo:(void (^)(id))block
{
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"ServiceInstance", @"type", nil];
        NSMutableDictionary *p1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", @"ServiceInstance", @"type", @"ServiceInstance", @"content", attrs, @"attributes", nil];
        [self performSoapAction:@"RetrieveServiceContent" withParameter:p1 block:block];
}

- (void)login
{
        void (^loginHandler)(id content) = ^(id content) {
                if ([content isKindOfClass:[NSError class]])
                        NSLog (@"%@", [(NSError*) content localizedDescription]);
                else if ([content isKindOfClass:[NSDictionary class]]) {
                        NSString *tag = [content objectForKey:@"tag"];
                        if ([tag isEqualToString:@"soapenv:Fault"]) {
                                NSLog (@"Login failed");
                                [self loginFailedResponse:content];
                        } else if ([tag isEqualToString:@"LoginResponse"]) {
                                NSLog (@"Login succeeded");
                                [self loginSucceededResponse:content];
                        }
                }
        };

        if (sessionManagerId) {
                NSLog (@"Going to log in");
                [self loginAndCallBlock:loginHandler];
        } else {
                [self fetchServiceContentAndCallBlock:^(NSError * error) {
                         if (!error)
                                 [self loginAndCallBlock:loginHandler];
                         else
                                 // !!!: Handle this error
                                 NSLog (@"Failed to fetch service content");
                 }];
        }
}

- (void)loginAndCallBlock:(void (^)(id))block
{
        DTRACE;
        NSMutableArray *children = [NSMutableArray array];
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"SessionManager", @"type", nil];
        [children addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", sessionManagerId, @"content", attrs, @"attributes", nil]];
        [children addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"userName", @"tag", username, @"content", nil]];
        [children addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"password", @"tag", password, @"content", nil]];
        [self performSoapAction:@"Login" withParameter:children block:block];
}

- (void)loginFailedResponse:(id)content
{
        NSString *faultString = nil;
        id innerContent = [content objectForKey:@"content"];
        NSAssert([innerContent isKindOfClass:[NSArray class]], @"Inner content must be NSArray");
        for (NSDictionary*innerTag in innerContent) {
                if ([[innerTag objectForKey:@"tag"] isEqualToString:@"faultstring"]) {
                        faultString = [innerTag objectForKey:@"content"];
                        break;
                }
        }
        loggedIn = NO;
        NSLog(@"Fault: %@", faultString);
}

- (void)loginSucceededResponse:(id)content
{
        loggedIn = YES;
        [self beginPullingData];
}

- (void)beginPullingData
{
        [self createFilter];
        [self retrieveRoles];
}

- (void)retrieveRoles
{
        NSMutableArray *selectSets = [NSMutableArray array];
        NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:@"obj", @"tag", authManagerId, @"content", [NSDictionary dictionaryWithObject:@"AuthorizationManager" forKey:@"type"], @"attributes", nil];
        NSDictionary *skip = [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil];

        NSDictionary *objectSet = [NSDictionary dictionaryWithObjectsAndKeys:@"objectSet", @"tag",
                                   [[NSArray arrayWithObjects:obj, skip, nil] arrayByAddingObjectsFromArray:selectSets], @"content", nil];
        NSArray *propSets = [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"AuthorizationManager", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"pathSet", @"tag", @"roleList", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil],
                               nil], @"content", nil],
                             nil];
        NSDictionary *spec = [NSDictionary dictionaryWithObjectsAndKeys:@"specSet", @"tag", [propSets arrayByAddingObject:objectSet], @"content", nil];

        NSDictionary *this = [NSDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", propertyCollectorId, @"content", [NSDictionary dictionaryWithObjectsAndKeys:@"PropertyCollector", @"type", nil], @"attributes", nil];
        NSArray *params = [NSArray arrayWithObjects:this, spec, nil];
        [self performSoapAction:@"RetrieveProperties" withParameter:params target:self selector:@selector(retrieveRolesResponse:)];
}

- (void)retrieveRolesResponse:(id)content
{
        if ([content isKindOfClass:[NSError class]])
                NSLog(@"%@", [(NSError*) content localizedDescription]);
        else if ([content isKindOfClass:[NSDictionary class]]) {
                NSDictionary *contentDict = [SOAP tagToValue:content];
                contentDict = [[[[contentDict valueForKey:@"RetrievePropertiesResponse"] valueForKey:@"returnval"] valueForKey:@"propSet"] valueForKey:@"val"];
                NSAssert(contentDict, @"Missing tag in XML somewhere.");
                NSMutableDictionary *roles = [NSMutableDictionary dictionary];
                for (NSDictionary*authRole in contentDict) {
                        NSDictionary *flatDict = [SOAP flattenDictionary:authRole];
                        NSArray *privileges = [flatDict valueForKey:@"AuthorizationRole.privilege"];
                        NSString *roleId = [flatDict objectForKey:@"AuthorizationRole.roleId"];
                        if (!privileges)
                                privileges = [NSArray array];
                        [roles setObject:privileges forKey:roleId];
                }
                [[self delegate] updateRolesFromData:roles];
        }
}

- (NSArray*)pathSetForEntity:(NSString*)entityName
{
        NSMutableSet *pathSet = [NSMutableSet set];
        NSArray *properties = [self.delegate mobKeysForEntity:entityName];
        for (NSString*path in properties) {
                NSString *firstPart = [[path componentsSeparatedByString:@"."] objectAtIndex:0];
                [pathSet addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"pathSet", @"tag", firstPart, @"content", nil]];
        }
        return [pathSet allObjects];
}

- (void)createFilter
{
        NSMutableArray *selectSets = [NSMutableArray array];
        [selectSets addObject:[self selectSetTagWithName:@"visitFolders" type:@"Folder" path:@"childEntity" children:[NSArray arrayWithObjects:@"visitFolders", @"visitHostsFolder", @"visitVMsFolder", @"visitHostSystems", @"visitDatastores", @"visitRecentTasks", nil]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitHostsFolder" type:@"Datacenter" path:@"hostFolder" children:[NSArray arrayWithObject:@"visitFolders"]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitVMsFolder" type:@"Datacenter" path:@"vmFolder" children:[NSArray arrayWithObject:@"visitFolders"]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitHostSystems" type:@"ComputeResource" path:@"host" children:[NSArray arrayWithObject:@"visitNetworks"]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitDatastores" type:@"Datacenter" path:@"datastore" children:nil]];
        [selectSets addObject:[self selectSetTagWithName:@"visitRecentTasks" type:@"ManagedEntity" path:@"recentTask" children:nil]];
        [selectSets addObject:[self selectSetTagWithName:@"visitNetworks" type:@"HostSystem" path:@"network" children:nil]];

        NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:@"obj", @"tag", rootFolderId, @"content", [NSDictionary dictionaryWithObject:@"Folder" forKey:@"type"], @"attributes", nil];
        NSDictionary *skip = [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil];

        NSDictionary *objectSet = [NSDictionary dictionaryWithObjectsAndKeys:@"objectSet", @"tag",
                                   [[NSArray arrayWithObjects:obj, skip, nil] arrayByAddingObjectsFromArray:selectSets], @"content", nil];

        NSArray *vmPathSet = [self pathSetForEntity:@"virtualmachine"];
        NSArray *hsPathSet = [self pathSetForEntity:@"hostsystem"];
        NSArray *dcPathSet = [self pathSetForEntity:@"datacenter"];
        NSArray *foPathSet = [self pathSetForEntity:@"folder"];
        NSArray *crPathSet = [self pathSetForEntity:@"computeresource"];
        NSArray *dsPathSet = [self pathSetForEntity:@"datastore"];
        NSArray *rtPathSet = [self pathSetForEntity:@"task"];
        NSArray *nePathSet = [self pathSetForEntity:@"network"];
        NSArray *propSets = [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"Folder", @"content", nil]] arrayByAddingObjectsFromArray:foPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"Datacenter", @"content", nil]] arrayByAddingObjectsFromArray:dcPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"HostSystem", @"content", nil]] arrayByAddingObjectsFromArray:hsPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"ComputeResource", @"content", nil]] arrayByAddingObjectsFromArray:crPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"VirtualMachine", @"content", nil]] arrayByAddingObjectsFromArray:vmPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"Datastore", @"content", nil]] arrayByAddingObjectsFromArray:dsPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"Task", @"content", nil]] arrayByAddingObjectsFromArray:rtPathSet],
                              @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"Network", @"content", nil]] arrayByAddingObjectsFromArray:nePathSet],
                              @"content", nil],
                             nil];
        NSDictionary *spec = [NSDictionary dictionaryWithObjectsAndKeys:@"spec", @"tag", [propSets arrayByAddingObject:objectSet], @"content", nil];

        NSDictionary *this = [NSDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", propertyCollectorId, @"content", [NSDictionary dictionaryWithObjectsAndKeys:@"PropertyCollector", @"type", nil], @"attributes", nil];
        NSDictionary *partials = [NSDictionary dictionaryWithObjectsAndKeys:@"partialUpdates", @"tag", @"false", @"content", nil];
        NSArray *params = [NSArray arrayWithObjects:this, spec, partials, nil];
        [self performSoapAction:@"CreateFilter" withParameter:params target:self selector:@selector(createFilterResponse:)];
}

- (NSDictionary*)selectSetTagWithName:(NSString*)name type:(NSString*)type path:(NSString*)path children:(NSArray*)children
{
        NSMutableArray *childTags = [NSMutableArray array];
        for (NSString*child in children)
                [childTags addObject:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"selectSet", @"tag",
                  [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"tag", child, @"content", nil], @"content",
                  nil]];

        NSDictionary *selectTag = [NSDictionary dictionaryWithObjectsAndKeys:@"selectSet", @"tag",
                                   [[NSArray arrayWithObjects:
                                     [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"tag", name, @"content", nil],
                                     [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", type, @"content", nil],
                                     [NSDictionary dictionaryWithObjectsAndKeys:@"path", @"tag", path, @"content", nil],
                                     [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil], nil] arrayByAddingObjectsFromArray:childTags], @"content",
                                   [NSDictionary dictionaryWithObjectsAndKeys:@"TraversalSpec", @"xsi:type", nil], @"attributes",
                                   nil];
        return selectTag;
}

- (void)createFilterResponse:(id)content
{
        if ([content isKindOfClass:[NSDictionary class]]) {
                NSDictionary *innerContent = [content objectForKey:@"content"];
                NSAssert([[innerContent objectForKey:@"tag"] isEqualToString:@"returnval"], @"Inner content musta be returnval tag.");
                [self checkForUpdatesFromVersion:@""];
        }
}

- (void)checkForUpdatesFromVersion:(NSString*)version
{
        NSDictionary *this = [NSDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", propertyCollectorId, @"content", [NSDictionary dictionaryWithObjectsAndKeys:@"PropertyCollector", @"type", nil], @"attributes", nil];
        NSDictionary *versionTag = [NSDictionary dictionaryWithObjectsAndKeys:@"version", @"tag", version, @"content", nil];
        NSArray *params = [NSArray arrayWithObjects:this, versionTag, nil];
        [self performSoapAction:@"WaitForUpdates" withParameter:params target:self selector:@selector(checkForUpdatesResponse:)];
}

- (void)checkForUpdatesResponse:(id)content
{
        static BOOL first = YES;

        NSMutableDictionary *updateContent = [NSMutableDictionary dictionary];
        id innerContent = [content objectForKey:@"content"];
        NSAssert([innerContent isKindOfClass:[NSDictionary class]], @"Innercontent must be dictionary class.");
        NSAssert([[innerContent objectForKey:@"tag"] isEqualToString:@"returnval"], @"Innercontent must be returnval tag.");
        innerContent = [innerContent objectForKey:@"content"];
        NSAssert([innerContent isKindOfClass:[NSArray class]], @"Innercontent must be array class.");
        NSString *version = nil;
        for (NSDictionary*tag in innerContent) {
                NSString *tagName = [tag objectForKey:@"tag"];
                if ([tagName isEqualToString:@"version"]) {
                        version = [tag objectForKey:@"content"];
                        continue;
                }
                if ([tagName isEqualToString:@"filterSet"]) {
                        id objects = [tag objectForKey:@"content"];
                        NSAssert([objects isKindOfClass:[NSArray class]], @"ObjectSet must be array class.");
                        for (id object in objects) {
                                NSAssert([object isKindOfClass:[NSDictionary class]], @"Object must be dictionary class.");
                                if ([[object objectForKey:@"tag"] isEqualToString:@"objectSet"]) {
                                        id objectSet = [object objectForKey:@"content"];
                                        NSAssert([objectSet isKindOfClass:[NSArray class]], @"ObjectSet must be array class.");
                                        NSString *objectId = nil;
                                        NSString *name = nil;
                                        NSMutableDictionary *changeSetDictionary = [NSMutableDictionary dictionary];

                                        for (id innerTag in objectSet) {
                                                if ([[innerTag objectForKey:@"tag"] isEqualToString:@"obj"]) {
                                                        objectId = [innerTag objectForKey:@"content"];
                                                        [changeSetDictionary setObject:innerTag forKey:@"objectData"];
                                                        continue;
                                                }

                                                if ([[innerTag objectForKey:@"tag"] isEqualToString:@"changeSet"]) {
                                                        for (id change in [innerTag objectForKey : @"content"]) {
                                                                NSString *tagName = [change objectForKey:@"tag"];
                                                                id content = [change objectForKey:@"content"];

                                                                if ([tagName isEqualToString:@"name"])
                                                                        name = content;
                                                                else if ([tagName isEqualToString:@"op"]) {
                                                                        if (![content isEqualToString:@"assign"])
                                                                                NSAssert(NO, @"How to handle?");
                                                                } else if ([tagName isEqualToString:@"val"])
                                                                        [changeSetDictionary setObject:[SOAP tagToValue:content] forKey:name];
                                                        }
                                                }
                                        }

                                        NSDictionary *flatDict = [SOAP flattenDictionary:changeSetDictionary];
                                        [updateContent setObject:flatDict forKey:objectId];
                                }
                        }
                        continue;
                }
        }
        NSAssert(version, @"Version cannot be nil");

        if (delegate && [delegate respondsToSelector:@selector(soapServer:didChangeObjects:)])
                [delegate soapServer:self didChangeObjects:updateContent];
        [self performSelector:@selector(checkForUpdatesFromVersion:) withObject:version afterDelay:1.0];
        if (first) {
                first = NO;
                [self performSelector:@selector(retrievePerformanceData) withObject:nil afterDelay:performanceUpdateInterval];
#ifdef DEBUG
                NSString *filename = [[[UIApplication sharedApplication].delegate applicationDocumentsDirectory] stringByAppendingPathComponent:@"initial.plist"];
                [content writeToFile:filename atomically:NO];
#endif
        }
}

- (void)retrievePerformanceData
{
        NSMutableArray *selectSets = [NSMutableArray array];
        [selectSets addObject:[self selectSetTagWithName:@"visitFolders" type:@"Folder" path:@"childEntity" children:[NSArray arrayWithObjects:@"visitFolders", @"visitHostsFolder", @"visitVMsFolder", @"visitHostSystems", @"visitDatastores", nil]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitHostsFolder" type:@"Datacenter" path:@"hostFolder" children:[NSArray arrayWithObject:@"visitFolders"]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitVMsFolder" type:@"Datacenter" path:@"vmFolder" children:[NSArray arrayWithObject:@"visitFolders"]]];
        [selectSets addObject:[self selectSetTagWithName:@"visitHostSystems" type:@"ComputeResource" path:@"host" children:nil]];
        [selectSets addObject:[self selectSetTagWithName:@"visitDatastores" type:@"Datacenter" path:@"datastore" children:nil]];

        NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:@"obj", @"tag", rootFolderId, @"content", [NSDictionary dictionaryWithObject:@"Folder" forKey:@"type"], @"attributes", nil];
        NSDictionary *skip = [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil];

        NSDictionary *objectSet = [NSDictionary dictionaryWithObjectsAndKeys:@"objectSet", @"tag",
                                   [[NSArray arrayWithObjects:obj, skip, nil] arrayByAddingObjectsFromArray:selectSets], @"content", nil];
        NSArray *propSets = [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"VirtualMachine", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"pathSet", @"tag", @"summary.quickStats", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil],
                               nil], @"content", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"propSet", @"tag",
                              [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"tag", @"HostSystem", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"pathSet", @"tag", @"summary.quickStats", @"content", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"skip", @"tag", @"false", @"content", nil],
                               nil], @"content", nil],
                             nil];
        NSDictionary *spec = [NSDictionary dictionaryWithObjectsAndKeys:@"specSet", @"tag", [propSets arrayByAddingObject:objectSet], @"content", nil];

        NSDictionary *this = [NSDictionary dictionaryWithObjectsAndKeys:@"_this", @"tag", propertyCollectorId, @"content", [NSDictionary dictionaryWithObjectsAndKeys:@"PropertyCollector", @"type", nil], @"attributes", nil];
        NSArray *params = [NSArray arrayWithObjects:this, spec, nil];
        [self performSoapAction:@"RetrieveProperties" withParameter:params target:self selector:@selector(retrievePerformanceDataResponse:)];
}

- (void)retrievePerformanceDataResponse:(id)content
{
        NSMutableDictionary *updateContent = [NSMutableDictionary dictionary];
        id innerContent = [content objectForKey:@"content"];
        NSAssert([innerContent isKindOfClass:[NSArray class]], @"Innercontent must be array class.");
        for (NSDictionary*returnvalTag in innerContent) {
                NSAssert([returnvalTag isKindOfClass:[NSDictionary class]], @"returnval isn't a dictionary");
                NSAssert([[returnvalTag objectForKey:@"tag"] isEqualToString:@"returnval"], @"Is returnval tag");
                NSString *objectId = nil;
                NSMutableDictionary *changeSetDictionary = [NSMutableDictionary dictionary];
                for (NSDictionary*innerTag in [returnvalTag objectForKey : @"content"]) {
                        if ([[innerTag objectForKey:@"tag"] isEqualToString:@"obj"]) {
                                objectId = [innerTag objectForKey:@"content"];
                                [changeSetDictionary setObject:innerTag forKey:@"objectData"];
                                continue;
                        }
                        NSString *name = nil;
                        if ([[innerTag objectForKey:@"tag"] isEqualToString:@"propSet"]) {
                                for (id prop in [innerTag objectForKey : @"content"]) {
                                        id propContent = [prop objectForKey:@"content"];
                                        id propName = [prop objectForKey:@"tag"];
                                        if ([propName isEqualToString:@"name"])
                                                name = propContent;
                                        else if ([propName isEqualToString:@"val"])
                                                [changeSetDictionary setObject:[SOAP tagToValue:propContent] forKey:name];
                                }
                        }
                }
                NSDictionary *flatDict = [SOAP flattenDictionary:changeSetDictionary];
                [updateContent setObject:flatDict forKey:objectId];
        }

        if (delegate && [delegate respondsToSelector:@selector(soapServer:didChangeObjects:)])
                [delegate soapServer:self didChangeObjects:updateContent];
        [self performSelector:@selector(retrievePerformanceData) withObject:nil afterDelay:performanceUpdateInterval];
}

/*
 * NSURLConnectionDelegate stuff
 */

- (BOOL)connection:(NSURLConnectionWithUserInfo*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace
{
        DTRACE;
        return [protectionSpace authenticationMethod] == NSURLAuthenticationMethodServerTrust;
}

- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
        DTRACE;
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnectionWithUserInfo*)connection didReceiveData:(NSData*)data
{
        DTRACE;
        if (![connection.userInfo valueForKey:@"recieveTime"])
                [connection.userInfo setValue:[NSDate date] forKey:@"recieveTime"];
        [[connection.userInfo objectForKey:@"data"] appendData:data];
}

- (void)connection:(NSURLConnectionWithUserInfo*)connection didFailWithError:(NSError*)error
{
        DTRACE;
        id target = [connection.userInfo objectForKey:@"target"];
        SEL selector = [[connection.userInfo objectForKey:@"selector"] pointerValue];
        [connection release];

        void (^block)(id) = [connection.userInfo objectForKey:@"block"];
        if (block)
                block(error);
}

- (void)connectionDidFinishLoading:(NSURLConnectionWithUserInfo*)connection
{
        DTRACE;
        NSDate *finishedTime = [NSDate date];
        NSTimeInterval holdInterval = [[connection.userInfo objectForKey:@"recieveTime"] timeIntervalSinceDate:[connection.userInfo objectForKey:@"startTime"]];
        NSTimeInterval recieveInterval = [finishedTime timeIntervalSinceDate:[connection.userInfo objectForKey:@"recieveTime"]];

        void (^block)(id) = [connection.userInfo objectForKey:@"block"];
        if (block) {
                NSData *data = [connection.userInfo objectForKey:@"data"];
                TBXML *xml = [TBXML tbxmlWithXMLData:data];

                TBXMLElement *rootElement = [xml rootXMLElement];
                rootElement = [TBXML childElementNamed:@"soapenv:Body" parentElement:rootElement];
                rootElement = rootElement->firstChild;

                NSMutableDictionary *elementDictionary = [SOAP dictionaryFromElement:rootElement];
                NSTimeInterval parseInterval = [[NSDate date] timeIntervalSinceDate:finishedTime];
                NSLog(@"Request %d bytes, %fs hold, %fs recieve, %fs parse", [data length], holdInterval, recieveInterval, parseInterval);

                block(elementDictionary);
                Block_release(block);
        }

        [connection release];
}

@end
