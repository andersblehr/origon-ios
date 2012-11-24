//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

extern NSString * const kElementSuffixLabel;
extern NSString * const kElementSuffixTextField;

extern CGFloat const kDefaultPadding;

@class OReplicatedEntity;
@class OTextField, OTextView, OVisualConstraints;

@interface OTableViewCell : UITableViewCell {
@private
    BOOL _selectable;
    
    OReplicatedEntity *_entity;
    OVisualConstraints *_visualConstraints;
    NSMutableDictionary *_views;
    
    id<UITextFieldDelegate, UITextViewDelegate> _delegate;
    
    void *_localContext;
}

+ (CGFloat)defaultHeight;
+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntityClass:(Class)entityClass;
+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (id)labelForKeyPath:(NSString *)keyPath;
- (id)textFieldForKeyPath:(NSString *)keyPath;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)respondToTextViewSizeChange:(OTextView *)textView;

- (void)shakeCellVibrate:(BOOL)shouldVibrate;

@end
