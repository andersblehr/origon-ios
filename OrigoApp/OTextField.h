//
//  OTextField.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern CGFloat const kBorderWidth;
extern CGFloat const kBorderWidthNonRetina;

@interface OTextField : UITextField<OInputField> {
@private
    NSDate *_date;
    id _value;
    id _displayValue;

    id<OTableViewInputDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSArray *multiValue;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) id value;

@property (nonatomic) BOOL isTitleField;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL hasEmphasis;

- (id)initWithKey:(NSString *)key delegate:(id)delegate;

- (void)prepareForInput;
- (void)raiseGuardAgainstUnwantedAutolayoutAnimation:(BOOL)raiseGuard; // Bug workaround

@end
