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
    OCellTypeMemberEntity,
    OCellTypeOrigoEntity,
} OCellType;

NSString * const kReuseIdentifierDefault = @"idDefaultCell";
NSString * const kReuseIdentifierUserSignIn = @"idUserSignInCell";
NSString * const kReuseIdentifierUserActivation = @"idUserActivationCell";

NSString * const kElementSuffixLabel = @"Label";
NSString * const kElementSuffixTextField = @"Field";

CGFloat const kDefaultPadding = 10.f;

static NSString * const kKeyPathTitleBanner = @"titleBanner";
static NSString * const kKeyPathPhotoFrame = @"photoFrame";
static NSString * const kKeyPathPhotoPrompt = @"photoPrompt";

static CGFloat const kDefaultCellHeight = 45.f;
static CGFloat const kLabelDetailSpacing = 3.f;

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

#pragma mark - Adding UI elements

- (void)addTitleForKeyPath:(NSString *)keyPath text:(NSString *)text
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_views setObject:titleBannerView forKey:kKeyPathTitleBanner];
    [_visualConstraints addTitleConstraintsForKeyPath:keyPath];
    
    [self addTextFieldForKeyPath:keyPath text:text constrained:NO];
}


- (void)addTitleForKeyPath:(NSString *)keyPath text:(NSString *)text photo:(NSData *)photo
{
    [self addTitleForKeyPath:keyPath text:text];
    
    _visualConstraints.titleBannerHasPhoto = YES;

    UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
    
    if (photo) {
        [imageButton setImage:[UIImage imageWithData:photo] forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor whiteColor];
        [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont labelFont];
        photoPrompt.text = [OStrings stringForKey:strPromptPhoto];
        photoPrompt.textAlignment = NSTextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
        [photoPrompt setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [imageButton addSubview:photoPrompt];
        [_views setObject:photoPrompt forKey:kKeyPathPhotoPrompt];
    }
    
    [self.contentView addSubview:imageButton];
    [_views setObject:imageButton forKey:kKeyPathPhotoFrame];
}


- (void)addLabelForKeyPath:(NSString *)keyPath constrained:(BOOL)constrained
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.text = [OStrings stringForLabelWithKeyPath:keyPath];
    label.textAlignment = constrained ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[keyPath stringByAppendingString:kElementSuffixLabel]];
    
    if (constrained) {
        [_visualConstraints addLabelConstraintsForKeyPath:keyPath];
    }
}


- (void)addTextFieldForKeyPath:(NSString *)keyPath constrained:(BOOL)constrained
{
    [self addTextFieldForKeyPath:keyPath text:nil constrained:constrained];
}


- (void)addTextFieldForKeyPath:(NSString *)keyPath text:(NSString *)text constrained:(BOOL)constrained
{
    OTextField *textField = [[OTextField alloc] initForKeyPath:keyPath text:text delegate:_delegate];
    
    [self.contentView addSubview:textField];
    [_views setObject:textField forKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
    
    if (constrained) {
        [_visualConstraints addUnlabeledTextFieldConstraintsForKeyPath:keyPath];
    }
    
    [[OMeta m] addObserver:self ofEntity:_entity forKeyPath:keyPath context:_localContext];
}


- (void)addLabeledTextFieldForKeyPath:(NSString *)keyPath text:(NSString *)text visible:(BOOL)visible
{
    [self addLabelForKeyPath:keyPath constrained:NO];
    [self addTextFieldForKeyPath:keyPath text:text constrained:NO];
    
    [_visualConstraints addLabeledTextFieldConstraintsForKeyPath:keyPath visible:visible];
}


- (void)addLabeledTextFieldForKeyPath:(NSString *)keyPath date:(NSDate *)date
{
    [self addLabeledTextFieldForKeyPath:keyPath text:[date localisedDateString] visible:YES];
    
    if (date) {
        OTextField *textField = [_views objectForKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
        ((UIDatePicker *)textField.inputView).date = date;
    }
}


- (void)addLabeledTextViewForKeyPath:(NSString *)keyPath text:(NSString *)text
{
    [self addLabelForKeyPath:keyPath constrained:NO];
    
    OTextView *textView = [[OTextView alloc] initForKeyPath:keyPath text:text delegate:_delegate];
    
    [self.contentView addSubview:textView];
    [_views setObject:textView forKey:[keyPath stringByAppendingString:kElementSuffixTextField]];
    [_visualConstraints addLabeledTextViewConstraintsForKeyPath:keyPath lineCount:[textView lineCount]];
    
    [[OMeta m] addObserver:self ofEntity:_entity forKeyPath:keyPath context:_localContext];
}


#pragma mark - Cell composition

- (void)composeForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    _entity = entity;
    _localContext = &_localContext;
    
    if (entityClass == OMember.class) {
        [self composeForMemberEntity:(OMember *)entity];
    } else if (entityClass == OOrigo.class) {
        [self composeForOrigoEntity:(OOrigo *)entity];
    }
    
    [self.contentView setNeedsUpdateConstraints];
}


- (void)composeForMemberEntity:(OMember *)member
{
    BOOL mobilePhoneFieldIsVisible = ([member hasMobilePhone] || [OState s].actionIsInput);
    BOOL emailFieldIsVisible = ([member hasEmail] || [OState s].actionIsInput);
    
    [self addTitleForKeyPath:kKeyPathName text:member.name photo:member.photo];
    [self addLabeledTextFieldForKeyPath:kKeyPathDateOfBirth date:member.dateOfBirth];
    [self addLabeledTextFieldForKeyPath:kKeyPathMobilePhone text:member.mobilePhone visible:mobilePhoneFieldIsVisible];
    [self addLabeledTextFieldForKeyPath:kKeyPathEmail text:member.entityId visible:emailFieldIsVisible];
    
    _cellType = OCellTypeMemberEntity;
    _selectable = NO;
}


- (void)composeForOrigoEntity:(OOrigo *)origo
{
    BOOL telephoneFieldIsVisible = ([origo hasTelephone] || [OState s].actionIsInput);
    
    [self addLabeledTextViewForKeyPath:kKeyPathAddress text:origo.address];
    [self addLabeledTextFieldForKeyPath:kKeyPathTelephone text:origo.telephone visible:telephoneFieldIsVisible];
    
    _cellType = OCellTypeOrigoEntity;
    _selectable = [OState s].actionIsList;
}


#pragma mark - Cell height

+ (CGFloat)defaultHeight
{
    return kDefaultCellHeight;
}


+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn] ||
        [reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
        height = 3 * kDefaultPadding;
        height += 3 * [UIFont detailFieldHeight] + 1;
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if (entityClass == OMember.class) {
        height = 3 * kDefaultPadding;
        height += [UIFont titleFieldHeight];
        height += 3 * [UIFont detailFieldHeight];
    } else if (entityClass == OOrigo.class) {
        height = 2 * kDefaultPadding;
        height += [UIFont detailFieldHeight];
        height += [OTextView heightForLineCount:kTextViewMinimumEditLines];
    }
    
    return height;
}


+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity
{
    CGFloat height = [OTableViewCell heightForEntityClass:entity.class];

    if ([entity isKindOfClass:OMember.class]) {
        if (![OState s].actionIsInput) {
            OMember *member = (OMember *)entity;
            
            if (![member hasMobilePhone] && ![member hasEmail]) {
                height -= 2 * [UIFont detailFieldHeight];
            } else if (!([member hasMobilePhone] && [member hasEmail])) {
                height -= [UIFont detailFieldHeight];
            }
        }
    } else if ([entity isKindOfClass:OOrigo.class]) {
        OOrigo *origo = (OOrigo *)entity;
        
        NSInteger addressViewLineCount = [OTextView lineCountGuesstimateWithText:origo.address];
        height += (addressViewLineCount - kTextViewMinimumEditLines) * [UIFont detailLineHeight];
        
        if (![origo hasTelephone] && ![OState s].actionIsInput) {
            height -= [UIFont detailFieldHeight];
        }
    }
    
    return height;
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _visualConstraints = [[OVisualConstraints alloc] initForTableViewCell:self];
        _views = [[NSMutableDictionary alloc] init];
        _delegate = delegate;
        
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
    } else {
        [self.backgroundView addDropShadowForInternalTableViewCell];
    }
    
    if (_cellType == OCellTypeMemberEntity) {
        [[_views objectForKey:kKeyPathPhotoFrame] addDropShadowForPhotoFrame];
    }
}


- (void)respondToTextViewSizeChange:(OTextView *)textView
{
    NSInteger lineCountDelta = [textView lineCountDelta];
    
    if (lineCountDelta) {
        [self.backgroundView removeDropShadow];
        CGRect frame = self.frame;
        frame.size.height += lineCountDelta * [UIFont detailLineHeight];
        self.frame = frame;
        [self.backgroundView addDropShadowForTrailingTableViewCell];
        
        [_visualConstraints updateLabeledTextViewConstraintsForKeyPath:textView.keyPath lineCount:[textView lineCount]];
        
        [self.contentView removeConstraints:[self.contentView constraints]];
        [self setNeedsUpdateConstraints];
    }
}


#pragma mark - Cell effects

- (void)shakeCellVibrate:(BOOL)shouldVibrate
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


#pragma mark - NSKeyValueObserving conformance

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == _localContext) {
        [[self textFieldForKeyPath:keyPath] setText:[change objectForKey:NSKeyValueChangeNewKey]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Removing entity KVO observers

- (void)dealloc
{
    [[OMeta m] removeEntityObserversInContext:_localContext];
}

@end
