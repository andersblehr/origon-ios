//
//  ScTableViewCell.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserLogin;
extern NSString * const kReuseIdentifierUserConfirmation;

extern NSString * const kTextFieldKeyEmail;
extern NSString * const kTextFieldKeyPassword;
extern NSString * const kTextFieldKeyRegistrationCode;
extern NSString * const kTextFieldKeyRepeatPassword;

extern NSString * const kTextFieldKeyName;
extern NSString * const kTextFieldKeyMobilePhone;
extern NSString * const kTextFieldKeyDateOfBirth;

extern NSString * const kTextFieldKeyAddressLine1;
extern NSString * const kTextFieldKeyAddressLine2;
extern NSString * const kTextFieldKeyPostCodeAndCity;
extern NSString * const kTextFieldKeyLandline;

extern CGFloat const kScreenWidth;
extern CGFloat const kCellWidth;
extern CGFloat const kContentWidth;
extern CGFloat const kContentMargin;
extern CGFloat const kKeyboardHeight;

@class ScCachedEntity, ScTextField;

@interface ScTableViewCell : UITableViewCell {
@private
    BOOL isSelectable;
    
    CGFloat verticalOffset;
    
    NSMutableDictionary *labels;
    NSMutableDictionary *details;
    NSMutableDictionary *textFields;
}

+ (UIColor *)backgroundColour;
+ (UIColor *)selectedBackgroundColour;
+ (UIColor *)labelColour;
+ (UIColor *)selectedLabelColour;

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;
+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntity:(ScCachedEntity *)entity editable:(BOOL)editable delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;

- (ScTextField *)textFieldWithKey:(NSString *)key;

- (void)shake;

@end
