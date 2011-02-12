//
// VisualizationEdgeView.h
// iDatacenter
//
// Created by Jakob Borg on 8/24/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VisualizationEdgeView : UIView {
        BOOL left;
        float inset;
}

@property (nonatomic, assign) BOOL left;
@property (nonatomic, assign) float inset;

@end
