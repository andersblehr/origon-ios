//
//  OCalendarViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCalendarViewController.h"


@implementation OCalendarViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [OStrings stringForKey:strViewTitleCalendar];
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
