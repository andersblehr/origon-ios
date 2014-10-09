//
//  OTextInput.h
//  OrigoApp
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

@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL hasEmphasis;
@property (nonatomic) BOOL isTitleField;
@property (nonatomic, readonly) BOOL isEditableListCellField;
@property (nonatomic, readonly) BOOL supportsMultiLineText;
@property (nonatomic, readonly) BOOL didChange;

- (BOOL)hasMultiValue;
- (BOOL)hasValidValue;

@optional
- (CGFloat)height;
- (void)prepareForInput;

@end
