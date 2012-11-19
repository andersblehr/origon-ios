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
    OCellTypeActivate,
    OCellTypeMemberEntity,
    OCellTypeOrigoEntity,
} OCellType;

NSString * const kReuseIdentifierDefault = @"idDefaultCell";
NSString * const kReuseIdentifierUserSignIn = @"idUserSignInCell";
NSString * const kReuseIdentifierUserActivation = @"idUserActivationCell";

NSString * const kNameSignIn = @"signIn";
NSString * const kNameAuthEmail = @"authEmail";
NSString * const kNamePassword = @"password";
NSString * const kNameActivate = @"activation";
NSString * const kNameActivationCode = @"activationCode";
NSString * const kNameRepeatPassword = @"repeatPassword";
NSString * const kNameName = @"name";
NSString * const kNameMobilePhone = @"mobilePhone";
NSString * const kNameEmail = @"email";
NSString * const kNameDateOfBirth = @"dateOfBirth";
NSString * const kNameAddress = @"address";
NSString * const kNameTelephone = @"telephone";

NSString * const kNameSuffixLabel = @"Label";
NSString * const kNameSuffixTextField = @"Field";

CGFloat const kDefaultPadding = 10.f;

static NSString * const kNameTitleBanner = @"titleBanner";
static NSString * const kNamePhotoFrame = @"photoFrame";
static NSString * const kNamePhotoPrompt = @"photoPrompt";

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

#pragma mark - Auxiliary methods

- (void)shakeWithVibration:(BOOL)doVibrate
{
    if (doVibrate) {
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


#pragma mark - Adding title banner

- (void)addTitleForName:(NSString *)name text:(NSString *)text
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_namedViews setObject:titleBannerView forKey:kNameTitleBanner];
    [_constraints addTitleConstraintsForName:name];
    
    [self addTextFieldForName:name text:text constrained:NO];
}


- (void)addTitleForName:(NSString *)name text:(NSString *)text photo:(NSData *)photo
{
    [self addTitleForName:name text:text];

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
        [_namedViews setObject:photoPrompt forKey:kNamePhotoPrompt];
    }
    
    [self.contentView addSubview:imageButton];
    [_namedViews setObject:imageButton forKey:kNamePhotoFrame];
    
    _constraints.titleBannerHasPhoto = YES;
}


#pragma mark - Adding labels

- (void)addLabelForName:(NSString *)name constrained:(BOOL)constrained
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.text = [OStrings stringForLabelWithName:name];
    label.textAlignment = constrained ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_namedViews setObject:label forKey:[name stringByAppendingString:kNameSuffixLabel]];
    
    if (constrained) {
        [_constraints addLabelConstraintsForName:name];
    }
}


#pragma mark - Adding text fields

- (void)addTextFieldForName:(NSString *)name constrained:(BOOL)constrained
{
    [self addTextFieldForName:name text:nil constrained:constrained];
}


- (void)addTextFieldForName:(NSString *)name text:(NSString *)text constrained:(BOOL)constrained
{
    if (text || [OState s].actionIsInput) {
        OTextField *textField = [[OTextField alloc] initWithName:name text:text delegate:_inputDelegate];
        
        [self.contentView addSubview:textField];
        [_namedViews setObject:textField forKey:[name stringByAppendingString:kNameSuffixTextField]];
        
        if (constrained) {
            [_constraints addTextFieldConstraintsForName:name];
        }
    }
}


- (void)addLabeledTextFieldForName:(NSString *)name text:(NSString *)text
{
    [self addLabelForName:name constrained:NO];
    [self addTextFieldForName:name text:text constrained:NO];
    
    [_constraints addLabeledTextFieldConstraintsForName:name];
}


- (void)addLabeledTextFieldForName:(NSString *)name date:(NSDate *)date
{
    [self addLabeledTextFieldForName:name text:[date localisedDateString]];
    
    if (date) {
        OTextField *textField = [_namedViews objectForKey:[name stringByAppendingString:kNameSuffixTextField]];
        ((UIDatePicker *)textField.inputView).date = date;
    }
}


#pragma mark - Adding text views

- (void)addLabeledTextViewForName:(NSString *)name text:(NSString *)text
{
    [self addLabelForName:name constrained:NO];
    
    OTextView *textView = [[OTextView alloc] initWithName:name text:text delegate:_inputDelegate];
    
    [self.contentView addSubview:textView];
    [_namedViews setObject:textView forKey:[name stringByAppendingString:kNameSuffixTextField]];
    [_constraints addLabeledTextViewConstraintsForName:name lineCount:[text lineCount]];
}


#pragma mark - Adding UI elements

- (void)addElementsForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    if (entityClass == OMember.class) {
        [self addElementsForMemberEntity:(OMember *)entity];
    } else if (entityClass == OOrigo.class) {
        [self addElementsForOrigoEntity:(OOrigo *)entity];
    }
    
    [self.contentView setNeedsUpdateConstraints];
}


- (void)addElementsForMemberEntity:(OMember *)member
{
    [self addTitleForName:kNameName text:member.name photo:member.photo];
    [self addLabeledTextFieldForName:kNameDateOfBirth date:member.dateOfBirth];
    
    if ([member hasMobilePhone] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameMobilePhone text:member.mobilePhone];
    }
    
    if ([member hasEmail] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameEmail text:member.entityId];
    }
    
    _cellType = OCellTypeMemberEntity;
    _selectable = NO;
}


- (void)addElementsForOrigoEntity:(OOrigo *)origo
{
    [self addLabeledTextViewForName:kNameAddress text:origo.address];
    
    if ([origo hasTelephone] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameTelephone text:origo.telephone];
    }
    
    _cellType = OCellTypeOrigoEntity;
    _selectable = ([OState s].actionIsList);
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
        height += [UIFont labelFont].lineHeight;
        height += 2 * [[UIFont detailFont] textFieldHeight] + 1;
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if (entityClass == OMember.class) {
        height = 3 * kDefaultPadding;
        height += [[UIFont titleFont] textFieldHeight];
        height += 3 * [[UIFont detailFont] textFieldHeight];
    } else if (entityClass == OOrigo.class) {
        height = 2 * kDefaultPadding;
        height += 3 * [[UIFont detailFont] textFieldHeight] - 2;
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
                height -= 2 * [[UIFont detailFont] textFieldHeight];
            } else if (!([member hasMobilePhone] && [member hasEmail])) {
                height -= [[UIFont detailFont] textFieldHeight];
            }
        }
    } else if ([entity isKindOfClass:OOrigo.class]) {
        OOrigo *origo = (OOrigo *)entity;
        
        if ([origo.address lineCount] > 2) {
            height += ([origo.address lineCount] - 2) * [[UIFont detailFont] textViewLineHeight];
        }
        
        if (![origo hasTelephone] && ![OState s].actionIsInput) {
            height -= [[UIFont detailFont] textFieldHeight];
        }
    }
    
    return height;
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _namedViews = [[NSMutableDictionary alloc] init];
        _constraints = [[OVisualConstraints alloc] init];
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
            
            [self addLabelForName:kNameSignIn constrained:YES];
            [self addTextFieldForName:kNameAuthEmail constrained:YES];
            [self addTextFieldForName:kNamePassword constrained:YES];
            
            [self.contentView setNeedsUpdateConstraints];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _cellType = OCellTypeActivate;
            
            [self addLabelForName:kNameActivate constrained:YES];
            [self addTextFieldForName:kNameActivationCode constrained:YES];
            [self addTextFieldForName:kNameRepeatPassword constrained:YES];
            
            [self.contentView setNeedsUpdateConstraints];
        } else {
            _cellType = OCellTypeDefault;
            _selectable = YES;
        }
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        [self addElementsForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:[entity reuseIdentifier] delegate:delegate];
    
    if (self) {
        [self addElementsForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


#pragma mark - Text field & text view retrieval

- (id)textFieldWithName:(NSString *)name
{
    return [_namedViews objectForKey:[name stringByAppendingString:kNameSuffixTextField]];
}


#pragma mark - Cell effects

- (void)adorn
{
    [self.backgroundView addDropShadowForTrailingTableViewCell];
    
    if (_cellType == OCellTypeMemberEntity) {
        [[_namedViews objectForKey:kNamePhotoFrame] addDropShadowForPhotoFrame];
    }
}


- (void)shake
{
    [self shakeWithVibration:NO];
}


- (void)shakeAndVibrateDevice
{
    [self shakeWithVibration:YES];
}


#pragma mark - Autolayout overrides

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (_cellType != OCellTypeDefault) {
        for (NSString *constraint in [_constraints constraints]) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraint options:0 metrics:nil views:_namedViews]];
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

    for (UIView *view in [_namedViews allValues]) {
        if ([view isKindOfClass:OTextField.class]) {
            ((OTextField *)view).enabled = editing;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selectable) {
        [super setSelected:selected animated:animated];
        
        for (UIView *view in [_namedViews allValues]) {
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

@end
