//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OState.h"
#import "OStrings.h"


@implementation OTableViewController

#pragma mark - State handling

- (void)loadState
{
    if ([OStrings hasStrings]) {
        if ([self shouldSetState]) {
            if ([self respondsToSelector:@selector(setStatePrerequisites)]) {
                [self setStatePrerequisites];
            }
            
            [self setState];
            
            _didLoadState = YES;
        }
    } else {
        [OState s].actionIsSetup = YES;
    }
}


- (void)reflectState
{
    if (!_didLoadState) {
        [self loadState];
    } else {
        [[OState s] reflect:_state];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _state = [[OState alloc] init];
    _modalImpliesRegistration = YES;
    
    [self loadState];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_didSetModal) {
        _isModal = (self.presentingViewController && ![self isMovingToParentViewController]);
        
        if (_isModal && _modalImpliesRegistration) {
            _state.actionIsRegister = YES;
        }
        
        _didSetModal = YES;
    }
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    
    _isPushed = [self isMovingToParentViewController];
    _isPopped = (!_isPushed && !_isModal && !_wasHidden);
    
    [self reflectState];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _isHidden = (self.presentedViewController != nil);
}


#pragma mark - OStateDelegate conformance

- (BOOL)shouldSetState
{
    return YES;
}


- (void)setState
{
    // Override in subclass
}

@end
