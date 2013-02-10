//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalViewControllerDelegate.h"
#import "OTableViewControllerDelegate.h"

@protocol OEntityObservingDelegate;

@class OState, OTableViewCell;
@class OReplicatedEntity;

@interface OTableViewController : UITableViewController<OTableViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OModalViewControllerDelegate> {
@private
    Class _entityClass;
    NSInteger _entitySectionKey;
    
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _isHidden;
    BOOL _needsReloadData;
    
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    
    NSNumber *_lastSectionKey;
    NSIndexPath *_selectedIndexPath;
    UIView *_emphasisedField;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewControllerDelegate> _delegate;
}

@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OReplicatedEntity *entity;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL shouldInitialise;
@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL shouldDemphasiseOnEndEdit;
@property (nonatomic) BOOL modalImpliesRegistration;

@property (strong, nonatomic) id data;
@property (strong, nonatomic) id meta;
@property (strong, nonatomic) id<OModalViewControllerDelegate> dismisser;
@property (strong, nonatomic) id<OEntityObservingDelegate> observer;
@property (strong, nonatomic) OTableViewCell *detailCell;

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)entitiesInSectionWithKey:(NSInteger)sectionKey;
- (id)entityAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;
- (id)entityForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue;
- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data;
- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data;
- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data meta:(id)meta;

- (void)reflectState;
- (void)toggleEditMode;
- (void)resumeFirstResponder;

@end
