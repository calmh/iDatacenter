//
// NSURLConnectionWithUserinfo.m
// iDatacenter
//
// Created by Jakob Borg on 9/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "NSURLConnectionWithUserinfo.h"

@implementation NSURLConnectionWithUserInfo
@synthesize userInfo;

- (void)dealloc
{
        self.userInfo = nil;
        [super dealloc];
}

@end
