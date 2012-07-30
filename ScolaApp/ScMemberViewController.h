//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScMemberViewControllerDelegate.h"
#import "ScModalViewControllerDelegate.h"
#import "ScServerConnectionDelegate.h"

@class ScMembership, ScScola;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate, ScModalViewControllerDelegate>

@property (weak, nonatomic) id<ScMemberViewControllerDelegate> delegate;

@property (weak, nonatomic) ScMembership *membership;
@property (weak, nonatomic) ScScola *scola;

@end
