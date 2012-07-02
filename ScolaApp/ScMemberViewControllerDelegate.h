//
//  ScMemberViewControllerDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScModalViewControllerDelegate.h"

#import "ScMembership.h"

@protocol ScMemberViewControllerDelegate <ScModalViewControllerDelegate>

@optional
- (void)insertMembershipInTableView:(ScMembership *)membership;

@end
