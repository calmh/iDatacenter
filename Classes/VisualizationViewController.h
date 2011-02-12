//
// VisualizationViewController.h
// iDatacenter
//
// Created by Jakob Borg on 8/17/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VisualizationRootView;
@class HostMO;

@interface VisualizationViewController : UIViewController<UIScrollViewDelegate> {
        VisualizationRootView *content;
        UIScrollView *scrollView;
}

@property (nonatomic, retain) IBOutlet VisualizationRootView *content;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (void)visualizeHost:(HostMO*)host;
- (IBAction)close;

@end
