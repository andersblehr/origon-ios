//
//  OTextInput.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTextInput <UITextInput>

@required
@property (strong, nonatomic) id value;
@property (strong, nonatomic) NSString *placeholder;
@property (strong, nonatomic, readonly) NSString *text;
@property (strong, nonatomic, readonly) NSString *key;

@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) BOOL hasEmphasis;
@property (nonatomic, assign) BOOL isTitleField;
@property (nonatomic, assign, readonly) BOOL isInlineField;
@property (nonatomic, assign, readonly) BOOL supportsMultiLineText;
@property (nonatomic, assign, readonly) BOOL didChange;

- (BOOL)hasMultiValue;
- (BOOL)hasValidValue;

@optional
- (CGFloat)height;
- (void)prepareForInput;

@end
