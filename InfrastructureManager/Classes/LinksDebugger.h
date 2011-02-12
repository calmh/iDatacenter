//
// IDCDebugger.h
// iDatacenter
//
// Created by Jakob Borg on 6/21/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LinksDebugger : NSObject {
        NSFileHandle *fileHandle;
}

- (void)truncateLinksFile;
- (void)linkFromObject:(NSString*)objectId destination:(NSString*)destination type:(NSString*)type attribute:(NSString*)attribute status:(NSString*)status;
- (void)attributeOnObject:(NSString*)objectId attribute:(NSString*)attribute status:(NSString*)status;
- (void)flushLinksFile;

@end
