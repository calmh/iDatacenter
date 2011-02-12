//
// SelectionTableViewController.m
// iDatacenter
//
// Created by Jakob Borg on 8/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "SelectionTableViewController.h"

@interface SelectionTableViewController ()
- (void)adjustHeightInPopover;
- (float)desiredHeight;
- (UIFont*)headerFont;
@end


@implementation SelectionTableViewController

@synthesize delegate;
@synthesize header;
@synthesize width;

#define MAX_HEIGHT 500.0f

- (void)dealloc
{
        [options dealloc];
        [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
        if ((self = [super initWithStyle:style])) {
                options = [[NSMutableArray alloc] init];
                width = 320.0f;
                cellStyle = UITableViewCellStyleDefault;

                self.tableView.scrollEnabled = NO;
                self.tableView.backgroundView = nil;
                self.tableView.backgroundColor = LIGHT_GRAY_BACKGROUND;
                self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
        return self;
}

- (void)addOptionWithTitle:(NSString*)title tag:(NSObject*)tag
{
        [self addOptionWithTitle:title subTitle:nil tag:tag];
}

- (void)addOptionWithTitle:(NSString*)title subTitle:(NSString*)subTitle tag:(NSObject*)tag
{
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, @"title", tag, @"tag", nil];
        if (subTitle) {
                [dict setObject:subTitle forKey:@"subTitle"];
                cellStyle = UITableViewCellStyleValue1;
        }
        [options addObject:dict];
        [self adjustHeightInPopover];
}

/*
 * UIViewController stuff
 */

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

/*
 * UITableViewDelegate stuff
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
        return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
        return [options count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
        static NSString *cellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
                if (cellStyle == UITableViewCellStyleDefault)
                        cell.textLabel.textAlignment = UITextAlignmentCenter;
        }

        NSDictionary *cellData = [options objectAtIndex:indexPath.row];
        cell.textLabel.text = [cellData valueForKey:@"title"];
        cell.detailTextLabel.text = [cellData valueForKey:@"subTitle"];

        return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
        if (delegate && [delegate respondsToSelector:@selector(selectionTable:selectedTag:)]) {
                NSDictionary *dict = [options objectAtIndex:indexPath.row];
                NSObject *tag = [dict valueForKey:@"tag"];
                [delegate performSelector:@selector(selectionTable:selectedTag:) withObject:self withObject:tag];
        }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
        UIFont *font = [self headerFont];
        CGSize size = [header sizeWithFont:font constrainedToSize:CGSizeMake(width, 1000.0f) lineBreakMode:UILineBreakModeWordWrap];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, size.height)] autorelease];
        label.font = font;
        label.text = header;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.numberOfLines = 0;
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEADER_LABEL_COLOR;
        label.shadowOffset = CGSizeMake(0.0f, 1.0f);
        label.shadowColor = [UIColor whiteColor];
        return label;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
        UIFont *font = [self headerFont];
        CGSize size = [header sizeWithFont:font constrainedToSize:CGSizeMake(width, 1000.0f) lineBreakMode:UILineBreakModeWordWrap];
        return size.height + 16.0f;
}

/*
 * Private
 */

- (void)adjustHeightInPopover
{
        float height = [self desiredHeight];
        if (height > MAX_HEIGHT) {
                height = MAX_HEIGHT;
                self.tableView.scrollEnabled = YES;
        } else
                self.tableView.scrollEnabled = NO;
        self.contentSizeForViewInPopover = CGSizeMake(width, height);
}

- (float)desiredHeight
{
        return [self tableView:nil heightForHeaderInSection:0] + 44.0f * [options count] + 12.0f;
}

- (UIFont*)headerFont
{
        return [UIFont boldSystemFontOfSize:17.0f];
}

@end
