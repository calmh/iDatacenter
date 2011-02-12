//
// VisualizationViewController.m
// iDatacenter
//
// Created by Jakob Borg on 8/17/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "HostMO.h"
#import "NSManagedObjectMethods.h"
#import "VirtualMachineMO.h"
#import "VisualizationEdgeView.h"
#import "VisualizationNodeView.h"
#import "VisualizationRootView.h"
#import "VisualizationViewController.h"

@implementation VisualizationViewController

#define CONTENT_SIZE 2048

@synthesize content;
@synthesize scrollView;

- (void)dealloc
{
        [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
        if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
                self.modalPresentationStyle = UIModalPresentationFullScreen;
                self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                self.scrollView.backgroundColor = LIGHT_GRAY_BACKGROUND;
        }
        return self;
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [content setFrame:CGRectMake(0.0f, 0.0f, CONTENT_SIZE, CONTENT_SIZE)];
        [scrollView setContentSize:CGSizeMake(CONTENT_SIZE, CONTENT_SIZE)];
        [scrollView setContentInset:UIEdgeInsetsMake(512.0f, 512.0f, 512.0f, 512.0f)];
        [scrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
        [scrollView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
        [scrollView flashScrollIndicators];
}

- (void)addNodeOfSize:(float)size atPoint:(CGPoint)point withLabel:(NSString*)label shade:(float)shade
{
        VisualizationNodeView *node = [[VisualizationNodeView alloc] initWithFrame:CGRectMake(point.x - size / 2.0f, point.y - size / 2.0f, size, size)];
        node.label.text = label;
        node.shade = shade;
        [content addSubview:node];
        [node release];
}

- (void)addEdgeFromPoint:(CGPoint)pointA toPoint:(CGPoint)pointB
{
        float inset = 25.0f;

        VisualizationEdgeView *edge;
        if (pointB.y < pointA.y) {
                // Wrong order, change it.
                CGPoint tmp = pointA;
                pointA = pointB;
                pointB = tmp;
        }

        BOOL left = NO;
        CGRect frame;

        if (pointB.x < pointA.x) {
                // Right to left
                frame = CGRectMake(pointB.x, pointA.y, pointA.x - pointB.x, pointB.y - pointA.y);
                left = YES;
        } else {
                // Left ro right
                frame = CGRectMake(pointA.x, pointA.y, pointB.x - pointA.x, pointB.y - pointA.y);
        }

        frame = CGRectInset(frame, -inset, -inset);
        edge = [[VisualizationEdgeView alloc] initWithFrame:frame];
        edge.left = left;
        edge.inset = inset;

        [content addSubview:edge];
        [edge release];
}

- (void)visualizeHost:(HostMO*)host
{
        float mainAreaPart = 0.75f;
        float marginPart = 0.15f;
        float sideAreaPart = 0.1f;

        float size = content.frame.size.width;
        float mainAreaWidth = size * mainAreaPart;
        float marginWidth = size * marginPart;
        float sideAreaWidth = size * sideAreaPart;

        NSMutableDictionary *nodes = [[NSMutableDictionary alloc] init];
        NSMutableArray *edges = [[NSMutableArray alloc] init];

        // Datastores

        NSArray *datastores = [[host.datastore allObjects] sortedArrayUsingSelector:@selector(compareNames:)];
        float sideNodeSpacing = size / [datastores count];
        float sideNodeSize = sideNodeSpacing * 0.9f;
        if (sideNodeSize > sideAreaWidth * 0.9f)
                sideNodeSize = sideAreaWidth * 0.9f;
        if (sideNodeSpacing > sideNodeSize * 1.5f)
                sideNodeSpacing = sideNodeSize * 1.5f;

        NSArray *dsCapacity = [[datastores valueForKey:@"totalMB"] sortedArrayUsingSelector:@selector(compare:)];
        int minCap = [[dsCapacity objectAtIndex:0] intValue];
        int maxCap = [[dsCapacity lastObject] intValue];

        int column = 0;
        for (NSManagedObject*ds in datastores) {
                float x = sideNodeSpacing * (0.5f + column);
                float y = 0.5f * sideAreaWidth;
                float sizeFactor = ([ds.totalMB intValue] - minCap) / (float) (maxCap - minCap); // 0.0 - 1.0 or NaN
                if (isnan(sizeFactor))
                        sizeFactor = 1.0f;
                sizeFactor = (float) sqrt(sizeFactor); // Account for area scale, sort of.
                float nodeSize = (sideNodeSize * 0.33f) + (sizeFactor * sideNodeSize * 0.67f); // Size varies between 33% and 100% of sideNodeSize;
                float usage = 1.0f - (float) [ds.freeMB intValue] / (float) [ds.totalMB intValue];

                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSValue valueWithCGPoint:CGPointMake(x, y)], @"point",
                                      [NSNumber numberWithFloat:nodeSize], @"size",
                                      [NSNumber numberWithFloat:usage], @"shade",
                                      ds.name, @"label", nil];
                [nodes setObject:data forKey:ds.id];
                column++;
        }

        // Networks

        NSArray *networks = [[host.network allObjects] sortedArrayUsingSelector:@selector(compareNames:)];
        // int minCap = [[dsCapacity objectAtIndex:0] intValue];
        // int maxCap = [[dsCapacity lastObject] intValue];

        sideNodeSpacing = size / [networks count];
        sideNodeSize = sideNodeSpacing * 0.9f;
        if (sideNodeSize > sideAreaWidth * 0.9f)
                sideNodeSize = sideAreaWidth * 0.9f;
        if (sideNodeSpacing > sideNodeSize * 1.5f)
                sideNodeSpacing = sideNodeSize * 1.5f;

        int row = 0;
        for (NSManagedObject*net in networks) {
                float x = mainAreaWidth  + marginWidth + 0.5f * sideAreaWidth;
                float y   = sideNodeSpacing  * (0.5f + row);
                float sizeFactor = 0.9f; // ([ds.totalMB intValue] - minCap) / (float) (maxCap - minCap); // 0.0 - 1.0 or NaN
                if (isnan(sizeFactor))
                        sizeFactor = 1.0f;
                sizeFactor = (float) sqrt(sizeFactor); // Account for area scale, sort of.
                float nodeSize = (sideNodeSize * 0.33f) + (sizeFactor * sideNodeSize * 0.67f); // Size varies between 33% and 100% of sideNodeSize;
                float usage = 0.5f; // 1.0f - (float) [ds.freeMB intValue] / (float) [ds.totalMB intValue];

                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSValue valueWithCGPoint:CGPointMake(x, y)], @"point",
                                      [NSNumber numberWithFloat:nodeSize], @"size",
                                      [NSNumber numberWithFloat:usage], @"shade",
                                      net.name, @"label", nil];
                [nodes setObject:data forKey:net.id];
                row++;
        }

        // Virtual machines

        NSArray *vms = [[host.vm allObjects] sortedArrayUsingSelector:@selector(compareNames:)];
        int vmsPerRow = (int) (sqrt([vms count]) + 1);
        float vmSpacing = mainAreaWidth / vmsPerRow;
        float maxSize = vmSpacing * 0.95f;
        float minSize = vmSpacing * 0.4f;

        NSArray *vmsRAM = [[vms valueForKey:@"configuredMemoryMB"] sortedArrayUsingSelector:@selector(compare:)];
        int minRAM = [[vmsRAM objectAtIndex:0] intValue];
        int maxRAM = [[vmsRAM lastObject] intValue];

        row = 0;
        column = 0;
        for (VirtualMachineMO*vm in vms) {
                float sizeFactor = ([vm.configuredMemoryMB intValue] - minRAM) / (float) (maxRAM - minRAM); // 0.0 - 1.0 or NaN
                if (isnan(sizeFactor))
                        sizeFactor = 1.0f;
                float nodeSize = minSize + (maxSize - minSize) * (float) sqrt(sizeFactor);
                float x = vmSpacing * (0.5f + column);
                float y = sideAreaWidth + marginWidth + vmSpacing * 0.5f + row * vmSpacing;
                float usage = (float) [vm.hostMemoryUsageMB intValue] / (float) [vm.configuredMemoryMB intValue];
                CGPoint point = CGPointMake(x, y);
                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSValue valueWithCGPoint:point], @"point",
                                      [NSNumber numberWithFloat:nodeSize], @"size",
                                      [NSNumber numberWithFloat:usage], @"shade",
                                      vm.name, @"label", nil];
                [nodes setObject:data forKey:vm.id];
                column++;
                if (column == vmsPerRow) {
                        column = 0;
                        row++;
                }

                for (NSManagedObject*ds in vm.datastores) {
                        NSValue *coordA = [NSValue valueWithCGPoint:point];
                        NSValue *coordB = [[nodes objectForKey:ds.id] objectForKey:@"point"];
                        NSArray *coords = [NSArray arrayWithObjects:coordA, coordB, nil];
                        [edges addObject:coords];
                }

                for (NSManagedObject*net in vm.network) {
                        NSString *netId = net.id;
                        NSValue *coordA = [NSValue valueWithCGPoint:point];
                        NSValue *coordB = [[nodes objectForKey:netId] objectForKey:@"point"];
                        if (!coordB)
                                NSLog(@"VM '%@' uses nonexistent network '%@'", vm.name, net.name);
                        else {
                                NSArray *coords = [NSArray arrayWithObjects:coordA, coordB, nil];
                                [edges addObject:coords];
                        }
                }
        }

        // Draw edges

        for (NSArray*arr in edges) {
                CGPoint pointA = [(NSValue*)[arr objectAtIndex:0] CGPointValue];
                CGPoint pointB = [(NSValue*)[arr objectAtIndex:1] CGPointValue];
                [self addEdgeFromPoint:pointA toPoint:pointB];
        }

        // Draw nodes

        for (NSDictionary*dict in [nodes allValues]) {
                float nodeSize = [(NSNumber*)[dict objectForKey:@"size"] floatValue];
                float shade = [(NSNumber*)[dict objectForKey:@"shade"] floatValue];
                CGPoint point = [(NSValue*) [dict objectForKey:@"point"] CGPointValue];
                NSString *label = [dict objectForKey:@"label"];
                [self addNodeOfSize:nodeSize atPoint:point withLabel:label shade:shade];
        }

        [scrollView zoomToRect:CGRectMake(-100.0f, -100.0f, CONTENT_SIZE + 200.0f, CONTENT_SIZE + 200.0f) animated:YES];
}

- (void)viewDidUnload
{
        [super viewDidUnload];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView
{
        return content;
}

- (IBAction)close
{
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self dismissModalViewControllerAnimated:YES];
}

@end
