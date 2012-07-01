//
//  ScScolaViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScScola;
@class ScTextField;

@interface ScScolaViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
@private
    ScTextField *addressField;
    ScTextField *landlineField;
    ScTextField *websiteField;
}

@property (weak, nonatomic) ScScola *scola;

@end
