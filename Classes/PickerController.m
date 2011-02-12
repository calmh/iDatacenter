#import "PickerController.h"

@implementation PickerController

@synthesize delegate;
@synthesize tagString;

- (id)init
{
        if ((self = [super init])) {
                choices = [[NSMutableArray alloc] init];
                values = [[NSMutableArray alloc] init];
        }
        return self;
}

- (void)dealloc
{
        [choices release];
        [values release];
        [self.view release];
        [super dealloc];
}

- (void)loadView
{
        self.view = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, PICKER_WIDTH, 180.0f)] autorelease];
        self.view.backgroundColor = LIGHT_GRAY_BACKGROUND;

        UIPickerView *pv = [[[UIPickerView alloc] init] autorelease];
        pv.frame = self.view.frame;
        pv.dataSource = self;
        pv.delegate = self;

        [self.view addSubview:pv];
        self.contentSizeForViewInPopover = pv.frame.size;
}

- (void)addChoice:(NSString*)choice value:(int)value
{
        [choices addObject:choice];
        [values addObject:[NSNumber numberWithInt:value]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        // Overriden to allow any orientation.
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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
        return 1;
}

- (NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
        return [choices count];
}

- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
        return [choices objectAtIndex:row];
}

- (void)pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
        if ([delegate respondsToSelector:@selector(picker:selectedValue:)])
                [delegate performSelector:@selector(picker:selectedValue:) withObject:self withObject:[values objectAtIndex:row]];
}

@end
