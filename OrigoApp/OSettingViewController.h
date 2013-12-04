//
//  OSettingViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OSettingViewController : OTableViewController<OTableViewListDelegate> {
@private
    OSettings *_settings;
    NSString *_settingKey;
    
    OTableViewCell *_valueCell;
}

@end
