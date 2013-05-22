//
//  OSettingViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 21.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OSettingViewController.h"

#import "OMeta.h"

@implementation OSettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    _viewId = kSettingView;
}

@end
