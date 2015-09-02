//
//  OTableViewController.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTableViewController<UITableViewDataSource, UITableViewDelegate, OTitleViewDelegate,  OConnectionDelegate>

@required
@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic) id target;
@property (strong, nonatomic) id returnData;

- (void)loadState;
- (void)loadData;

@optional
- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)didSetEntity:(id)entity;

- (NSString *)reuseIdentifierForInputSection;
- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey;

- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (CGFloat)headerHeightForSectionWithKey:(NSInteger)sectionKey;
- (CGFloat)footerHeightForSectionWithKey:(NSInteger)sectionKey;
- (id)headerContentForSectionWithKey:(NSInteger)sectionKey;
- (id)footerContentForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)emptyTableViewFooterText;

- (BOOL)toolbarHasSendTextButton;
- (BOOL)toolbarHasCallButton;
- (BOOL)toolbarHasSendEmailButton;

- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey;
- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2;
- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey;

- (void)willDisplayInputCell:(OTableViewCell *)inputCell;
- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldDeleteCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController;
- (void)willDismissModalViewController:(OTableViewController *)viewController;
- (void)didDismissModalViewController:(OTableViewController *)viewController;
- (void)viewWillBeDismissed;

- (NSString *)editTitleViewPrompt;
- (void)didFinishEditingInlineField:(OInputField *)inlineField;

- (BOOL)supportsPullToRefresh;
- (void)onlineStatusDidChange;
- (void)didToggleEditMode;
- (void)didResumeFromBackground;
- (void)didLogout;

@end


@interface OTableViewController : UIViewController<OTableViewController>

@property (nonatomic, readonly) OState *state;
@property (nonatomic, readonly) OEntityProxy *entity;
@property (nonatomic, readonly) OTableView *tableView;
@property (nonatomic, readonly) UIRefreshControl *refreshControl;

@property (nonatomic, assign, readonly) BOOL isModal;
@property (nonatomic, assign, readonly) BOOL isPushed;
@property (nonatomic, assign, readonly) BOOL isHidden;
@property (nonatomic, assign, readonly) BOOL wasHidden;
@property (nonatomic, assign, readonly) BOOL didResurface;
@property (nonatomic, assign, readonly) BOOL isOnline;

@property (nonatomic, assign) BOOL requiresSynchronousServerCalls;
@property (nonatomic, assign) BOOL usesTableView;
@property (nonatomic, assign) BOOL usesPlainTableViewStyle;
@property (nonatomic, assign) BOOL usesSectionIndexTitles;
@property (nonatomic, assign) BOOL cancelImpliesSkip;

@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, assign) BOOL forceDeleteCell;
@property (nonatomic, assign) BOOL presentStealthilyOnce;
@property (nonatomic, assign) BOOL needsReloadInputSection;

@property (nonatomic, assign) NSInteger selectedHeaderSegment;
@property (nonatomic, assign) UITableViewRowAnimation rowAnimation;

@property (nonatomic) id meta;
@property (nonatomic) id returnData;
@property (nonatomic) OTitleView *titleView;
@property (nonatomic) OTableViewCell *inputCell;
@property (nonatomic) OInputField *nextInputField;

@property (nonatomic, weak) OTableViewController *dismisser;

- (OTableViewController *)precedingViewController;

- (BOOL)actionIs:(id)action;
- (BOOL)targetIs:(id)target;
- (BOOL)aspectIs:(id)aspect;

- (void)setDataForInputSection;
- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (void)setData:(NSArray *)data sectionIndexLabelKey:(NSString *)sectionIndexLabelKey;
- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isBottomSectionKey:(NSInteger)sectionKey;
- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath;

- (UISegmentedControl *)titleSegmentsWithTitles:(NSArray *)segmentTitles;

- (void)sendTextToRecipients:(id)recipients;
- (void)sendEmailToRecipients:(id)toRecipients cc:(id)ccRecipients;
- (void)callRecipient:(id)recipient;

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target;
- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target meta:(id)meta;
- (void)dismissModalViewController:(OTableViewController *)viewController;

- (void)scrollToTopAndToggleEditMode;
- (void)toggleEditMode;
- (void)endEditing;

- (void)editInlineInCell:(OTableViewCell *)inlineCell;
- (void)cancelInlineEditingIfOngoing;

- (void)reloadSections;
- (void)reloadSectionWithKey:(NSInteger)sectionKey;
- (void)reloadSectionWithKey:(NSInteger)sectionKey rowAnimation:(UITableViewRowAnimation)rowAnimation;

- (void)reloadHeaderForSectionWithKey:(NSInteger)sectionKey;
- (void)reloadFooterForSectionWtihKey:(NSInteger)sectionKey;

@end
