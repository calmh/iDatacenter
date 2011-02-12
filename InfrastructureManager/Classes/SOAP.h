//
// SOAP.h
// iDatacenter
//
// Created by Jakob Borg on 8/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InfrastructureManager;
@class SOAP;

@protocol SOAPDelegate
@required
- (void)soapServer:(SOAP*)server didChangeObjects:(NSDictionary*)objects;
@end

@interface SOAP : NSObject {
        InfrastructureManager *delegate;
        NSURL *serverUrl;
        NSString *username;
        NSString *password;
        NSString *sessionManagerId;
        NSString *rootFolderId;
        NSString *propertyCollectorId;
        NSString *authManagerId;
        float performanceUpdateInterval;
        BOOL loggedIn;
}

@property (nonatomic, assign) NSObject<SOAPDelegate> *delegate;
@property (readonly) NSString *rootFolderId;
@property (nonatomic, assign) BOOL loggedIn;

- (id)initWithServerUrl:(NSURL*)url username:(NSString*)username password:(NSString*)password;
- (void)start;

@end
