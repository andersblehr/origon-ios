//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OMember, OOrigo;

@interface OOrigoListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate> {
@private
    NSMutableSet *_origos;
    
    NSArray *_sortedResidences;
    NSArray *_sortedWards;
    NSArray *_sortedOrigos;
    
    BOOL _tableViewHasResidenceSection;
    BOOL _tableViewHasWardSection;
    BOOL _tableViewHasOrigoSection;
    
    NSInteger _numberOfSections;

    OMember *_selectedMember;
    OOrigo *_selectedOrigo;
}

@end
