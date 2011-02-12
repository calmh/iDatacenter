//
// NSDate+Parsing.h
// InfrastructureManager
//
// Created by Jakob Borg on 7/25/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Parsing)

+ (NSDate*)dateByParsingXmlFormat:(NSString*)data;

@end
