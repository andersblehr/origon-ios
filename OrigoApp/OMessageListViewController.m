//
//  OMessageListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMessageListViewController.h"

@implementation OMessageListViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [OStrings stringForKey:strTabBarTitleMessages];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    // TODO
}


- (void)initialiseDataSource
{
    // TODO
}

@end
