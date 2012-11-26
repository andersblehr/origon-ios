//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTextViewMinimumEditLines;
extern NSInteger const kTextViewMaximumEditLines;

@interface OTextView : UITextView<UITextViewDelegate> {
@private
    BOOL _editing;
    
    UITextView *_placeholderView;
    
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic) NSString *keyPath;
@property (strong, nonatomic) NSString *placeholder;
@property (nonatomic) BOOL selected;

- (id)initForKeyPath:(NSString *)keyPath delegate:(id)delegate;

+ (CGFloat)heightGuesstimateWithText:(NSString *)text;
- (CGFloat)height;

- (NSInteger)lineCount;
- (NSInteger)lineCountDelta;

- (void)toggleEmphasis;

@end
