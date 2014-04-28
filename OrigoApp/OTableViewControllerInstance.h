//
//  OTableViewControllerInstance.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewControllerInstance <NSObject>

@required
- (void)loadState;
- (void)loadData;

@optional
- (id)defaultTarget;
- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)toolbarButtons;

- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey;

- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController;
- (void)willDismissModalViewController:(OTableViewController *)viewController;
- (void)didDismissModalViewController:(OTableViewController *)viewController;

- (void)didResumeFromBackground;

@end
