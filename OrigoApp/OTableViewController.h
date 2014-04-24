//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kCustomData;

@interface OTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OConnectionDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _didResurface;
    BOOL _isHidden;
    BOOL _shouldReloadOnModalDismissal;
    
    Class _implicitEntityClass;
    NSInteger _detailSectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    NSMutableArray *_sectionIndexTitles;
    NSMutableSet *_dirtySections;

    NSMutableDictionary *_sectionHeaderLabels;
    NSMutableDictionary *_sectionFooterLabels;

    NSNumber *_lastSectionKey;
    NSIndexPath *_selectedIndexPath;
    OActivityIndicator *_activityIndicator;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewControllerInstance> _instance;
    id _target;
}

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OEntityProxy *entityProxy;
@property (strong, nonatomic, readonly) OActivityIndicator *activityIndicator;

@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL usesPlainTableViewStyle;
@property (nonatomic) BOOL usesSectionIndexTitles;
@property (nonatomic) BOOL cancelImpliesSkip;
@property (nonatomic) BOOL canEdit;

@property (strong, nonatomic) id target;
@property (strong, nonatomic) id meta;
@property (strong, nonatomic) id returnData;
@property (strong, nonatomic) OTableViewCell *detailCell;
@property (strong, nonatomic) OInputField *nextInputField;

@property (weak, nonatomic) OTableViewController *dismisser;
@property (weak, nonatomic) id<OEntityObserver> observer;

- (BOOL)aspectIsHousehold;
- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;

- (void)setDataForDetailSection;
- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (void)setData:(NSArray *)data sectionIndexLabelKey:(NSString *)sectionIndexLabelKey;

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;
- (id)dataAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)dataInSectionWithKey:(NSInteger)sectionKey;

- (BOOL)isLastSectionKey:(NSInteger)sectionKey;
- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber;
- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath;

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target;
- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target meta:(id)meta;
- (void)dismissModalViewController:(OTableViewController *)viewController reload:(BOOL)reload;

- (void)toggleEditMode;
- (void)didCancelEditing;
- (void)didFinishEditing;
- (void)endEditing;

- (void)reloadSections;
- (void)reloadSectionWithKey:(NSInteger)sectionKey;
- (void)reloadHeaderForSectionWithKey:(NSInteger)sectionKey;
- (void)reloadFooterForSectionWithKey:(NSInteger)sectionKey;

- (void)signOut;

@end
