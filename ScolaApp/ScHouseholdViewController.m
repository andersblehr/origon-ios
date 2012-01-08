//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScHouseholdViewController.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScStrings.h"


NSString * const kAppStateKeyUserInfo = @"userInfo";


@implementation ScHouseholdViewController

@synthesize darkLinenView;
@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;
@synthesize addressUserHelpLabel;
@synthesize nameField;
@synthesize editNameButton;
@synthesize streetAddressField;
@synthesize postCodeAndCityField;
@synthesize dateOfBirthUserHelpLabel;
@synthesize dateOfBirthPicker;


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];

    NSDictionary *userInfo = [[ScAppEnv env].appState objectForKey:kAppStateKeyUserInfo];
    
    deviceNameUserHelpLabel.text = [ScStrings stringForKey:strDeviceNameUserHelp];
    deviceNameField.placeholder = [ScStrings stringForKey:strDeviceNamePrompt];
    deviceNameField.text = [ScAppEnv env].deviceName;
    
    addressUserHelpLabel.text = [ScStrings stringForKey:strAddressUserHelp];
    nameField.placeholder = [userInfo objectForKey:@"name"];
    nameField.text = @"";
    streetAddressField.placeholder = [ScStrings stringForKey:strStreetAddressPrompt];
    streetAddressField.text = @"";
    postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
    postCodeAndCityField.text = @"";
    
    dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}


#pragma mark - IBAction implementation

- (IBAction)editName:(id)sender
{
    isNameEditingAllowed = YES;
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return (textField == nameField) ? isNameEditingAllowed : YES;
}

@end
