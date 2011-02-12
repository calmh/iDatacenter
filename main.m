//
// main.m
// iDatacenter
//
// Created by Jakob Borg on 5/2/10.
// Copyright Jakob Borg 2010. All rights reserved.
//

#import "InfrastructureManager.h"
#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int retVal = UIApplicationMain(argc, argv, nil, nil);
        [pool release];
        return retVal;
}
