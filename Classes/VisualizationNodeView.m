//
// VisualizationNodeView.m
// iDatacenter
//
// Created by Jakob Borg on 8/17/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "VisualizationNodeView.h"

@implementation VisualizationNodeView

@synthesize label;
@synthesize shade;

- (id)initWithFrame:(CGRect)frame
{
        if ((self = [super initWithFrame:frame])) {
                self.opaque = NO;
                CGRect labelFrame = CGRectMake(frame.size.width * 0.1f, 0.0f, frame.size.width * 0.8f, frame.size.height * 0.9f);
                label = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = UITextAlignmentCenter;
                label.font = [UIFont boldSystemFontOfSize:60.0f];
                label.adjustsFontSizeToFitWidth = YES;
                label.textColor = [UIColor whiteColor];
                [self addSubview:label];
        }
        return self;
}

- (void)drawRect:(CGRect)rect
{
        shade = shade * shade;
        float red = 0.1f + 0.9f * shade;
        float green = 0.5f - 0.5f * shade;
        float blue = 1.0f - 0.9f * shade;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        for (int i = 0; i < 3; i++) {
                float factor = 0.8f + 0.1f * i;
                float inset = 1.0f + 16.0f * i;
                CGContextSetRGBFillColor(ctx, red * factor, green * factor, blue * factor, 1.0f);
                CGContextFillEllipseInRect(ctx, CGRectInset(rect, inset, inset));
        }
}

- (void)dealloc
{
        [super dealloc];
}

@end
