//
// InitialSettingsController.h
// iDatacenter
//
// Created by Jakob Borg on 5/13/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "InfrastructureManager.h"
#import <UIKit/UIKit.h>

@class IDCApplicationDelegate;

@interface InitialSettingsController : UIViewController<InfrastructureManagerDelegate> {
        IDCApplicationDelegate *delegate;
        UITextField *vcenterServer;
        UITextField *username;
        UITextField *password;
        UIActivityIndicatorView *spinner;
        UISegmentedControl *connectButton;
        UISwitch *rememberPassword;
}

@property (nonatomic, assign) IBOutlet IDCApplicationDelegate *delegate;
@property (nonatomic, retain) IBOutlet UITextField *vcenterServer;
@property (nonatomic, retain) IBOutlet UITextField *username;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UISwitch *rememberPassword;

- (IBAction)connect:(id)sender;

@end
