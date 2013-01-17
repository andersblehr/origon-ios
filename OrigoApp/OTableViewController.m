//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OState.h"


@implementation OTableViewController

#pragma mark - State handling

- (void)loadState
{
    _stateIsIntrinsic = YES;
    
    if ([self respondsToSelector:@selector(setStatePrerequisites)]) {
        [self setStatePrerequisites];
    }
    
    [self setState];
    
    if (_stateIsIntrinsic) {
        _intrinsicState = [[OState s] copy];
    }
}


- (void)restoreState
{
    if (_intrinsicState) {
        [[OState s] restoreState:_intrinsicState];
    } else {
        [self loadState];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadState];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_intrinsicState) {
        [self restoreState];
    }
}

@end
