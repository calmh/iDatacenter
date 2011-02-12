//
// IDCDebugger.m
// iDatacenter
//
// Created by Jakob Borg on 6/21/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "LinksDebugger.h"

@implementation LinksDebugger

- (void)dealloc
{
        [super dealloc];
}

- (void)truncateLinksFile
{
#ifdef DEBUG
        NSString *docsDir = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
        NSString *filename = [NSString stringWithFormat:@"%@/links.txt", docsDir];
        [[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:filename] retain];
#endif
}

- (void)linkFromObject:(NSString*)objectId destination:(NSString*)destination type:(NSString*)type attribute:(NSString*)attribute status:(NSString*)status
{
#ifdef DEBUG
        NSString *logStr = [NSString stringWithFormat:@"%@.%@ -> %@ (%@): %@\n", objectId, attribute, destination, type, status];
        [fileHandle writeData:[logStr dataUsingEncoding:NSUTF8StringEncoding]];
#endif
}

- (void)attributeOnObject:(NSString*)objectId attribute:(NSString*)attribute status:(NSString*)status
{
#ifdef DEBUG
        NSString *logStr = [NSString stringWithFormat:@"%@.%@: %@\n", objectId, attribute, status];
        [fileHandle writeData:[logStr dataUsingEncoding:NSUTF8StringEncoding]];
#endif
}

- (void)flushLinksFile
{
#ifdef DEBUG
        [fileHandle closeFile];
        [fileHandle release];
        fileHandle = nil;
#endif
}

@end
