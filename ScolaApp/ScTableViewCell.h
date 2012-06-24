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

extern NSString * const kLabelKeyLoginLabel;
extern NSString * const kLabelKeyConfirmationLabel;

@class ScCachedEntity, ScTextField;

@interface ScTableViewCell : UITableViewCell {
@private
    BOOL isSelectable;
    
    CGFloat labelLineHeight;
    CGFloat verticalOffset;
    
    NSMutableDictionary *labels;
    NSMutableDictionary *details;
    NSMutableDictionary *textFields;
}

+ (UIColor *)backgroundColour;
+ (UIColor *)selectedBackgroundColour;
+ (UIColor *)labelColour;
+ (UIColor *)selectedLabelColour;
+ (UIFont *)labelFont;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntity:(ScCachedEntity *)entity delegate:(id)delegate;

- (ScTextField *)textFieldWithKey:(NSString *)key;

- (void)addLabel:(NSString *)label withDetail:(NSString *)detail;
- (ScTextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail;
- (ScTextField *)addEditableFieldWithOffset:(CGFloat)offset centred:(BOOL)centred;

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;
+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels;

@end
