//
//  ONavigationController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "ONavigationController.h"

@implementation ONavigationController

#pragma mark - UIViewController overrides

- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return [[OState s].viewController supportedInterfaceOrientations];
}

@end
