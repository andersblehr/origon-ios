//
//  ONavigationController.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2013 Rhelba Source. All rights reserved.
//

#import "ONavigationController.h"

@implementation ONavigationController

#pragma mark - UIViewController overrides

- (BOOL)shouldAutorotate
{
    return YES;
}


#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return [((UIViewController *)[OState s].viewController) supportedInterfaceOrientations];
}

@end
