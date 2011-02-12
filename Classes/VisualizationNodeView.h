//
// VisualizationNodeView.h
// iDatacenter
//
// Created by Jakob Borg on 8/17/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VisualizationNodeView : UIView {
        UILabel *label;
        float shade;
}

@property (readonly) UILabel *label;
@property (nonatomic, assign) float shade;

@end
