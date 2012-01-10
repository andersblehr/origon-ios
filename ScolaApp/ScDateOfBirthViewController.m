//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScDateOfBirthViewController.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScStrings.h"


static NSString * const kSegueToMainView = @"dateOfBirthToMainView";

static int const kGenderSegmentFemale = 0;
static int const kGenderSegmentMale = 1;
static int const kGenderSegmentNeutral = 2;

static int const kPopUpButtonUseBuiltIn = 0;
static int const kPopUpButtonUseNew = 1;


@implementation ScDateOfBirthViewController

@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;
@synthesize genderUserHelpLabel;
@synthesize genderControl;
@synthesize dateOfBirthUserHelpLabel;
@synthesize dateOfBirthField;
@synthesize dateOfBirthPicker;


#pragma mark - auxiliary methods

- (BOOL)isDoneEditing
{
    BOOL isDone = NO;
    
    NSMutableDictionary *userInfo = [[ScAppEnv env].appState objectForKey:kAppStateKeyUserInfo];
    
    if (isSkipping) {
        [userInfo setObject:[ScAppEnv env].deviceName forKey:@"deviceName"];
        
        isDone = YES;
    } else {
        if (deviceNameField.text.length == 0) {
            NSString *deviceType = [ScAppEnv env].deviceType;
            NSString *deviceTypeDeterminate;
            NSString *deviceTypePossessive;
            
            if ([deviceType isEqualToString:@"iPod"]) {
                deviceTypeDeterminate = [ScStrings stringForKey:str_iPodDeterminate];
                deviceTypePossessive = [ScStrings stringForKey:str_iPodPossessive];
            } else if ([deviceType isEqualToString:@"iPad"]) {
                deviceTypeDeterminate = [ScStrings stringForKey:str_iPadDeterminate];
                deviceTypePossessive = [ScStrings stringForKey:str_iPadPossessive];
            } else {
                deviceTypeDeterminate = [ScStrings stringForKey:strPhoneDeterminate];
                deviceTypePossessive = [ScStrings stringForKey:strPhonePossessive];
            }
            
            NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strNoDeviceNameAlert], deviceTypeDeterminate, deviceTypePossessive, [ScAppEnv env].deviceName];
            NSString *useBuiltInButtonTitle = [ScStrings stringForKey:strUseBuiltIn];
            NSString *useNewButtonTitle = [ScStrings stringForKey:strUseNew];
            
            UIAlertView *noDeviceNameAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:useBuiltInButtonTitle otherButtonTitles:useNewButtonTitle, nil];
            [noDeviceNameAlert show];
        } else {
            [userInfo setObject:deviceNameField.text forKey:@"deviceName"];
            
            if (genderControl.selectedSegmentIndex == kGenderSegmentFemale) {
                [userInfo setObject:@"F" forKey:@"gender"];
            } else if (genderControl.selectedSegmentIndex == kGenderSegmentMale) {
                [userInfo setObject:@"M" forKey:@"gender"];
            }
            
            if (hasEditedDateOfBirth) { // TODO: Do some basic age validation
                [userInfo setObject:dateOfBirthPicker.date forKey:@"dateOfBirth"];
            }
            
            isDone = YES;
        }
    }
    
    if (isDone) {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    }
    
    return isDone;
}


- (void)skipEditing
{
    isSkipping = YES;
    
    [self isDoneEditing];
}


- (void)genderChanged
{
    hasEditedGender = YES;
}


- (void)dateOfBirthChanged
{
    hasEditedDateOfBirth = YES;
    
    dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:dateOfBirthPicker.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    UIBarButtonItem *skipThisButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strSkipThis] style:UIBarButtonItemStylePlain target:self action:@selector(skipEditing)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strDone] style:UIBarButtonItemStyleDone target:self action:@selector(isDoneEditing)];
    
    self.navigationItem.leftBarButtonItem = skipThisButton;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    deviceNameUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNameUserHelp], [ScStrings stringForKey:strThisPhone]];
    deviceNameField.placeholder = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNamePrompt], [ScStrings stringForKey:strPhoneDeterminate]];
    deviceNameField.text = [ScAppEnv env].deviceName;
    deviceNameField.delegate = self;
    
    genderUserHelpLabel.text = [ScStrings stringForKey:strGenderUserHelp];
    [genderControl setTitle:[ScStrings stringForKey:strFemale] forSegmentAtIndex:kGenderSegmentFemale];
    [genderControl setTitle:[ScStrings stringForKey:strMale] forSegmentAtIndex:kGenderSegmentMale];
    [genderControl setTitle:[ScStrings stringForKey:strNeutral] forSegmentAtIndex:kGenderSegmentNeutral];
    [genderControl addTarget:self action:@selector(genderChanged) forControlEvents:UIControlEventValueChanged];
    
    dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    dateOfBirthField.delegate = self;
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthChanged) forControlEvents:UIControlEventValueChanged];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSDate *firstOfApril1976 = [dateFormatter dateFromString:@"1976-04-01T20:00:00Z"];
    [dateOfBirthPicker setDate:firstOfApril1976 animated:YES];

    [self dateOfBirthChanged];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL isDateOfBirthField = (textField == dateOfBirthField);
    
    if (isDateOfBirthField) {
        [self.view endEditing:YES];    
    }
    
    return !isDateOfBirthField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [self isDoneEditing];
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kPopUpButtonUseBuiltIn) {
        deviceNameField.text = [ScAppEnv env].deviceName;
        [self isDoneEditing];
    } else if (buttonIndex == kPopUpButtonUseNew) {
        [deviceNameField becomeFirstResponder];
    }
}

@end
