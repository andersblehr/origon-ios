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

@end
