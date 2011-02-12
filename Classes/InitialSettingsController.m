//
// InitialSettingsController.m
// iDatacenter
//
// Created by Jakob Borg on 5/13/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "IDCApplicationDelegate.h"
#import "InfrastructureManager.h"
#import "InitialSettingsController.h"
#import "SettingsManager.h"

@implementation InitialSettingsController

@synthesize delegate;
@synthesize vcenterServer;
@synthesize username;
@synthesize password;
@synthesize spinner;

- (void)dealloc
{
        [vcenterServer release];
        [username release];
        [password release];
        [spinner release];
        [connectButton release];
        [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
        NSInteger nextTag = textField.tag + 1;
        UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
        if (nextResponder)
                [nextResponder becomeFirstResponder];
        else
                [textField resignFirstResponder];
        return NO;
}

- (IBAction)connect:(id)sender
{
        vcenterServer.enabled = NO;
        username.enabled = NO;
        password.enabled = NO;
        connectButton.enabled = NO;
        [spinner startAnimating];
        [delegate.infrastructureManager testConnectionWithServer:vcenterServer.text username:username.text password:password.text delegate:self];
}

- (void)connectionFailedWithError:(NSError*)error
{
        vcenterServer.enabled = YES;
        username.enabled = YES;
        password.enabled = YES;
        connectButton.enabled = YES;
        [spinner stopAnimating];
        [delegate showConnectionErrorAlert:error];
}

- (void)connectionTestSucceeded
{
        [spinner stopAnimating];
        SettingsManager *settings = [SettingsManager instance];
        settings.server = vcenterServer.text;
        settings.username = username.text;
        settings.password = password.text;
        settings.rememberPassword = rememberPassword.on;
        [delegate hideInitialSettings];
}

- (void)addConnectButton
{
        connectButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Connect", nil)]];
        connectButton.segmentedControlStyle = UISegmentedControlStyleBar;
        connectButton.frame = CGRectMake(rememberPassword.frame.origin.x, rememberPassword.frame.origin.y + rememberPassword.frame.size.height + 8.0f, connectButton.frame.size.width, connectButton.frame.size.height);
        connectButton.momentary = YES;
        connectButton.tintColor = GREEN_TINT;
        [connectButton addTarget:self action:@selector(connect:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:connectButton];
}

- (void)viewDidLoad
{
        [super viewDidLoad];

        self.view.backgroundColor = LIGHT_GRAY_BACKGROUND;
        [self addConnectButton];

        SettingsManager *settings = [SettingsManager instance];
        vcenterServer.text = settings.server;
        username.text = settings.username;
        rememberPassword.on = settings.rememberPassword;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
        [super viewDidUnload];
}

@end
