//
//  ScMembershipViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 17.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScMember, ScScola;

@interface ScMembershipViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource>
{
    UIBarButtonItem *addButton;
    
    NSMutableSet *unsortedAdults;
    NSMutableSet *unsortedMinors;
    NSArray *adults;
    NSArray *minors;
    
    BOOL isForHousehold;
    BOOL didAddMembers;
}

@property (weak, nonatomic) ScScola *scola;

@property (nonatomic) BOOL isRegistrationWizardStep;

@end
