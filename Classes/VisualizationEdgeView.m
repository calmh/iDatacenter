//
// VisualizationEdgeView.m
// iDatacenter
//
// Created by Jakob Borg on 8/24/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "VisualizationEdgeView.h"

@implementation VisualizationEdgeView

@synthesize left;
@synthesize inset;

- (id)initWithFrame:(CGRect)frame
{
        if ((self = [super initWithFrame:frame]))
                self.opaque = NO;
        return self;
}

- (void)drawRect:(CGRect)rect
{
        float red = 0.6f;
        float green = 0.7f;
        float blue = 0.8f;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        for (int i = 0; i < 2; i++) {
                float factor = 0.75f + 0.25f * i;
                CGContextSetRGBStrokeColor(ctx, red * factor, green * factor, blue * factor, 0.7f);

                float width = 24.0f - 16.0f * i;
                CGContextSetLineWidth(ctx, width);

                CGSize size = self.frame.size;
                CGPoint pointA = CGPointMake(inset, inset);
                CGPoint pointB = CGPointMake(size.width - inset, size.height - inset);
                if (left) {
                        float tx = pointA.x;
                        pointA.x = pointB.x;
                        pointB.x = tx;
                }

                CGPoint points[2] = { pointA, pointB };
                CGContextStrokeLineSegments(ctx, points, 2);
        }
}

@end
