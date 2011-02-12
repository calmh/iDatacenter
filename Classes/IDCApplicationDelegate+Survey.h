//
// IDCApplicationDelegate+Survey.h
// iDatacenter
//
// Created by Jakob Borg on 9/4/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDCApplicationDelegate.h"

@interface IDCApplicationDelegate (Survey)

- (void)conditionallyDisplaySurveyPrompt;
- (void)surveyAlertclickedButtonAtIndex:(NSInteger)buttonIndex;

@end
