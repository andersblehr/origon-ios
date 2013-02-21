//
//  OTableViewCell.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCell.h"

#import <AudioToolbox/AudioToolbox.h>

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIColor+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTextField.h"
#import "OTextView.h"
#import "OTableViewCellComposer.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OTableViewController.h"

NSString * const kReuseIdentifierDefault = @"idDefaultCell";
NSString * const kReuseIdentifierUserSignIn = @"idUserSignInCell";
NSString * const kReuseIdentifierUserActivation = @"idUserActivationCell";

NSString * const kViewKeySuffixLabel = @"Label";
NSString * const kViewKeySuffixTextField = @"Field";

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kViewKeyTitleBanner = @"titleBanner";
static NSString * const kViewKeyPhotoFrame = @"photoFrame";
static NSString * const kViewKeyPhotoPrompt = @"photoPrompt";

static CGFloat const kLabelDetailSpacing = 3.f;
static CGFloat const kImplicitFramePadding = 2.f;

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@interface OTableViewCell ()

@property (strong, nonatomic) OState *localState;

@end


@implementation OTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)shouldComposeForReuseIdentifier:(NSString *)reuseIdentifier
{
    BOOL userIsSigningIn = [reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn];
    BOOL userIsActivating = [reuseIdentifier isEqualToString:kReuseIdentifierUserActivation];
    
    return (userIsSigningIn || userIsActivating);
}


- (BOOL)isListCell
{
    return [self.reuseIdentifier isEqualToString:kReuseIdentifierDefault];
}


- (void)populateListCell
{
    self.textLabel.text = [_listCellDelegate cellTextForIndexPath:_indexPath];
    
    if ([_listCellDelegate respondsToSelector:@selector(cellDetailTextForIndexPath:)]) {
        self.detailTextLabel.text = [_listCellDelegate cellDetailTextForIndexPath:_indexPath];
    }
    
    if ([_listCellDelegate respondsToSelector:@selector(cellImageForIndexPath:)]) {
        self.imageView.image = [_listCellDelegate cellImageForIndexPath:_indexPath];
    }
}


#pragma mark - Adding elements

- (void)addTitleFieldIfNeeded
{
    if (_composer.titleKey) {
        UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
        titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
        [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.contentView addSubview:titleBannerView];
        [_views setObject:titleBannerView forKey:kViewKeyTitleBanner];
        
        [self addTextFieldForKey:_composer.titleKey];
        
        if (_composer.titleBannerHasPhoto) {
            UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
            NSData *photo = [_entity asMember].photo;
            
            if (photo) {
                [imageButton setImage:[UIImage imageWithData:photo] forState:UIControlStateNormal];
            } else {
                imageButton.backgroundColor = [UIColor whiteColor];
                [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
                
                UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
                photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
                photoPrompt.font = [UIFont labelFont];
                photoPrompt.text = [OStrings stringForKey:strPlaceholderPhoto];
                photoPrompt.textAlignment = NSTextAlignmentCenter;
                photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
                [photoPrompt setTranslatesAutoresizingMaskIntoConstraints:NO];
                
                [imageButton addSubview:photoPrompt];
                [_views setObject:photoPrompt forKey:kViewKeyPhotoPrompt];
            }
            
            [self.contentView addSubview:imageButton];
            [_views setObject:imageButton forKey:kViewKeyPhotoFrame];
        }
    }
}


- (void)addLabelForKey:(NSString *)key centred:(BOOL)centred
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.hidden = YES;
    label.text = [OStrings labelForKey:key];
    label.textAlignment = centred ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (void)addTextFieldForKey:(NSString *)key
{
    OTextField *textField = [[OTextField alloc] initForKey:key cell:self delegate:_inputDelegate];
    
    [self.contentView addSubview:textField];
    [_views setObject:textField forKey:[key stringByAppendingString:kViewKeySuffixTextField]];
}


- (void)addTextViewForKey:(NSString *)key
{
    OTextView *textView = [[OTextView alloc] initForKey:key cell:self delegate:_inputDelegate];
    
    [self.contentView addSubview:textView];
    [_views setObject:textView forKey:[key stringByAppendingString:kViewKeySuffixTextField]];
}


#pragma mark - Cell composition

- (void)composeForReuseIdentifier:(NSString *)reuseIdentifier
{
    [_composer composeForReuseIdentifier:reuseIdentifier];
    
    [self addLabelForKey:_composer.titleKey centred:YES];
    
    for (NSString *detailKey in _composer.detailKeys) {
        [self addTextFieldForKey:detailKey];
    }
}


- (void)composeForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    _entityClass = entityClass;
    
    self.entity = entity;
    self.editing = !_selectable;
    
    [_composer composeForEntityClass:entityClass entity:entity];
    
    [self addTitleFieldIfNeeded];
    
    for (NSString *detailKey in _composer.detailKeys) {
        [self addLabelForKey:detailKey centred:NO];
        
        if ([OTableViewCellComposer requiresTextViewForKey:detailKey]) {
            [self addTextViewForKey:detailKey];
        } else {
            [self addTextFieldForKey:detailKey];
        }
    }
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.font = [UIFont detailFont];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.textLabel.font = [UIFont titleFont];

        if ([self isListCell]) {
            _listCellDelegate = delegate;
            _selectable = YES;
        } else {
            _inputDelegate = delegate;
            _selectable = self.localState.actionIsList;
            _composer = [[OTableViewCellComposer alloc] initForCell:self];
            _views = [[NSMutableDictionary alloc] init];
            
            if ([self shouldComposeForReuseIdentifier:reuseIdentifier]) {
                [self composeForReuseIdentifier:reuseIdentifier];
            }
        }
        
        if (_selectable) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        [self composeForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:entity.entityId delegate:delegate];
    
    if (self) {
        [self composeForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


#pragma mark - Text field & text view access

- (BOOL)isTitleKey:(NSString *)key
{
    return [key isEqualToString:_composer.titleKey];
}


- (id)labelForKey:(NSString *)key
{
    return [_views objectForKey:[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (id)textFieldForKey:(NSString *)key
{
    return [_views objectForKey:[key stringByAppendingString:kViewKeySuffixTextField]];
}


- (id)nextInputFieldFromTextField:(id)textField
{
    NSArray *elementKeys = _composer.allKeys;
    NSInteger indexOfTextField = textField ? [elementKeys indexOfObject:[textField key]] : -1;
    NSString *inputFieldKey = nil;
    UIView *inputField = nil;
    
    BOOL inputFieldIsEditable = NO;
    
    for (int i = indexOfTextField + 1; ((i < [elementKeys count]) && !inputFieldIsEditable); i++) {
        inputFieldKey = [elementKeys[i] stringByAppendingString:kViewKeySuffixTextField];
        inputField = _views[inputFieldKey];
        
        if ([inputField isKindOfClass:OTextField.class]) {
            inputFieldIsEditable = ((OTextField *)inputField).enabled;
        } else if ([inputField isKindOfClass:OTextView.class]) {
            inputFieldIsEditable = ((OTextView *)inputField).editable;
        }
    }
    
    return inputFieldIsEditable ? inputField : nil;
}


#pragma mark - Cell display & effects

- (void)willAppearTrailing:(BOOL)trailing
{
    if (trailing) {
        [self.backgroundView addDropShadowForTrailingTableViewCell];
    } else {
        [self.backgroundView addDropShadowForInternalTableViewCell];
    }
    
    if (_composer.titleBannerHasPhoto) {
        [[_views objectForKey:kViewKeyPhotoFrame] addDropShadowForPhotoFrame];
    }
}


- (void)toggleEditMode
{
    [self.localState toggleEditState];
    
    self.editing = (self.localState.actionIsEdit || _editable);
}


- (void)redrawIfNeeded
{
    if (_entity || _entityClass) {
        CGFloat desiredHeight = [OTableViewCellComposer cell:self heightForEntityClass:_entityClass entity:_entity];
        
        if (abs(self.frame.size.height - (desiredHeight + kImplicitFramePadding)) > 0.5f) {
            [UIView animateWithDuration:kCellAnimationDuration animations:^{
                [(UITableView *)self.superview beginUpdates];
                CGRect frame = self.frame;
                frame.size.height = desiredHeight + kImplicitFramePadding;
                self.frame = frame;
                [(UITableView *)self.superview endUpdates];
                
                [self setNeedsUpdateConstraints];
                [self layoutIfNeeded];
                [self.backgroundView redrawDropShadow];
            }];
        }
    }
}


- (void)shakeCellShouldVibrate:(BOOL)shouldVibrate
{
    if (shouldVibrate) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    
    CGAffineTransform translateRight = CGAffineTransformTranslate(CGAffineTransformIdentity, kShakeTranslationX, kShakeTranslationY);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -kShakeTranslationX, kShakeTranslationY);
    
    self.transform = translateLeft;
    
    [UIView animateWithDuration:kShakeDuration delay:kShakeDelay options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:kShakeRepeatCount];
        
        self.transform = translateRight;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:kShakeDuration delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:NULL];
    }];
}


#pragma mark - UIView overrides

- (void)updateConstraints
{
    [super updateConstraints];

    if (![self isListCell]) {
        [self.contentView removeConstraints:[self.contentView constraints]];
        
        NSDictionary *alignedConstraints = [_composer constraintsWithAlignmentOptions];
        
        for (NSNumber *alignmentOptions in [alignedConstraints allKeys]) {
            NSUInteger options = [alignmentOptions integerValue];
            NSArray *constraintsWithOptions = [alignedConstraints objectForKey:alignmentOptions];
            
            for (NSString *visualConstraints in constraintsWithOptions) {
                [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraints options:options metrics:nil views:_views]];
            }
        }
    }
}


#pragma mark - UITableViewCell overrides

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    
    for (UIView *view in [_views allValues]) {
        if ([view isKindOfClass:OTextField.class]) {
            ((OTextField *)view).enabled = editing;
        } else if ([view isKindOfClass:OTextView.class]) {
            ((OTextView *)view).editable = editing;
            ((OTextView *)view).userInteractionEnabled = editing;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selectable) {
        [super setSelected:selected animated:animated];
        
        for (UIView *view in [_views allValues]) {
            if ([view isKindOfClass:UILabel.class]) {
                if (selected) {
                    ((UILabel *)view).textColor = [UIColor selectedLabelTextColor];
                } else {
                    ((UILabel *)view).textColor = [UIColor labelTextColor];
                }
            } else if ([view isKindOfClass:OTextField.class]) {
                ((OTextField *)view).selected = selected;
            } else if ([view isKindOfClass:OTextView.class]) {
                ((OTextView *)view).selected = selected;
            }
        }
    }
}


#pragma mark - Custom accessors

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    _indexPath = indexPath;

    if ([self isListCell]) {
        [self populateListCell];
    }
}


- (OState *)localState
{
    if (!_localState) {
        _localState = ((OTableViewController *)((UITableView *)self.superview).delegate).state;
    }
    
    return _localState ? _localState : [OState s];
}


- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    self.editing = editable;
}


#pragma mark - OEntityObservingDelegate conformance

- (void)reloadEntity
{
    if ([self isListCell]) {
        [self populateListCell];
    } else {
        for (NSString *detailKey in _composer.detailKeys) {
            id value = [_entity valueForKey:detailKey];
            
            if (value) {
                if ([value isKindOfClass:NSString.class]) {
                    [[self textFieldForKey:detailKey] setText:value];
                } else if ([value isKindOfClass:NSDate.class]) {
                    [[self textFieldForKey:detailKey] setDate:value];
                }
            }
        }
        
        [self redrawIfNeeded];
    }
    
    if (_observer) {
        [_observer reloadEntity];
    }
}

@end
