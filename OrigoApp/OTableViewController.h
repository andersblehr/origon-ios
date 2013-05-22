//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalViewControllerDelegate.h"
#import "OServerConnectionDelegate.h"
#import "OTableViewControllerInstance.h"

extern NSString * const kEmptyDetailCellPlaceholder;

@protocol OEntityObservingDelegate;

@class OState, OTableViewCell;
@class OReplicatedEntity;

@interface OTableViewController : UITableViewController<OTableViewControllerInstance, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OModalViewControllerDelegate, OServerConnectionDelegate> {
@protected
    NSString *_viewId;

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
    
    id<OTableViewControllerInstance> _instance;
}

@property (strong, nonatomic, readonly) NSString *viewId;
@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OReplicatedEntity *entity;
@property (strong, nonatomic, readonly) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, readonly) BOOL isListView;
@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL shouldDemphasiseOnEndEdit;
@property (nonatomic) BOOL modalImpliesRegistration;
@property (nonatomic) BOOL cancelRegistrationImpliesSignOut;

@property (strong, nonatomic) id data;
@property (strong, nonatomic) id meta;
@property (strong, nonatomic) id aspectCarrier;
@property (strong, nonatomic) id<OModalViewControllerDelegate> dismisser;
@property (strong, nonatomic) id<OEntityObservingDelegate> observer;
@property (strong, nonatomic) OTableViewCell *detailCell;

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)dataInSectionWithKey:(NSInteger)sectionKey;
- (id)dataAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;
- (id)dataForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber;

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue;
- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data;

- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data;
- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data meta:(id)meta;
- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data dismisser:(id)dismisser;

- (void)reflectState;
- (void)toggleEditMode;
- (void)reloadSectionsIfNeeded;
- (void)resumeFirstResponder;

@end
