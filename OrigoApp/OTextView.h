//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTextView : UITextView<UITextViewDelegate> {
@private
    BOOL _editing;
    
    UITextView *_placeholderView;
    
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *placeholder;
@property (nonatomic) BOOL selected;

+ (NSInteger)lineCountGuesstimateWithText:(NSString *)text;
+ (CGFloat)heightForLineCount:(NSUInteger)lineCount;

- (id)initWithName:(NSString *)name text:(NSString *)text delegate:(id)delegate;

- (NSInteger)lineCount;
- (NSInteger)lineCountChange;

- (void)toggleEmphasis;

@end
