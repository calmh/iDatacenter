//
// NSURLConnectionWithUserinfo.h
// iDatacenter
//
// Created by Jakob Borg on 9/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnectionWithUserInfo : NSURLConnection {
        NSDictionary *userInfo;
}

@property (retain, nonatomic) NSDictionary *userInfo;

@end
