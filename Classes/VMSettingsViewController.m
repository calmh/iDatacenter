//
// VMSettingsViewController.m
// iDatacenter
//
// Created by Jakob Borg on 8/15/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "HostMO.h"
#import "PickerController.h"
#import "VMSettingsViewController.h"
#import "VirtualMachineMO.h"

@implementation VMSettingsViewController

@synthesize applyButton;
@synthesize cancelButton;
@synthesize tableView;
@synthesize vm;

- (void)dealloc
{
        [newValues dealloc];
        [super dealloc];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
        if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
                self.modalPresentationStyle = UIModalPresentationFormSheet;
                self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                self.applyButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Apply", nil)]];
                applyButton.segmentedControlStyle = UISegmentedControlStyleBar;
                applyButton.tintColor = [UIColor colorWithRed:0.3f green:0.8f blue:0.5f alpha:1];
                applyButton.momentary = YES;
                [applyButton addTarget:self action:@selector(applyPressed:) forControlEvents:UIControlEventValueChanged];
                CGRect currentFrame = applyButton.frame;
                currentFrame.size.width = 80.0f;
                currentFrame.origin.x = 540.0f - currentFrame.size.width - 32.0f;
                currentFrame.origin.y = 620.0f - currentFrame.size.height - 32.0f;
                applyButton.frame = currentFrame;
                [self.view addSubview:applyButton];

                self.cancelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Cancel", nil)]];
                cancelButton.segmentedControlStyle = UISegmentedControlStyleBar;
                cancelButton.tintColor = [UIColor colorWithRed:0.3f green:0.5f blue:0.8f alpha:1];
                cancelButton.momentary = YES;
                [cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventValueChanged];
                currentFrame = cancelButton.frame;
                currentFrame.size.width = 80.0f;
                currentFrame.origin.x = 32.f;
                currentFrame.origin.y = 620.0f - currentFrame.size.height - 32.0f;
                cancelButton.frame = currentFrame;
                [self.view addSubview:cancelButton];

                self.tableView.backgroundView = nil;
                self.view.backgroundColor = LIGHT_GRAY_BACKGROUND;

                newValues = [[NSMutableDictionary alloc] init];
        }
        return self;
}

- (void)viewDidLoad
{
        [super viewDidLoad];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
        return 2;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section
{
        return 3;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
        return [[NSArray arrayWithObjects:NSLocalizedString(@"Processor Settings", nil), NSLocalizedString(@"Memory Settings", nil), nil] objectAtIndex:section];
}

- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
        static NSString *cellIdentifier = @"SettingsCell";
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        NSNumber *current = nil;
        BOOL changed = YES;
        if (indexPath.section == 0) { // CPU
                switch (indexPath.row) {
                case 0:
                        cell.textLabel.text = @"Virtual CPUs";
                        current = [newValues valueForKey:@"configuredCpus"];
                        if (!current) {
                                changed = NO;
                                current = vm.configuredCpus;
                        }
                        if ([current intValue] == 1)
                                cell.detailTextLabel.text = @"1 CPU";
                        else
                                cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" CPUs"];
                        break;
                case 1:
                        current = [newValues valueForKey:@"cpuReservation"];
                        if (!current) {
                                changed = NO;
                                current = vm.cpuReservation;
                        }
                        cell.textLabel.text = @"Reservation";
                        cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" MHz"];
                        break;
                case 2:
                        current = [newValues valueForKey:@"cpuLimit"];
                        if (!current) {
                                changed = NO;
                                current = vm.cpuLimit;
                        }
                        cell.textLabel.text = @"Limit";
                        cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" MHz"];
                        break;
                }
        } else if (indexPath.section == 1) { // RAM
                switch (indexPath.row) {
                case 0:
                        current = [newValues valueForKey:@"configuredMemoryMB"];
                        if (!current) {
                                changed = NO;
                                current = vm.configuredMemoryMB;
                        }
                        cell.textLabel.text = @"Allocated Memory";
                        cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" MB"];
                        break;
                case 1:
                        current = [newValues valueForKey:@"memoryReservation"];
                        if (!current) {
                                changed = NO;
                                current = vm.memoryReservation;
                        }
                        cell.textLabel.text = @"Reservation";
                        cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" MB"];
                        break;
                case 2:
                        current = [newValues valueForKey:@"memoryLimit"];
                        if (!current) {
                                changed = NO;
                                current = vm.memoryLimit;
                        }
                        cell.textLabel.text = @"Limit";
                        cell.detailTextLabel.text = [[current stringValue] stringByAppendingString:@" MB"];
                        break;
                }
        }

        if (changed)
                cell.backgroundColor = BLUE_CELL_BACKGROUND;
        else
                cell.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];

        return cell;
}

- (IBAction)applyPressed:(id)sender
{
        [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)cancelPressed:(id)sender
{
        [self dismissModalViewControllerAnimated:YES];
}

- (void)addMemoryChoicesTo:(PickerController*)pic upTo:(int)maxMemory
{
        for (int i = 64; i < 1024 && i <= maxMemory; i += 64)
                [pic addChoice:[NSString stringWithFormat:@"%d MB", i] value:i];
        for (int i = 1024; i < 4096 && i <= maxMemory; i += 128)
                [pic addChoice:[NSString stringWithFormat:@"%d MB", i] value:i];
        for (int i = 4096; i < 8192 && i <= maxMemory; i += 256)
                [pic addChoice:[NSString stringWithFormat:@"%d MB", i] value:i];
        for (int i = 8192; i <= maxMemory; i += 512)
                [pic addChoice:[NSString stringWithFormat:@"%d MB", i] value:i];
}

- (void)addCyclesChoicesTo:(PickerController*)pic upTo:(int)maxCycles
{
        for (int i = 50; i < 500 && i <= maxCycles; i += 50)
                [pic addChoice:[NSString stringWithFormat:@"%d MHz", i] value:i];
        for (int i = 500; i < 1000 && i <= maxCycles; i += 100)
                [pic addChoice:[NSString stringWithFormat:@"%d MHz", i] value:i];
        for (int i = 1000; i < 4000 && i <= maxCycles; i += 250)
                [pic addChoice:[NSString stringWithFormat:@"%d MHz", i] value:i];
        for (int i = 4000; i <= maxCycles; i += 500)
                [pic addChoice:[NSString stringWithFormat:@"%d MHz", i] value:i];
}

- (void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
        PickerController *pic = [[PickerController alloc] init];
        pic.delegate = self;

        if (indexPath.section == 0) { // CPU
                switch (indexPath.row) {
                case 0:
                        pic.tagString = @"configuredCpus";
                        [pic addChoice:@"1 CPU" value:1];
                        [pic addChoice:@"2 CPUs" value:2];
                        [pic addChoice:@"4 CPUs" value:4];
                        break;
                case 1:
                        pic.tagString = @"cpuReservation";
                        [pic addChoice:@"None" value:-1];
                        [self addCyclesChoicesTo:pic upTo:[vm.host.cyclesPerCpuMHz intValue]];
                        break;
                case 2:
                        pic.tagString = @"cpuLimit";
                        [pic addChoice:@"None" value:-1];
                        [self addCyclesChoicesTo:pic upTo:[vm.host.cyclesPerCpuMHz intValue]];
                        break;
                }
        } else if (indexPath.section == 1) { // RAM
                switch (indexPath.row) {
                case 0:
                        pic.tagString = @"configuredMemoryMB";
                        [self addMemoryChoicesTo:pic upTo:[vm.host.totalMemoryMB intValue]];
                        break;
                case 1:
                        pic.tagString = @"memoryReservation";
                        [pic addChoice:@"None" value:-1];
                        [self addMemoryChoicesTo:pic upTo:[vm.configuredMemoryMB intValue]];
                        break;
                case 2:
                        pic.tagString = @"memoryLimit";
                        [pic addChoice:@"None" value:-1];
                        [self addMemoryChoicesTo:pic upTo:[vm.configuredMemoryMB intValue]];
                        break;
                }
        }

        CGRect rect = [aTableView rectForRowAtIndexPath:indexPath];
        UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:pic];
        [pc presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

- (void)picker:(PickerController*)picker selectedValue:(NSNumber*)value
{
        NSLog(@"New value for %@: %@", picker.tagString, value);
        [newValues setValue:value forKey:picker.tagString];
        [tableView reloadData];
}

@end
