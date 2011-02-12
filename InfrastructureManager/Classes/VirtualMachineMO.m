//
// VirtualMachineMO.m
// InfrastructureManager
//
// Created by Jakob Borg on 6/26/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "DatacenterMO.h"
#import "FolderMO.h"
#import "VirtualMachineMO.h"

@implementation VirtualMachineMO

- (NSString*)currentPowerState
{
        for (NSManagedObject*task in self.recentTasks) {
                if ([task.state isEqualToString:@"running"]) {
                        if ([task.descriptionId isEqualToString:@"VirtualMachine.suspend"])
                                return @"suspending";
                        if ([task.descriptionId isEqualToString:@"VirtualMachine.powerOn"])
                                return @"poweringOn";
                        if ([task.descriptionId isEqualToString:@"VirtualMachine.powerOff"])
                                return @"poweringOff";
                        if ([task.descriptionId isEqualToString:@"VirtualMachine.reset"])
                                return @"resetting";
                }
        }
        return self.powerState;
}

- (NSArray*)children
{
        return [NSArray array];
}

- (NSComparisonResult)compareNames:(VirtualMachineMO*)other
{
        NSManagedObject *myDatastore = [[[self.datastores allObjects] sortedArrayUsingSelector:@selector(compareNames:)] objectAtIndex:0];
        NSManagedObject *otherDatastore = [[[other.datastores allObjects] sortedArrayUsingSelector:@selector(compareNames:)] objectAtIndex:0];
        NSComparisonResult orderedByDatastore = [[myDatastore name] compare:[otherDatastore name]];
        if (orderedByDatastore != NSOrderedSame)
                return orderedByDatastore;
        return [self.name compare:other.name];
}

@end
