//
//  OTableViewCell.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCell.h"

#import <AudioToolbox/AudioToolbox.h>

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UIDatePicker+ODatePickerExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTextField.h"
#import "OTextView.h"
#import "OVisualConstraints.h"

#import "OMember.h"
#import "OOrigo.h"
#import "OReplicatedEntity.h"

#import "OMember+OMemberExtensions.h"
#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

typedef enum {
    OCellTypeDefault,
    OCellTypeSignIn,
    OCellTypeActivation,
} OCellType;

NSString * const kReuseIdentifierDefault = @"idDefaultCell";
NSString * const kReuseIdentifierUserSignIn = @"idUserSignInCell";
NSString * const kReuseIdentifierUserActivation = @"idUserActivationCell";

NSString * const kElementSuffixLabel = @"Label";
NSString * const kElementSuffixTextField = @"Field";

CGFloat const kDefaultTableViewCellHeight = 45.f;
CGFloat const kDefaultPadding = 10.f;

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kKeyPathTitleBanner = @"titleBanner";
static NSString * const kKeyPathPhotoFrame = @"photoFrame";
static NSString * const kKeyPathPhotoPrompt = @"photoPrompt";

static CGFloat const kLabelDetailSpacing = 3.f;
static CGFloat const kImplicitFramePadding = 2.f;

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@interface OTableViewCell () {
@private
    OCellType _cellType;
}

@end


@implementation OTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)isListCell
{
    return [self.reuseIdentifier isEqualToString:kReuseIdentifierDefault];
}


#pragma mark - Adding elements

- (void)addTitleForKeyPath:(NSString *)keyPath hasPhoto:(BOOL)hasPhoto
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_views setObject:titleBannerView forKey:kKeyPathTitleBanner];
    [_visualConstraints addTitleConstraintsForKeyPath:keyPath];
    
    [self addTextFieldForKeyPath:keyPath constrained:NO];
    
    if (hasPhoto) {
        _visualConstraints.titleBannerHasPhoto = YES;
        
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
        NSData *photo = ((OMember *)_entity).photo;
        
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
            [_views setObject:photoPrompt forKey:kKeyPathPhotoPrompt];
        }
        
        [self.contentView addSubview:imageButton];
        [_views setObject:imageButton forKey:kKeyPathPhotoFrame];
    }
}


- (void)addLabelForKeyPath:(NSString *)keyPath constrained:(BOOL)constrained
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.hidden = YES;
    label.text = [OStrings labelForKeyPath:keyPath];
    label.textAlignment = constrained ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[keyPath stringByAppendingString:kElementSuffixLabel]];
    
    if (constrained) {
        [_visualConstraints addUnlabeledConstraintsForKeyPath:keyPath];
    }
}


- (void)addTextFieldForKeyPath:(NSString *)keyPath constrained:(BOOL)constrained
{
    OTextField *textField = [[OTextField alloc] initForKeyPath:keyPath cell:self delegate:_inputDelegate];
    
    [self.contentView addSubview:textField];
    [_views setObject:textField forKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
    
    if (constrained) {
        [_visualConstraints addUnlabeledConstraintsForKeyPath:keyPath];
    }
}


- (void)addLabeledTextFieldForKeyPath:(NSString *)keyPath
{
    [self addLabelForKeyPath:keyPath constrained:NO];
    [self addTextFieldForKeyPath:keyPath constrained:NO];
    
    [_visualConstraints addLabeledTextFieldConstraintsForKeyPath:keyPath];
}


- (void)addLabeledTextViewForKeyPath:(NSString *)keyPath
{
    [self addLabelForKeyPath:keyPath constrained:NO];
    
    OTextView *textView = [[OTextView alloc] initForKeyPath:keyPath cell:self delegate:_inputDelegate];
    
    [self.contentView addSubview:textView];
    [_views setObject:textView forKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
    [_visualConstraints addLabeledTextFieldConstraintsForKeyPath:keyPath];
}


#pragma mark - Cell composition

- (void)composeForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    self.entity = entity;
    
    _entityClass = entityClass;
    _selectable = [OState s].actionIsList;
    
    if (entityClass == OMember.class) {
        [self addTitleForKeyPath:kKeyPathName hasPhoto:YES];
        [self addLabeledTextFieldForKeyPath:kKeyPathDateOfBirth];
        [self addLabeledTextFieldForKeyPath:kKeyPathMobilePhone];
        [self addLabeledTextFieldForKeyPath:kKeyPathEmail];
    } else if (entityClass == OOrigo.class) {
        [self addLabeledTextViewForKeyPath:kKeyPathAddress];
        [self addLabeledTextFieldForKeyPath:kKeyPathTelephone];
    }
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _visualConstraints = [[OVisualConstraints alloc] initForTableViewCell:self];
        _views = [[NSMutableDictionary alloc] init];
        _inputDelegate = delegate;
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.font = [UIFont detailFont];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.textLabel.font = [UIFont titleFont];
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
            _cellType = OCellTypeSignIn;
            
            [self addLabelForKeyPath:kKeyPathSignIn constrained:YES];
            [self addTextFieldForKeyPath:kKeyPathAuthEmail constrained:YES];
            [self addTextFieldForKeyPath:kKeyPathPassword constrained:YES];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _cellType = OCellTypeActivation;
            
            [self addLabelForKeyPath:kKeyPathActivation constrained:YES];
            [self addTextFieldForKeyPath:kKeyPathActivationCode constrained:YES];
            [self addTextFieldForKeyPath:kKeyPathRepeatPassword constrained:YES];
        } else {
            _cellType = OCellTypeDefault;
            _selectable = YES;
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
    self = [self initWithReuseIdentifier:[entity reuseIdentifier] delegate:delegate];
    
    if (self) {
        [self composeForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


#pragma mark - Text field & text view retrieval

- (id)labelForKeyPath:(NSString *)keyPath
{
    return [_views objectForKey:[keyPath stringByAppendingString:kElementSuffixLabel]];
}


- (id)textFieldForKeyPath:(NSString *)keyPath
{
    return [_views objectForKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
}


#pragma mark - Adjust cell display

- (void)willAppearTrailing:(BOOL)trailing
{
    if (trailing) {
        [self.backgroundView addDropShadowForTrailingTableViewCell];
        
        if (![self isListCell]) {
            [OMeta m].participatingCell = self;
        }
    } else {
        [self.backgroundView addDropShadowForInternalTableViewCell];
    }
    
    if (_visualConstraints.titleBannerHasPhoto) {
        [[_views objectForKey:kKeyPathPhotoFrame] addDropShadowForPhotoFrame];
    }
}


- (void)toggleEditMode
{
    if ([OState s].actionIsDisplay) {
        [OState s].actionIsEdit = YES;
    } else if ([OState s].actionIsEdit) {
        [OState s].actionIsDisplay = YES;
    }

    self.editing = [OState s].actionIsEdit;
}


- (void)redrawIfNeeded
{
    if (_entity || _entityClass) {
        CGFloat desiredHeight = _entity ? [_entity cellHeight] : [_entityClass defaultCellHeight];
        
        if (self.frame.size.height != desiredHeight + kImplicitFramePadding) {
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


#pragma mark - Cell effects

- (void)shakeCellVibrateDevice:(BOOL)shouldVibrate
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


#pragma mark - Autolayout overrides

- (void)updateConstraints
{
    [self.contentView removeConstraints:[self.contentView constraints]];
    
    [super updateConstraints];
    
    NSDictionary *alignedConstraints = [_visualConstraints constraintsWithAlignmentOptions];
    
    for (NSNumber *alignmentOptions in [alignedConstraints allKeys]) {
        NSUInteger options = [alignmentOptions integerValue];
        NSArray *constraintsWithOptions = [alignedConstraints objectForKey:alignmentOptions];
        
        for (NSString *visualConstraints in constraintsWithOptions) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraints options:options metrics:nil views:_views]];
        }
    }
}


#pragma mark - Accessor overrides

- (void)setEntity:(OReplicatedEntity *)entity
{
    _entity = entity;
    
    if ([self isListCell]) {
        _selectable = YES;
        
        self.textLabel.text = [_entity listName];
        self.detailTextLabel.text = [_entity listDetails];
        self.imageView.image = [_entity listImage];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}


- (void)setSelectable:(BOOL)selectable
{
    _selectable = selectable;
    
    if (!_selectable) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}


- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    for (UIView *view in [_views allValues]) {
        if ([view isKindOfClass:OTextField.class]) {
            ((OTextField *)view).enabled = editing;
        } else if ([view isKindOfClass:OTextView.class]) {
            ((OTextView *)view).editable = editing;
            ((OTextView *)view).userInteractionEnabled = [OState s].actionIsEdit;
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


#pragma mark - OEntityObservingDelegate conformance

- (void)refresh
{
    if ([self isListCell]) {
        self.textLabel.text = [_entity listName];
        self.detailTextLabel.text = [_entity listDetails];
        self.imageView.image = [_entity listImage];
    } else {
        if ([_entity isKindOfClass:OOrigo.class]) {
            [[self textFieldForKeyPath:kKeyPathAddress] setText:((OOrigo *)_entity).address];
            [[self textFieldForKeyPath:kKeyPathTelephone] setText:((OOrigo *)_entity).telephone];
        } else if ([_entity isKindOfClass:OMember.class]) {
            [[self textFieldForKeyPath:kKeyPathName] setText:((OMember *)_entity).name];
            [[self textFieldForKeyPath:kKeyPathDateOfBirth] setText:[((OMember *)_entity).dateOfBirth localisedDateString]];
            [[self textFieldForKeyPath:kKeyPathMobilePhone] setText:((OMember *)_entity).mobilePhone];
            [[self textFieldForKeyPath:kKeyPathEmail] setText:((OMember *)_entity).email];
        }
        
        [self redrawIfNeeded];
    }
    
    if (_entityObservingDelegate) {
        [_entityObservingDelegate refresh];
    }
}

@end
