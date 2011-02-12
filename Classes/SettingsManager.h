//
// SettingsManager.h
// iDatacenter
//
// Created by Jakob Borg on 2010-11-09.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SettingsManager : NSObject {
        NSUserDefaults *defaults;
        NSString *password;
}

@property (nonatomic, assign) NSString *server;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSString *password;
@property (nonatomic, assign) BOOL rememberPassword;
@property (readonly) int totalLaunches;
@property (readonly) int currentVersionLaunches;
@property (readonly) NSTimeInterval installedTimeInterval;
@property (nonatomic, assign) BOOL displayedBetaWarning;
@property (nonatomic, assign) BOOL debug;

+ instance;

@end
