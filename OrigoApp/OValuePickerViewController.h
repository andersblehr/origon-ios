//
//  OValuePickerViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OValuePickerViewController : OTableViewController<OTableViewController> {
@private
    id<OSettings> _settings;
    NSString *_settingKey;
}

@end
