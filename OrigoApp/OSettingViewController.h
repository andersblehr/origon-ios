//
//  OSettingViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 21.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OSettingViewController : OTableViewController<OTableViewListDelegate, OLocatorDelegate> {
@private
    OSettings *_settings;
    NSString *_settingKey;
    
    OTableViewCell *_valueCell;
    
    BOOL _listContainsParenthesisedCountries;
}

@end
