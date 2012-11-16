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

CGFloat const kDefaultPadding = 10.f;

static NSString * const kNameTitleBanner = @"titleBanner";
static NSString * const kNamePhotoFrame = @"photoFrame";

static NSString * const kNameSuffixLabel = @"Label";
static NSString * const kNameSuffixTextField = @"Field";
static NSString * const kNameSuffixTextView = @"View";

static CGFloat const kLineSpacing = 5.f;
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


#pragma mark - Addint title & photo

- (void)addTitleBanner
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_namedViews setObject:titleBannerView forKey:kNameTitleBanner];
}


- (void)addPhotoFrame:(UIImage *)photo
{
    UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
    
    if (photo) {
        [imageButton setImage:photo forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor whiteColor];
        [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, 3.f, 3.f)];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [OStrings stringForKey:strPromptPhoto];
        photoPrompt.textAlignment = NSTextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
        [photoPrompt setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [imageButton addSubview:photoPrompt];
    }
    
    [imageButton addDropShadowForPhotoFrame];
    
    [self.contentView addSubview:imageButton];
    [_namedViews setObject:imageButton forKey:kNamePhotoFrame];
}


#pragma mark - Adding labels

- (void)addLabelForName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.text = [OStrings stringForLabelWithName:name];
    label.textAlignment = ([name isEqualToString:kNameSignIn] || [name isEqualToString:kNameActivate]) ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_namedViews setObject:label forKey:[name stringByAppendingString:kNameSuffixLabel]];
}


#pragma mark - Adding text fields

- (void)addTextFieldForName:(NSString *)name
{
    [self addTextFieldForName:name text:nil];
}


- (void)addTextFieldForName:(NSString *)name text:(NSString *)text
{
    if (text || [OState s].actionIsInput) {
        OTextField *textField = [[OTextField alloc] initWithName:name text:text delegate:_inputDelegate];
        
        [self.contentView addSubview:textField];
        [_namedViews setObject:textField forKey:[name stringByAppendingString:kNameSuffixTextField]];
    }
}


#pragma mark - Adding labeled text fields

- (void)addLabeledTextFieldForName:(NSString *)name
{
    [self addLabeledTextFieldForName:name text:nil];
}


- (void)addLabeledTextFieldForName:(NSString *)name text:(NSString *)text
{
    [self addLabelForName:name];
    [self addTextFieldForName:name text:text];
}


- (void)addLabeledTextFieldForName:(NSString *)name date:(NSDate *)date
{
    [self addLabeledTextFieldForName:name text:[date localisedDateString]];
    
    if (date) {
        OTextField *textField = [_namedViews objectForKey:[name stringByAppendingString:kNameSuffixTextField]];
        ((UIDatePicker *)textField.inputView).date = date;
    }
}


#pragma mark - Adding labeled text views

- (void)addLabeledTextViewForName:(NSString *)name text:(NSString *)text
{
    [self addLabelForName:name];
    
    OTextView *textView = [[OTextView alloc] initWithName:name text:text delegate:_inputDelegate];
    
    [self.contentView addSubview:textView];
    [_namedViews setObject:textView forKey:[name stringByAppendingString:kNameSuffixTextView]];
}


#pragma mark - Cell composition

- (void)layoutForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    if (entityClass == OMember.class) {
        [self layoutForMemberEntity:(OMember *)entity];
    } else if (entityClass == OOrigo.class) {
        [self layoutForOrigoEntity:(OOrigo *)entity];
    }
}


- (void)layoutForMemberEntity:(OMember *)member
{
    [self addTitleBanner];
    [self addTextFieldForName:kNameName text:member.name];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    
    if ([member hasMobilePhone] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameMobilePhone text:member.mobilePhone];
    }
    
    if ([member hasEmail] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameEmail text:member.entityId];
    }
    
    [self addLabeledTextFieldForName:kNameDateOfBirth date:member.dateOfBirth];
    
    _cellType = OCellTypeMemberEntity;
    _selectable = NO;
    
    [self.contentView setNeedsUpdateConstraints];
}


- (void)layoutForOrigoEntity:(OOrigo *)origo
{
    [self addLabeledTextViewForName:kNameAddress text:origo.address];
    
    //if ([origo hasTelephone] || [OState s].actionIsInput) {
        [self addLabeledTextFieldForName:kNameTelephone text:origo.telephone];
    //}
    
    _cellType = OCellTypeOrigoEntity;
    _selectable = ([OState s].actionIsList);
    
    [self.contentView setNeedsUpdateConstraints];
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
        height = kDefaultPadding;
        height += [UIFont labelFont].lineHeight;
        height += 2.f * kLineSpacing;
        height += 2.f * [UIFont detailFont].lineHeight;
        height += 2.f * kDefaultPadding;
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if (entityClass == OMember.class) {
        height = 2 * kDefaultPadding + 2 * kLineSpacing;
        height += [UIFont titleFont].lineHeight;
        height += 3 * [UIFont detailFont].lineHeight;
        height += 2 * kLineSpacing;
    } else if (entityClass == OOrigo.class) {
        height = 2 * kDefaultPadding + 2 * kLineSpacing;
        height += 3 * [UIFont detailFont].lineHeight;
    }
    
    return height;
}


+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity
{
    CGFloat height = [OTableViewCell heightForEntityClass:entity.class];
    
    if ([entity isKindOfClass:OOrigo.class]) {
        OOrigo *origo = (OOrigo *)entity;
        
        if (![origo hasTelephone] && ![OState s].actionIsInput) {
            height -= [UIFont detailFont].lineHeight;
            height -= kLineSpacing;
        }
    }
    
    return height;
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _inputDelegate = delegate;
        _namedViews = [[NSMutableDictionary alloc] init];
        
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
            
            [self addLabelForName:kNameSignIn];
            [self addTextFieldForName:kNameAuthEmail];
            [self addTextFieldForName:kNamePassword];
            
            [self.contentView setNeedsUpdateConstraints];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _cellType = OCellTypeActivate;
            
            [self addLabelForName:kNameActivate];
            [self addTextFieldForName:kNameActivationCode];
            [self addTextFieldForName:kNameRepeatPassword];
            
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
        [self layoutForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:[entity reuseIdentifier] delegate:delegate];
    
    if (self) {
        [self layoutForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


#pragma mark - Named view retrieval

- (id)textFieldWithName:(NSString *)name
{
    return [_namedViews objectForKey:[name stringByAppendingString:kNameSuffixTextField]];
}


- (id)textViewWithName:(NSString *)name
{
    return [_namedViews objectForKey:[name stringByAppendingString:kNameSuffixTextView]];
}


#pragma mark - Cell effects

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
    
    if (_cellType == OCellTypeSignIn) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[signInLabel(15)]-[authEmailField(22)]-1-[passwordField(22)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-25-[signInLabel]-25-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-55-[authEmailField]-55-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-55-[passwordField]-55-|" options:0 metrics:nil views:_namedViews]];
    } else if (_cellType == OCellTypeActivate) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[activationLabel(15)]-[activationCodeField(22)]-1-[repeatPasswordField(22)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-25-[activationCodeLabel]-25-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-55-[activationCodeField]-55-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-55-[repeatPasswordField]-55-|" options:0 metrics:nil views:_namedViews]];
    } else if (_cellType == OCellTypeMemberEntity) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-1)-[titleBanner(39)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-44-[dateOfBirthLabel(22)][mobilePhoneLabel(22)][emailLabel(22)]" options:NSLayoutFormatAlignAllTrailing metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[nameField(24)]-10-[dateOfBirthField(22)][mobilePhoneField(22)][emailField(22)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[photoFrame(75)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-1)-[titleBanner]-(-1)-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[nameField]-6-[photoFrame(75)]-10-|" options:NSLayoutFormatAlignAllTop metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[dateOfBirthLabel(>=55)]-3-[dateOfBirthField]-6-[photoFrame]-10-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[mobilePhoneLabel(>=55)]-3-[mobilePhoneField]-6-[photoFrame]-10-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[emailLabel(>=55)]-3-[emailField]-6-|" options:0 metrics:nil views:_namedViews]];
    } else if (_cellType == OCellTypeOrigoEntity) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[addressLabel(22)]-(>=0)-[telephoneLabel(22)]" options:NSLayoutFormatAlignAllTrailing metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[addressView(42)][telephoneField(22)]" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[addressLabel(>=55)]-3-[addressView]-6-|" options:0 metrics:nil views:_namedViews]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[telephoneLabel(>=55)]-3-[telephoneField]-6-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:_namedViews]];
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
