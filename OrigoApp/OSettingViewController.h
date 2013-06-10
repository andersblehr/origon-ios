//
//  OSettingViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 21.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OLocatorDelegate.h"
#import "OTableViewListCellDelegate.h"

@class OTableViewCell;
@class OSettings;

@interface OSettingViewController : OTableViewController<OTableViewListCellDelegate, OLocatorDelegate> {
@private
    OSettings *_settings;
    NSString *_settingKey;
    
    OTableViewCell *_valueCell;
    NSMutableArray *_valueList;
    
    BOOL _listContainsParenthesisedCountries;
}

@end
