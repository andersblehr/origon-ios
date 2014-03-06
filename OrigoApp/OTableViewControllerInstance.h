//
//  OTableViewControllerInstance.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OTableViewControllerInstance <NSObject>

@required
- (void)initialiseState;
- (void)initialiseData;

@optional
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

- (BOOL)serverRequestsAreSynchronous;
- (void)didResumeFromBackground;

@end
