//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

@class OTableViewCell;
@class OMember, OOrigo;

@interface OOrigoListViewController : OTableViewController<UIActionSheetDelegate> {
@private
    OMember *_member;
    
    NSMutableArray *_origoTypes;
    NSString *_selectedOrigoType;
}

@end
