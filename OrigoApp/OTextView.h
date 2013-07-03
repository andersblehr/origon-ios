//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTextViewMaximumLines;

@class OTableViewCell, OState;

@interface OTextView : UITextView<UITextViewDelegate> {
@private
    OState *_state;
    UITextView *_placeholderView;
    
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSString *placeholder;

@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL hasEmphasis;

- (id)initWithKey:(NSString *)key delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text;
- (CGFloat)height;

- (BOOL)isDateField;
- (BOOL)hasValue;
- (BOOL)hasValidValue;

- (id)objectValue;
- (NSString *)textValue;

@end
