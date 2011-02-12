//
// DetailTableViewController.m
// iDatacenter
//
// Created by Jakob Borg on 7/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "InfrastructureManager.h"
#import "VMDetailTableViewController.h"
#import "VMDetailViewController.h"
#import "SettingsManager.h"

@interface DetailTableViewController ()
- (enum SectionType)sectionTypeForSection:(NSInteger)section;
- (UITableViewCell*)prepareDetailCellForTableView:(UITableView*)tableView;
- (void)configureDetailCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)prepareRecentTaskCellForTableView:(UITableView*)tableView;
- (void)configureRecentTaskCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)prepareConfigIssueCellForTableView:(UITableView*)tableView;
- (void)configureConfigIssueCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void)configureMetaCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void)tappedSegmentedControl:(UISegmentedControl*)control;
@end

@implementation DetailTableViewController

#define COMMAND_BUTTON_WIDTH 65.0f

@synthesize delegate;
@synthesize backgroundView;

- (void)dealloc
{
        [debugData release];
        [super dealloc];
}

- (void)setDebugData:(NSString*)data forKey:(NSString*)key
{
        if (data && key)
                [debugData setObject:data forKey:key];
        else if (key)
                [debugData setObject:@"(nil)" forKey:key];
}

- (void)updateWithObject:(NSManagedObject*)object
{
        [self setDebugData:[object id] forKey:@"moId"];
}

- (void)updateConfigurationIssues:(NSArray*)issues
{
        [configIssues release];
        configIssues = [issues retain];
}

- (void)updateRecentTasks:(NSArray*)tasks
{
        [recentTasks release];
        recentTasks = [tasks retain];
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        debugData = [[NSMutableDictionary alloc] init];
        self.tableView.backgroundView = backgroundView;
        settings = [SettingsManager instance];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
        NSInteger sections = [sectionTitles count];
        if ([configIssues count] > 0)
                sections++;
        if ([recentTasks count] > 0)
                sections++;
        if (settings.debug && [debugData count] > 0)
                sections++;
        return sections;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
        enum SectionType sectionType = [self sectionTypeForSection:section];
        if (sectionType == SectionTypeNormal)
                return [[sectionValues objectAtIndex:section] count];
        else if (sectionType == SectionTypeConfigIssues)
                return [configIssues count];
        else if (sectionType == SectionTypeRecentTasks)
                return [recentTasks count];
        else if (sectionType == SectionTypeMeta) {
                if (settings.debug)
                        return [debugData count];
                else
                        return 0;
        }
        return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
        enum SectionType sectionType = [self sectionTypeForSection:section];
        if (sectionType == SectionTypeNormal)
                return [sectionTitles objectAtIndex:section];
        else if (sectionType == SectionTypeConfigIssues)
                return NSLocalizedString(@"Configuration Issues", nil);
        else if (sectionType == SectionTypeRecentTasks)
                return NSLocalizedString(@"Recent Tasks", nil);
        else if (sectionType == SectionTypeMeta)
                return NSLocalizedString(@"Meta", nil);
        return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
        enum SectionType sectionType = [self sectionTypeForSection:indexPath.section];
        UITableViewCell *cell = nil;

        if (sectionType == SectionTypeNormal) {
                cell = [self prepareDetailCellForTableView:tableView];
                [self configureDetailCell:cell atIndexPath:indexPath];
        } else if (sectionType == SectionTypeConfigIssues) {
                cell = [self prepareConfigIssueCellForTableView:tableView];
                [self configureConfigIssueCell:cell atIndexPath:indexPath];
        } else if (sectionType == SectionTypeRecentTasks) {
                cell = [self prepareRecentTaskCellForTableView:tableView];
                [self configureRecentTaskCell:cell atIndexPath:indexPath];
        } else if (sectionType == SectionTypeMeta) {
                cell = [self prepareDetailCellForTableView:tableView];
                [self configureMetaCell:cell atIndexPath:indexPath];
        }

        if (!cell) {
                // Catastrophic fallback
                cell = [self prepareDetailCellForTableView:tableView];
                cell.textLabel.text = @"-";
                cell.detailTextLabel.text = @"-";
                cell.backgroundColor = GRAY_CELL_BACKGROUND;
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
}

- (enum SectionType)sectionTypeForSection:(NSInteger)section
{
        BOOL hasExtraConfigIssuesSection = [configIssues count] > 0;
        BOOL hasExtraRecentTasksSection = [recentTasks count] > 0;
        int realSections = [sectionValues count];
        if (section < realSections)
                return SectionTypeNormal;
        else if (section == realSections && hasExtraConfigIssuesSection)
                return SectionTypeConfigIssues;
        else if (section == realSections && !hasExtraConfigIssuesSection && hasExtraRecentTasksSection)
                return SectionTypeRecentTasks;
        else if (section == realSections + 1 && hasExtraConfigIssuesSection && hasExtraRecentTasksSection)
                return SectionTypeRecentTasks;
        else
                return SectionTypeMeta;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
        [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
        [[cell detailTextLabel] setBackgroundColor:[UIColor clearColor]];
}

- (UITableViewCell*)prepareDetailCellForTableView:(UITableView*)tableView
{
        static NSString *cellIdentifier = @"DetailCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = GRAY_CELL_BACKGROUND;
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
        }
        return cell;
}

- (void)configureDetailCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
        NSDictionary *value = [[sectionValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [value objectForKey:@"title"];
        cell.detailTextLabel.text = [value objectForKey:@"value"];
        UIColor *customBackground = [value objectForKey:@"backgroundColor"];
        if (customBackground)
                cell.backgroundColor = customBackground;
        else
                cell.backgroundColor = GRAY_CELL_BACKGROUND;

        NSArray *commands = [value objectForKey:@"commands"];
        if (commands) {
                UISegmentedControl *buttons = [[UISegmentedControl alloc] initWithItems:commands];
                UIColor *tintColor = [value objectForKey:@"tintColor"];
                if (!tintColor)
                        tintColor = BLUE_TINT;
                buttons.userInteractionEnabled = YES;
                buttons.momentary = YES;
                buttons.segmentedControlStyle = UISegmentedControlStyleBar;
                buttons.tintColor = tintColor;
                buttons.tag = [[value objectForKey:@"tag"] intValue];
                CGRect frame = buttons.frame;
                frame.size.width = COMMAND_BUTTON_WIDTH;
                buttons.frame = frame;
                [buttons addTarget:self action:@selector(tappedSegmentedControl:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = buttons;
        } else
                cell.accessoryView = nil;
}

- (UITableViewCell*)prepareRecentTaskCellForTableView:(UITableView*)tableView
{
        static NSString *cellIdentifier = @"RecentTaskCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
        }
        return cell;
}

- (void)configureRecentTaskCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
        NSManagedObject *task = [recentTasks objectAtIndex:indexPath.row];
        if ([task.managedObjectContext validateObject:task]) {
                UIProgressView *progress = (UIProgressView*) cell.accessoryView;
                if ([[task state] isEqualToString:@"running"]) {
                        int percentComplete = [[task progress] intValue];
                        cell.textLabel.text = [NSString stringWithFormat:@"%@: running (%d%%)", [task descriptionId], percentComplete];
                        progress.progress = percentComplete / 100.0f;
                        progress.hidden = NO;
                } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", [task descriptionId], [task state]];
                        progress.hidden = YES;
                }
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", [[task belongsTo] name], [self.delegate localizedTimestampForDate:[task started]]];
                if ([[task state] isEqualToString:@"pending"])
                        cell.backgroundColor = GRAY_CELL_BACKGROUND;
                else if ([[task state] isEqualToString:@"running"])
                        cell.backgroundColor = BLUE_CELL_BACKGROUND;
                else if ([[task state] isEqualToString:@"success"])
                        cell.backgroundColor = GREEN_CELL_BACKGROUND;
                else if ([[task state] isEqualToString:@"error"])
                        cell.backgroundColor = RED_CELL_BACKGROUND;
                else
                        cell.backgroundColor = GRAY_CELL_BACKGROUND;
        } else {
                cell.backgroundColor = GRAY_CELL_BACKGROUND;
                cell.textLabel.text = cell.detailTextLabel.text = @"-";
        }
}

- (UITableViewCell*)prepareConfigIssueCellForTableView:(UITableView*)tableView
{
        static NSString *cellIdentifier = @"ConfigIssueCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
                cell.backgroundColor = YELLOW_CELL_BACKGROUND;
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
}

- (void)configureConfigIssueCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
        cell.textLabel.text = [configIssues objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)configureMetaCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
        NSString *key = [[[debugData allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:indexPath.row];
        cell.textLabel.text = key;
        cell.detailTextLabel.text = [debugData objectForKey:key];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{ }

- (void)tappedSegmentedControl:(UISegmentedControl*)control
{
        NSInteger tag = control.tag;
        NSInteger idx = control.selectedSegmentIndex;
        CGRect controlFrame = control.frame;
        CGRect rect = [delegate.view convertRect:controlFrame fromView:control.superview];
        [self tappedButtonWithTag:tag index:idx rect:rect];
}

- (void)tappedButtonWithTag:(NSInteger)tag index:(NSInteger)idx rect:(CGRect)rect;
{ }

- (NSString*)formatStorageAmount:(long)megabytes
{
        if (megabytes < 1024)
                return [NSString stringWithFormat:@"%ld MB", megabytes];
        else if (megabytes < 1024 * 1024)
                return [NSString stringWithFormat:@"%.01f GB", megabytes / 1024.f];
        else
                return [NSString stringWithFormat:@"%.02f TB", megabytes / 1024.f / 1024.0f];
}

@end
