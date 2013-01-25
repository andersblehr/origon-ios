//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewControllerDelegate.h"

@class OState;
@class OReplicatedEntity;

@interface OTableViewController : UITableViewController<OTableViewControllerDelegate> {
@private
    BOOL _didInitialise;
    BOOL _didSetModal;
    BOOL _isHidden;
    
    NSMutableArray *_tableData;
    NSMutableArray *_sectionDeltas;
}

@property (strong, nonatomic, readonly) OState *state;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL modalImpliesRegistration;

- (void)reflectState;

- (void)setData:(id)data forSection:(NSInteger)section;
- (void)addData:(id)data toSection:(NSInteger)section;

- (id)entityForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)sectionIsEmpty:(NSInteger)section;
- (void)reloadSectionsIfNeeded;

@end
