//
// PickerController.h
// iDatacenter
//
// Created by Jakob Borg on 8/15/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PICKER_WIDTH 300.0f

@class PickerController;

@protocol PickerControlDelegate
- (void)picker:(PickerController*)picker selectedValue:(NSNumber*)value;
@end

@interface PickerController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate> {
        NSMutableArray *choices;
        NSMutableArray *values;
        NSObject<PickerControlDelegate> *delegate;
        NSString *tagString;
}

@property (nonatomic, assign) NSObject<PickerControlDelegate> *delegate;
@property (nonatomic, retain) NSString *tagString;

- (void)addChoice:(NSString*)choice value:(int)value;

@end
