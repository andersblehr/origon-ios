//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSInteger const kTextViewMaximumLines;

@interface OTextView : UITextView<OTextInput, UITextViewDelegate> {
@private
    OTableViewCellBlueprint *_blueprint;
    CGFloat _textWidth;
    
    UITextView *_placeholderView;
    NSString *_placeholder;
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

- (id)initWithKey:(NSString *)key blueprint:(OTableViewCellBlueprint *)blueprint delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text blueprint:(OTableViewCellBlueprint *)blueprint;

@end
