//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTableViewController<NSObject>

@required
@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic) id target;
@property (strong, nonatomic) id returnData;

- (void)loadState;
- (void)loadData;

@optional
- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (id)defaultTarget;
- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)toolbarButtons;

- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey;

- (UITableViewCellStyle)styleForListCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)willDisplayDetailCell:(OTableViewCell *)cell;
- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey;
- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2;
- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey;

- (BOOL)shouldRelayDismissalOfModalViewController:(id<OTableViewController>)viewController;
- (void)willDismissModalViewController:(id<OTableViewController>)viewController;
- (void)didDismissModalViewController:(id<OTableViewController>)viewController;

- (void)didResumeFromBackground;
- (void)didSignOut;

@end


@interface OTableViewController : UITableViewController<OTableViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, OConnectionDelegate> {
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
    NSMutableDictionary *_sectionFooterLabels;
    NSMutableArray *_sectionIndexTitles;
    NSMutableSet *_dirtySections;

    NSNumber *_lastSectionKey;
    NSIndexPath *_selectedIndexPath;
    OActivityIndicator *_activityIndicator;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewController> _instance;
}

@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic, readonly) OEntityProxy *entity;

@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL requiresSynchronousServerCalls;
@property (nonatomic) BOOL usesPlainTableViewStyle;
@property (nonatomic) BOOL usesSectionIndexTitles;
@property (nonatomic) BOOL cancelImpliesSkip;
@property (nonatomic) BOOL canEdit;

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

- (BOOL)isLastSectionKey:(NSInteger)sectionKey;
- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
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

@end
