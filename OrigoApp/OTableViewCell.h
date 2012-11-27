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

extern CGFloat const kDefaultTableViewCellHeight;
extern CGFloat const kDefaultPadding;

extern CGFloat const kCellAnimationDuration;

@class OReplicatedEntity;
@class OTextField, OTextView, OVisualConstraints;

@interface OTableViewCell : UITableViewCell {
@private
    BOOL _selectable;
    
    OVisualConstraints *_visualConstraints;
    NSMutableDictionary *_views;
    
    id<UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
    
    void *_localContext;
}

@property (strong, nonatomic, readonly) OReplicatedEntity *entity;

+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (id)labelForKeyPath:(NSString *)keyPath;
- (id)textFieldForKeyPath:(NSString *)keyPath;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)toggleEditMode;
- (void)respondToTextViewSizeChange:(OTextView *)textView;

- (void)shakeCellShouldVibrate:(BOOL)shouldVibrate;

@end
