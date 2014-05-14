//
//  OActionSheet.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OActionSheet : UIActionSheet

- (instancetype)initWithPrompt:(NSString *)prompt delegate:(id<UIActionSheetDelegate>)delegate tag:(NSInteger)tag;

- (NSInteger)addButtonWithTitle:(NSString *)title tag:(NSInteger)tag;
- (NSInteger)tagForButtonIndex:(NSInteger)buttonIndex;

- (void)show;

@end
