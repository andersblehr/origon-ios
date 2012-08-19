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

extern CGFloat const kScreenWidth;
extern CGFloat const kCellWidth;
extern CGFloat const kContentWidth;
extern CGFloat const kKeyboardHeight;


@class ScCachedEntity;
@class ScTextField;

@interface ScTableViewCell : UITableViewCell {
@private
    CGFloat _contentOffset;
    CGFloat _contentMargin;
    CGFloat _verticalOffset;
    
    NSMutableSet *_labels;
    NSMutableDictionary *_textFields;
    
    id<UITextFieldDelegate> _textFieldDelegate;
}

@property (nonatomic) BOOL selectable;
@property (strong, readonly) UIButton *imageButton;

+ (CGFloat)defaultHeight;
+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntityClass:(Class)entityClass;
+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity;
- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity delegate:(id)delegate;
- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate;

- (ScTextField *)textFieldWithKey:(NSString *)key;

- (void)shake;
- (void)shakeAndVibrateDevice;

@end
