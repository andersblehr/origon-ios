//
//  ScScolaViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"

#import "ScMember.h"
#import "ScScola.h"


@implementation ScScolaViewController

@synthesize delegate;
@synthesize scola;


#pragma mark - Selector implementations

- (void)startEditing
{
    
}


- (void)cancelEditing
{
    [delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
}


- (void)didFinishEditing
{
    if ([ScMeta isAddressValidWithLine1:addressLine1Field line2:addressLine2Field]) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        scola.addressLine1 = addressLine1Field.text;
        scola.addressLine2 = addressLine2Field.text;
        scola.landline = landlineField.text;
        
        if ([ScMeta appState] == ScAppStateRegisterUserHousehold) {
            ScMember *member = [context fetchEntityWithId:[ScMeta m].userId];
            member.activeSince = [NSDate date];
        }
        
        [context synchronise];
        
        [self.view endEditing:YES];
        [delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
    } else {
        [scolaCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    isRegistering = ([ScMeta appState] == ScAppStateRegisterUserHousehold);
    isRegistering = isRegistering || ([ScMeta appState] == ScAppStateRegisterScola);
    isRegistering = isRegistering || ([ScMeta appState] == ScAppStateRegisterScolaMemberHousehold);
    
    isDisplaying = ([ScMeta appState] == ScAppStateDisplayUserHousehold);
    isDisplaying = isDisplaying || ([ScMeta appState] == ScAppStateDisplayScola);
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (isRegistering) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        if ([ScMeta appState] == ScAppStateRegisterUserHousehold) {
            self.navigationItem.hidesBackButton = YES;
        } else {
            self.navigationItem.leftBarButtonItem = cancelButton;
        }
    } else if (isDisplaying) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}


- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [ScMeta popAppState];
    }
    
    [super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ScTableViewCell heightForEntity:scola editing:isRegistering];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isRegistering) {
        scolaCell = [tableView cellForEntity:scola editing:YES delegate:self];
        
        addressLine1Field = [scolaCell textFieldWithKey:kTextFieldKeyAddressLine1];
        addressLine2Field = [scolaCell textFieldWithKey:kTextFieldKeyAddressLine2];
        landlineField = [scolaCell textFieldWithKey:kTextFieldKeyLandline];
        
        [addressLine1Field becomeFirstResponder];
    } else if (isDisplaying) {
        scolaCell = [tableView cellForEntity:scola];
    }
    
    return scolaCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadowForBottomTableViewCell];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == addressLine1Field) {
        [addressLine2Field becomeFirstResponder];
    } else if (textField == addressLine2Field) {
        [landlineField becomeFirstResponder];
    }
    
    return YES;
}

@end
