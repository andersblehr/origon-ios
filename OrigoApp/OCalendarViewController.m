//
//  OCalendarViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCalendarViewController.h"

#import "OState.h"
#import "OStrings.h"


@implementation OCalendarViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [OStrings stringForKey:strTabBarTitleCalendar];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    // TODO
}

@end
