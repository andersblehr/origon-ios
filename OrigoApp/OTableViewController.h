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

extern NSString * const kCustomCell;

@protocol OEntityObservingDelegate;

@class OState, OTableViewCell;
@class OReplicatedEntity;

@interface OTableViewController : UITableViewController<OTableViewControllerInstance, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OModalViewControllerDelegate, OServerConnectionDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _isHidden;
    BOOL _needsReloadSections;
    
    Class _entityClass;
    NSInteger _entitySectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    
    NSNumber *_lastSectionKey;
    NSIndexPath *_selectedIndexPath;
    NSInteger _reauthenticationLandingTabIndex;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewControllerInstance> _instance;
}

@property (strong, nonatomic, readonly) NSString *viewId;
@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) id target;

@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OReplicatedEntity *entity;
@property (strong, nonatomic, readonly) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL modalImpliesRegistration;
@property (nonatomic) BOOL cancelRegistrationImpliesSignOut;

@property (strong, nonatomic) id data;
@property (strong, nonatomic) id meta;
@property (strong, nonatomic) OTableViewCell *detailCell;

@property (weak, nonatomic) id<OModalViewControllerDelegate> dismisser;
@property (weak, nonatomic) id<OEntityObservingDelegate> observer;

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)dataInSectionWithKey:(NSInteger)sectionKey;
- (id)dataAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;
- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber;
- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath;

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue;
- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data;

- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data;
- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data meta:(id)meta;
- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data dismisser:(id)dismisser;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;

- (void)reflectState;
- (void)toggleEditMode;
- (void)reloadSectionsIfNeeded;
- (void)reloadSectionWithKey:(NSInteger)sectionKey;
- (void)resumeFirstResponder;

@end
