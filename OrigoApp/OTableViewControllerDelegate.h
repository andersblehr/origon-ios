//
//  OTableViewControllerDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewControllerDelegate <NSObject>

@required
- (void)prepareState;
- (void)populateDataSource;

@optional
- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey;
- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey;
- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey;

@end
