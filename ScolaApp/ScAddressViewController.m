//
//  ScAddressViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAddressViewController.h"

#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScHousehold.h"
#import "ScLogging.h"
#import "ScStrings.h"

static NSString * const kSegueToDateOfBirthView = @"addressToDateOfBirthView";


@implementation ScAddressViewController

@synthesize darkLinenView;
@synthesize addressUserHelpLabel;
@synthesize addressLine1Field;
@synthesize addressLine2Field;
@synthesize postCodeAndCityField;


#pragma mark - Auxiliary methods

- (BOOL)isDoneEditing
{
    NSString *addressLine1 = addressLine1Field.text;
    NSString *addressLine2 = addressLine2Field.text;
    NSString *postCodeAndCity = postCodeAndCityField.text;
    
    BOOL isDone = (addressLine1.length || addressLine2.length || postCodeAndCity.length);
    
    if (isDone) {
        ScManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        ScHousehold *household = [context entityForClass:ScHousehold.class];
        
        household.addressLine1 = addressLine1Field.text;
        household.addressLine2 = addressLine2Field.text;
        household.postCodeAndCity = postCodeAndCityField.text;

        [context save];
        
        [self performSegueWithIdentifier:kSegueToDateOfBirthView sender:self];
    } else {
        UIAlertView *noAddressAlert = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strNoAddressAlert] delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        [noAddressAlert show];
    }

    return isDone;
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
    
    [darkLinenView addGradientLayer];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strNext] style:UIBarButtonItemStyleDone target:self action:@selector(isDoneEditing)];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nextButton;
    
    addressLine1Field.delegate = self;
    addressLine2Field.delegate = self;
    postCodeAndCityField.delegate = self;
    
    addressUserHelpLabel.text = [ScStrings stringForKey:strProvideAddressUserHelp];
    addressLine1Field.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
    addressLine2Field.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
    postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
    
    addressLine1Field.text = @"";
    addressLine2Field.text = @"";
    postCodeAndCityField.text = @"";
    
    [addressLine1Field becomeFirstResponder];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [self isDoneEditing];
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [addressLine1Field becomeFirstResponder];
}

@end
