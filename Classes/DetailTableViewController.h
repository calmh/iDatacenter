//
// DetailTableViewController.h
// iDatacenter
//
// Created by Jakob Borg on 7/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

enum SectionType {
        SectionTypeNormal,
        SectionTypeConfigIssues,
        SectionTypeRecentTasks,
        SectionTypeMeta,
};

@class BaseDetailViewController;
@class SettingsManager;

@interface DetailTableViewController : UITableViewController {
        @protected
        NSArray *sectionTitles;
        NSArray *sectionValues;
        @private
        BaseDetailViewController *delegate;
        UIView *backgroundView;
        NSArray *recentTasks;
        NSArray *configIssues;
        NSString *mobId;
        NSMutableDictionary *debugData;
        SettingsManager *settings;
}

@property (nonatomic, assign) IBOutlet BaseDetailViewController *delegate;
@property (nonatomic, assign) IBOutlet UIView *backgroundView;

- (void)updateWithObject:(NSManagedObject*)object;
- (void)updateRecentTasks:(NSArray*)tasks;
- (void)updateConfigurationIssues:(NSArray*)issues;
- (void)setDebugData:(NSString*)data forKey:(NSString*)key;
- (void)tappedButtonWithTag:(NSInteger)tag index:(NSInteger)idx rect:(CGRect)rect;
- (NSString*)formatStorageAmount:(long)megabytes;

@end
