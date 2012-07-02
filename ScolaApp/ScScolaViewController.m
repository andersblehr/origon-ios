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

#import "ScScola.h"


@implementation ScScolaViewController

@synthesize delegate;
@synthesize scola;


#pragma mark - Selector implementations

- (void)endEditing
{
    if ([ScMeta isAddressValidWithLine1:addressLine1Field line2:addressLine2Field]) {
        scola.addressLine1 = addressLine1Field.text;
        scola.addressLine2 = addressLine2Field.text;
        scola.landline = landlineField.text;
        
        [[ScMeta m].managedObjectContext synchronise];
        
        [self.view endEditing:YES];
        [delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
    } else {
        [scolaCell shake];
    }
}


- (void)cancelEditing
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    
    self.title = [ScStrings stringForKey:strAddressLabel];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
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
    return [ScTableViewCell heightForEntity:scola whenEditing:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    scolaCell = [tableView cellForEntity:scola editing:YES delegate:self];
    
    addressLine1Field = [scolaCell textFieldWithKey:kTextFieldKeyAddressLine1];
    addressLine2Field = [scolaCell textFieldWithKey:kTextFieldKeyAddressLine2];
    landlineField = [scolaCell textFieldWithKey:kTextFieldKeyLandline];
    
    [addressLine1Field becomeFirstResponder];
    
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
