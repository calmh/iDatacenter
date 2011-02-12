//
// NSManagedObject+Compare.m
// iDatacenter
//
// Created by Jakob Borg on 8/27/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "NSManagedObject+Compare.h"
#import "NSManagedObjectMethods.h"

@implementation NSManagedObject (Compare)

- (NSComparisonResult)compareNames:(NSManagedObject*)other
{
        return [self.name compare:other.name];
}

@end
