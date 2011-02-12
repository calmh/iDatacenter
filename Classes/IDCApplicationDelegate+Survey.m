//
// IDCApplicationDelegate+Survey.m
// iDatacenter
//
// Created by Jakob Borg on 9/4/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "IDCApplicationDelegate+Survey.h"

@implementation IDCApplicationDelegate (Survey)

- (void)conditionallyDisplaySurveyPrompt
{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL hasPrompted = [defaults boolForKey:@"has_prompted_for_survey"];
        NSDate *cutoffDate = [NSDate dateWithTimeIntervalSince1970:1285884000]; // 2010-10-01 00:00 CET
        if (!hasPrompted && [cutoffDate timeIntervalSinceNow] > 0) {
                int currentLaunches = [defaults integerForKey:@"current_version_launches"];
                if (currentLaunches >= 10 && currentLaunches % 5 == 0) {
                        NSString *title = NSLocalizedString(@"Make your opinion count!", nil);
                        NSString *message = NSLocalizedString(@"Would you like to take a short survey to help improve iDatacenter in the future? It is just five short questions, and takes at most a minute or two.", nil);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"No, and don't ask again", nil) otherButtonTitles:NSLocalizedString(@"Yes, please", nil), NSLocalizedString(@"Maybe later", nil), nil];
                        alert.tag = SURVEY_ALERT_TAG;
                        [alert show];
                        [alert release];
                }
        }
}

- (void)surveyAlertclickedButtonAtIndex:(NSInteger)buttonIndex
{
        if (buttonIndex == 2) {
                // "Remind me later", do nothing now.
        } else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"has_prompted_for_survey"];
                if (buttonIndex == 1)
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://nym.se/survey"]];
        }
}

@end
