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
extern CGFloat const kContentMargin;
extern CGFloat const kKeyboardHeight;


@class ScCachedEntity;
@class ScTextField;

@interface ScTableViewCell : UITableViewCell

@property (nonatomic) BOOL selectable;
@property (strong, readonly) UIButton *imageButton;

+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntity:(ScCachedEntity *)entity editing:(BOOL)editing;
+ (CGFloat)heightForEntityClass:(Class)entityClass;

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity;
- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity editing:(BOOL)editing delegate:(id)delegate;
- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate;

- (ScTextField *)textFieldWithKey:(NSString *)key;

- (void)shake;
- (void)shakeAndVibrateDevice;

@end
