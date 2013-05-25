//
//  OSettingViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 21.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OSettingViewController.h"

#import "OState.h"
#import "OStrings.h"

@implementation OSettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = [OStrings settingTitleForKey:_settingKey];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    _settingKey = self.data;
    
    self.target = _settingKey;
}

@end
