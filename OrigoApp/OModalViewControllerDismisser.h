//
//  OModalViewControllerDismisser.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OModalViewControllerDismisser <NSObject>

@required
- (void)dismissModalViewController:(OTableViewController *)viewController reload:(BOOL)reload;

@optional
- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController;
- (void)willDismissModalViewController:(OTableViewController *)viewController;
- (void)didDismissModalViewController:(OTableViewController *)viewController;

@end
