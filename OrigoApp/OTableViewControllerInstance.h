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
- (void)initialiseDataSource;

@optional
- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)toolbarButtons;

- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didResumeFromBackground;

@end
