//
//  ScScolaViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScModalViewControllerDelegate.h"

@class ScScola;

@interface ScScolaViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

@end
