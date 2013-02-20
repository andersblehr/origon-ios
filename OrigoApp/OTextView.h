//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTextViewMaximumLines;

@class OTableViewCell;

@interface OTextView : UITextView<UITextViewDelegate> {
@private
    OTableViewCell *_cell;
    UITextView *_placeholderView;
    
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSString *placeholder;

@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL hasEmphasis;

- (id)initForKey:(NSString *)key cell:(OTableViewCell *)cell delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text;
- (CGFloat)height;

- (NSString *)finalText;

@end
