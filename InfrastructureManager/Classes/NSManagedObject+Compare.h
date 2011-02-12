//
// NSManagedObject+Compare.h
// iDatacenter
//
// Created by Jakob Borg on 8/27/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface NSManagedObject (Compare)

- (NSComparisonResult)compareNames:(NSManagedObject*)other;

@end
