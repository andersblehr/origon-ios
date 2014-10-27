//
//  OTableView.h
//  OrigoApp
//
//  Created by Anders Blehr on 23/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kSectionIndexMinimumDisplayRowCount;

@interface OTableView : UITableView

- (id)listCellWithStyle:(UITableViewCellStyle)style data:(id)data delegate:(id)delegate;
- (id)editableListCellWithData:(id)data delegate:(id)delegate;
- (id)inputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate;
- (id)inputCellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;

- (void)setTopContentInset:(CGFloat)topContentInset;
- (void)setBottomContentInset:(CGFloat)bottomContentInset;

- (void)dim;
- (void)undim;

@end
