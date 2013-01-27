//
//  OOrigoViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

@protocol OEntityObservingDelegate, OModalViewControllerDelegate;

@class OMember, OMembership, OOrigo;
@class OTableViewCell, OTextField, OTextView;

@interface OOrigoViewController : OTableViewController<UITextViewDelegate> {
@private
    OTableViewCell *_origoCell;
    OOrigo *_origo;
    
    OTextView *_addressView;
    OTextField *_telephoneField;
    
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIView *_currentField;
}

@property (strong, nonatomic) OOrigo *origo;
@property (strong, nonatomic) OMember *member;
@property (strong, nonatomic) OMembership *membership;

@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;
@property (weak, nonatomic) id<OEntityObservingDelegate> entityObservingDelegate;

@end
