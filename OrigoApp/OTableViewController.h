//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kEntityRegistrationCell;
extern NSString * const kCustomCell;
extern NSString * const kCustomValue;

@interface OTableViewController : UITableViewController<OTableViewControllerInstance, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OModalViewControllerDismisser, OConnectionDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _isHidden;
    BOOL _shouldReloadOnModalDismissal;
    
    Class _entityClass;
    NSInteger _detailSectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    
    NSNumber *_lastSectionKey;
    NSIndexPath *_selectedIndexPath;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewControllerInstance> _instance;
}

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OReplicatedEntity *entity;
@property (strong, nonatomic, readonly) NSMutableSet *dirtySections;
@property (strong, nonatomic, readonly) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic, readonly) UIView *actionSheetView;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL modalImpliesRegistration;

@property (strong, nonatomic) id data;
@property (strong, nonatomic) id meta;
@property (strong, nonatomic) OTableViewCell *detailCell;

@property (weak, nonatomic) id<OModalViewControllerDismisser> dismisser;
@property (weak, nonatomic) id<OEntityObserver> observer;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;
- (id)dataAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)dataInSectionWithKey:(NSInteger)sectionKey;

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber;
- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath;

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue;
- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data;

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier data:(id)data;
- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier data:(id)data meta:(id)meta;
- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier dismisser:(id)dismisser;

- (void)toggleEditMode;
- (void)reloadSections;
- (void)reloadSectionWithKey:(NSInteger)sectionKey;
- (void)resumeFirstResponder;
- (void)signOut;

@end
