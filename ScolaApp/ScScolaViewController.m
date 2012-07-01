//
//  ScScolaViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaViewController.h"

#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"

#import "ScScola.h"


@implementation ScScolaViewController

@synthesize scola;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
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
    ScTableViewCell *scolaCell = [tableView cellForEntity:scola editing:YES delegate:self];
    
    addressField = [scolaCell textFieldWithKey:kTextFieldKeyAddress];
    landlineField = [scolaCell textFieldWithKey:kTextFieldKeyLandline];
    websiteField = [scolaCell textFieldWithKey:kTextFieldKeyScolaWebsite];
    
    [addressField becomeFirstResponder];
    
    return scolaCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadowForBottomTableViewCell];
}

@end
