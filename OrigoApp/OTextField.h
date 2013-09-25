//
//  OTextField.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern CGFloat const kTextFieldBorderWidth;
extern CGFloat const kTextInsetX;
extern CGFloat const kTextInsetY;

@interface OTextField : UITextField {
@private
    NSDate *_date;
    NSString *_cachedText;

    id<OTableViewInputDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSDate *date;

@property (nonatomic) BOOL isTitleField;
@property (nonatomic) BOOL isDateField;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL hasEmphasis;

- (id)initWithKey:(NSString *)key delegate:(id)delegate;

- (BOOL)hasValue;
- (BOOL)hasValidValue;

- (id)objectValue;
- (NSString *)textValue;

- (void)prepareForInput;
- (void)indicatePendingEvent:(BOOL)isPending;
- (void)raiseGuardAgainstUnwantedAutolayoutAnimation:(BOOL)raiseGuard; // Hack!

@end
