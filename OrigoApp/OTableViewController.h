//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTableViewController<UITableViewDataSource, UITableViewDelegate>

@required
@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic) id target;
@property (strong, nonatomic) id returnData;

- (void)loadState;
- (void)loadData;

@optional
- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (id)defaultTarget;
- (id)destinationMetaForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)destinationAspectForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)reuseIdentifierForInputSection;
- (NSArray *)toolbarButtons;

- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey;
- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey;

- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey;
- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2;
- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey;

- (void)willDisplayInputCell:(OTableViewCell *)inputCell;
- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController;
- (void)willDismissModalViewController:(OTableViewController *)viewController;
- (void)didDismissModalViewController:(OTableViewController *)viewController;

- (void)titleWillChange:(NSString *)newTitle;
- (void)didResumeFromBackground;
- (void)didSignOut;

@end


@interface OTableViewController : UITableViewController<OTableViewController, OConnectionDelegate>

@property (nonatomic, readonly) OState *state;
@property (nonatomic, readonly) OEntityProxy *entity;

@property (nonatomic, assign, readonly) BOOL isModal;
@property (nonatomic, assign, readonly) BOOL isPushed;
@property (nonatomic, assign, readonly) BOOL isHidden;
@property (nonatomic, assign, readonly) BOOL wasHidden;
@property (nonatomic, assign, readonly) BOOL didResurface;

@property (nonatomic, assign) BOOL requiresSynchronousServerCalls;
@property (nonatomic, assign) BOOL usesPlainTableViewStyle;
@property (nonatomic, assign) BOOL usesSectionIndexTitles;
@property (nonatomic, assign) BOOL presentStealthilyOnce;
@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, assign) BOOL cancelImpliesSkip;
@property (nonatomic, assign) UITableViewRowAnimation rowAnimation;

@property (nonatomic) id meta;
@property (nonatomic) id returnData;
@property (nonatomic) OTableViewCell *inputCell;
@property (nonatomic) OInputField *nextInputField;

@property (nonatomic, weak) OTableViewController *dismisser;
@property (nonatomic, weak) id<OEntityObserver> observer;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)aspectIs:(NSString *)aspect;

- (void)setDataForInputSection;
- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (void)setData:(NSArray *)data sectionIndexLabelKey:(NSString *)sectionIndexLabelKey;
- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isBottomSectionKey:(NSInteger)sectionKey;
- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath;

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target;
- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target meta:(id)meta;
- (void)dismissModalViewController:(OTableViewController *)viewController;

- (void)scrollToTopAndToggleEditMode;
- (void)toggleEditMode;
- (void)endEditing;

- (void)setEditableTitle:(NSString *)title placeholder:(NSString *)placeholder;
- (void)setSubtitle:(NSString *)subtitle;
- (UISegmentedControl *)setTitleSegments:(NSArray *)segments;

- (void)reloadSections;
- (void)reloadSectionWithKey:(NSInteger)sectionKey;

@end
