//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSInteger const kTextViewMaximumLines;

@interface OTextView : UITextView<OInputField, UITextViewDelegate> {
@private
    OTableViewCellBlueprint *_blueprint;
    CGFloat _textWidth;
    
    UITextView *_placeholderView;
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSString *placeholder;

@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL hasEmphasis;

- (id)initWithKey:(NSString *)key blueprint:(OTableViewCellBlueprint *)blueprint delegate:(id)delegate;

+ (CGFloat)labelWidthWithBlueprint:(OTableViewCellBlueprint *)blueprint;
+ (CGFloat)heightWithText:(NSString *)text blueprint:(OTableViewCellBlueprint *)blueprint;
- (CGFloat)height;

@end
