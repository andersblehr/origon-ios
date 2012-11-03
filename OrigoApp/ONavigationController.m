//
//  ONavigationController.m
//  OrigoApp
//
//  Created by Anders Blehr on 03.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "ONavigationController.h"

#import "OMeta.h"


@implementation ONavigationController

#pragma mark - Reset root view controller

- (void)popToAuthViewController
{
    [[OMeta m] userDidSignOut];
    
    [self setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:kAuthViewControllerId]] animated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    id rootViewController = nil;
    
    if ([OMeta m].userIsSignedIn && [OMeta m].registrationIsComplete) {
        rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:kTabBarControllerId];
    } else {
        rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:kAuthViewControllerId];
    }
    
    self.viewControllers = [NSArray arrayWithObject:rootViewController];
}

@end
