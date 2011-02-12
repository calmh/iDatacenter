//
// NSArray+Flatten.m
// iDatacenter
//
// Created by Jakob Borg on 9/11/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "NSArray+Flatten.h"

@implementation NSArray (Flatten)

- (NSArray*)arrayByFlattening
{
        NSMutableArray *r = [NSMutableArray new];
        NSEnumerator *en = [self objectEnumerator];
        id o;
        while ((o = [en nextObject])) {
                if ([o isKindOfClass:[NSArray class]])
                        [r addObjectsFromArray:[o arrayByFlattening]];
                else {
                        if (o != [NSNull null])
                                [r addObject:o];
                }
        }
        return [NSArray arrayWithArray:r];
}

@end
