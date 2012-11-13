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

extern CGFloat const kDefaultPadding;

@class OReplicatedEntity;
@class OTextField;

@interface OTableViewCell : UITableViewCell {
@private
    CGFloat _contentOffset;
    CGFloat _contentMargin;
    CGFloat _verticalOffset;
    
    NSMutableDictionary *_namedViews;
    
    id<UITextFieldDelegate> _textFieldDelegate;
}

@property (nonatomic) BOOL selectable;

+ (CGFloat)defaultHeight;
+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntityClass:(Class)entityClass;
+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (OTextField *)textFieldWithName:(NSString *)key;

- (void)shake;
- (void)shakeAndVibrateDevice;

@end
