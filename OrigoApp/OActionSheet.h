//
//  OActionSheet.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OActionSheet : UIActionSheet {
@private
    NSMutableArray *_buttonTags;
}

- (id)initWithPrompt:(NSString *)prompt delegate:(id<UIActionSheetDelegate>)delegate tag:(NSInteger)tag;

- (NSInteger)addButtonWithTitle:(NSString *)title tag:(NSInteger)tag;
- (NSInteger)tagForButtonIndex:(NSInteger)buttonIndex;

- (void)show;

@end
