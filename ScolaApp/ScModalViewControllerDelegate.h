//
//  ScModalViewControllerDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScModalViewControllerDelegate <NSObject>

@required
- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier;

@end
