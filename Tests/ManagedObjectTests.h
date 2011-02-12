//
// DatacenterTests.h
// iDatacenter
//
// Created by Jakob Borg on 5/4/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "DatacenterMO.h"
#import "FolderMO.h"
#import "HostMO.h"
#import "NSDate+Parsing.h"
#import "TestBase.h"
#import "VirtualMachineMO.h"

@interface ManagedObjectTests : TestBase {
        DatacenterMO *datacenter;
        HostMO *host;
        VirtualMachineMO *vm;
}

@end
