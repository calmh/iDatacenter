//
// SettingsManager.m
// iDatacenter
//
// Created by Jakob Borg on 2010-11-09.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "SettingsManager.h"

@interface SettingsManager ()
- (void)updateDefaultSettings;
- (NSDictionary*)loadDefaultSettings;
- (void)incrementDefaultsCounter:(NSString*)counter;
- (int)valueForDefaultsCounter:(NSString*)counter;
@end


@implementation SettingsManager

+ (SettingsManager*)instance
{
        static SettingsManager *instance = nil;
        if (!instance)
                instance = [[SettingsManager alloc] init];
        return instance;
}

- (id)init
{
        if ((self = [super init])) {
                defaults = [NSUserDefaults standardUserDefaults];
                [self updateDefaultSettings];
        }
        return self;
}

- (NSString*)server
{
        return [defaults stringForKey:@"vcenter_server"];
}

- (NSString*)username
{
        return [defaults stringForKey:@"vcenter_username"];
}

- (NSString*)password
{
        if (!password)
                password = [defaults stringForKey:@"vcenter_password"];
        return password;
}

- (BOOL)rememberPassword
{
        return [defaults boolForKey:@"remember_password"];
}

- (void)setServer:(NSString*)value
{
        [defaults setObject:value forKey:@"vcenter_server"];
        [defaults synchronize];
}

- (void)setUsername:(NSString*)value
{
        [defaults setObject:value forKey:@"vcenter_username"];
        [defaults synchronize];
}

- (void)setPassword:(NSString*)value
{
        password = value;
        if ([self rememberPassword])
                [defaults setObject:value forKey:@"vcenter_password"];
        else
                [defaults removeObjectForKey:@"vcenter_password"];
        [defaults synchronize];
}

- (void)setRememberPassword:(BOOL)value
{
        [defaults setBool:value forKey:@"remember_password"];
        if (value)
                [defaults setObject:password forKey:@"vcenter_password"];
        else
                [defaults removeObjectForKey:@"vcenter_password"];
        [defaults synchronize];
}

- (int)totalLaunches
{
        return [defaults integerForKey:@"total_launches"];
}

- (int)currentVersionLaunches
{
        return [defaults integerForKey:@"current_version_launches"];
}

- (NSTimeInterval)installedTimeInterval
{
        NSDate *installed = [defaults valueForKey:@"current_version_installed_date"];
        if (!installed)
                return 0;
        else
                return -[installed timeIntervalSinceNow];
}

- (BOOL)displayedBetaWarning
{
        return [defaults boolForKey:@"displayed_beta_warning"];
}

- (void)setDisplayedBetaWarning:(BOOL)value
{
        [defaults setBool:value forKey:@"displayed_beta_warning"];
        [defaults synchronize];
}

- (BOOL)debug
{
        return [defaults boolForKey:@"debug"];
}

- (void)setDebug:(BOOL)value
{
        [defaults setBool:value forKey:@"debug"];
        [defaults synchronize];
}

/*
   Private
 */

- (void)updateDefaultSettings
{
        NSDictionary *defaultSettings = [self loadDefaultSettings];
        [defaults registerDefaults:defaultSettings];

        NSString *currentVersionNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *currentBuildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *currentVersion = [NSString stringWithFormat:@"%@ (%@)", currentVersionNumber, currentBuildNumber];
        NSString *defaultsVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"current_version"];
        if (defaultsVersion == nil || [currentVersion compare:defaultsVersion] != NSOrderedSame) {
                [defaults setObject:currentVersion forKey:@"current_version"];
                [defaults setObject:[NSNumber numberWithInt:0] forKey:@"current_version_launches"];
                [defaults setObject:[NSDate date] forKey:@"current_version_installed_date"];
#if defined(ADHOC) || defined(DEBUG)
                [defaults setBool:NO forKey:@"displayed_beta_warning"];
#endif
        }
        [self incrementDefaultsCounter:@"current_version_launches"];
        [self incrementDefaultsCounter:@"total_launches"];
        [defaults synchronize];
}

- (NSDictionary*)loadDefaultSettings
{
        NSString *pathStr = [[NSBundle mainBundle] bundlePath];
        NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
        NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];

        NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];

        NSMutableDictionary *defaultSettings = [NSMutableDictionary dictionary];
        for (NSDictionary*prefItem in prefSpecifierArray) {
                NSString *keyValueStr = [prefItem objectForKey:@"Key"];
                id defaultValue = [prefItem objectForKey:@"DefaultValue"];
                if (keyValueStr && defaultValue)
                        [defaultSettings setObject:defaultValue forKey:keyValueStr];
        }
        return defaultSettings;
}

- (void)incrementDefaultsCounter:(NSString*)counter
{
        NSNumber *n = [defaults valueForKey:counter];
        if (!n)
                n = [NSNumber numberWithInt:1];
        else
                n = [NSNumber numberWithInt:[n intValue] + 1];
        [defaults setObject:n forKey:counter];
}

- (int)valueForDefaultsCounter:(NSString*)counter
{
        NSNumber *n = [defaults valueForKey:counter];
        return [n intValue];
}

@end
