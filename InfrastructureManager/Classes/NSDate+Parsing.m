//
// NSDate+Parsing.m
// InfrastructureManager
//
// Created by Jakob Borg on 7/25/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "NSDate+Parsing.h"

@implementation NSDate (Parsing)

+ (NSDateFormatter*)xmlFormatFormatter
{
        static NSDateFormatter *formatter = nil;
        if (formatter == nil) {
                formatter = [[NSDateFormatter alloc] init];
                NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                [formatter setLocale:enUS];
                [enUS release];
                // 2010-07-24T10:10:14.091484Z
                [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                [formatter setDateFormat:@"yyyy-LL-dd'T'HH:mm:ss.SSSSSS'Z'"];
        }
        return formatter;
}

+ (NSDate*)dateByParsingXmlFormat:(NSString*)data
{
        NSDateFormatter *formatter = [NSDate xmlFormatFormatter];
        return [formatter dateFromString:data];
}

@end
