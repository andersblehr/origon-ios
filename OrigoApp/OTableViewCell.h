//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserLogin;
extern NSString * const kReuseIdentifierUserActivation;

extern CGFloat const kScreenWidth;
extern CGFloat const kCellWidth;
extern CGFloat const kContentWidth;
extern CGFloat const kKeyboardHeight;


@class OCachedEntity;
@class OTextField;

@interface OTableViewCell : UITableViewCell {
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
+ (CGFloat)heightForEntity:(OCachedEntity *)entity;

- (OTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (OTableViewCell *)initWithEntity:(OCachedEntity *)entity;
- (OTableViewCell *)initWithEntity:(OCachedEntity *)entity delegate:(id)delegate;
- (OTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate;

- (OTextField *)textFieldWithKey:(NSString *)key;

- (void)shake;
- (void)shakeAndVibrateDevice;

@end