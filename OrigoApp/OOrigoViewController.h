//
//  OOrigoViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OModalViewControllerDelegate;

@class OMembership, OOrigo;
@class OTableViewCell, OTextField;

@interface OOrigoViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
@private
    OTableViewCell *_origoCell;
    OOrigo *_origo;
    
    OTextField *_addressLine1Field;
    OTextField *_addressLine2Field;
    OTextField *_telephoneField;
}

@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;

@property (strong, nonatomic) OMembership *membership;
@property (strong, nonatomic) NSString *origoType;

@end
