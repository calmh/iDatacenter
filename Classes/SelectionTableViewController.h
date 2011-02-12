//
// SelectionTableViewController.h
// iDatacenter
//
// Created by Jakob Borg on 8/3/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectionTableViewController;

@protocol SelectionTableDelegate
- (void)selectionTable:(SelectionTableViewController*)table selectedTag:(NSObject*)tag;
@end

@interface SelectionTableViewController : UITableViewController {
        NSMutableArray *options;
        NSString *header;
        NSObject<SelectionTableDelegate> *delegate;
        CGFloat width;
        UITableViewCellStyle cellStyle;
}

@property (nonatomic, assign) NSObject<SelectionTableDelegate> *delegate;
@property (nonatomic, retain) NSString *header;
@property (nonatomic, assign) CGFloat width;

- (void)addOptionWithTitle:(NSString*)title subTitle:(NSString*)subTitle tag:(NSObject*)tag;
- (void)addOptionWithTitle:(NSString*)title tag:(NSObject*)tag;

@end
