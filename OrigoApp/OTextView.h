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
    NSUInteger numberOfLines;
}

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *placeholder;
@property (nonatomic) BOOL selected;

- (id)initWithName:(NSString *)name text:(NSString *)text delegate:(id)delegate;

- (void)emphasise;
- (void)deemphasise;
- (void)toggleEmphasis;

@end
