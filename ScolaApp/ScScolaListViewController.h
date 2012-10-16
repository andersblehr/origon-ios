//
//  ScScolaListViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScMember, ScScola;

@interface ScScolaListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate> {
@private
    NSMutableSet *_scolas;
    NSArray *_sortedResidences;
    NSArray *_sortedWards;
    NSArray *_sortedScolas;
    
    ScScola *_selectedScola;
    ScMember *_selectedWard;
}

@end
