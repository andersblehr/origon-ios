//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTextViewMaximumLines;

@interface OTextView : UITextView<UITextViewDelegate> {
@private
    UITextView *_placeholderView;
    
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic) NSString *keyPath;
@property (strong, nonatomic) NSString *placeholder;

@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL selected;

- (id)initForKeyPath:(NSString *)keyPath delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text;
- (CGFloat)height;

+ (NSInteger)lineCountWithText:(NSString *)text;
- (NSInteger)lineCount;
- (NSInteger)lineCountDelta;

- (void)emphasise;
- (void)deemphasise;

@end
