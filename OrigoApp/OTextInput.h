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
@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) id value;

@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL hasEmphasis;
@property (nonatomic, readonly) BOOL supportsMultiLineText;

- (BOOL)hasMultiValue;
- (BOOL)hasValidValue;

@optional
@property (nonatomic) BOOL isTitleField;

- (CGFloat)height;
- (void)prepareForInput;

- (void)protectAgainstUnwantedAutolayoutAnimation:(BOOL)shouldProtect; // Bug workaround

@end
