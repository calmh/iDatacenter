//
// MREntities.h
// TrackerPad
//
// Created by Jakob Borg on 4/5/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_4_0
@interface MREntitiesConverter : NSObject<NSXMLParserDelegate> {
#else
@interface MREntitiesConverter : NSObject {
#endif
        NSMutableString *resultString;
}

- (NSString*)convertEntiesInString:(NSString*)s;

@end
