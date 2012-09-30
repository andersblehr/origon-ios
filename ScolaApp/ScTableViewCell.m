//
//  ScTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTableViewCell.h"

#import <AudioToolbox/AudioToolbox.h>

#import "NSDate+ScDateExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UIColor+ScColorExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIFont+ScFontExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTextField.h"

#import "ScCachedEntity.h"
#import "ScMember.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

NSString * const kReuseIdentifierDefault = @"idDefault";
NSString * const kReuseIdentifierUserLogin = @"idUserLogin";
NSString * const kReuseIdentifierUserActivation = @"idUserConfirmation";

CGFloat const kScreenWidth = 320.f;
CGFloat const kCellWidth = 300.f;
CGFloat const kContentWidth = 280.f;
CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kVerticalPadding = 11.f;
static CGFloat const kHorizontalPadding = 10.f;
static CGFloat const kDefaultCellHeight = 47.f;
static CGFloat const kDefaultContentOffset = 0.f;
static CGFloat const kPhotoSideLength = 63.f;

static CGFloat const kLabelWidth = 63.f;
static CGFloat const kLabelToDetailAlignmentPadding = 2.f;
static CGFloat const kLabelDetailSpacing = 7.f;
static CGFloat const kLineSpacing = 5.f;

static CGFloat const kAuthFieldWidthFraction = 0.7f;
static CGFloat const kSingleLetterLabelWidthFraction = 0.09f;
static CGFloat const kPhoneFieldWidthFraction = 0.45f;


@implementation ScTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)isAuthFieldKey:(NSString *)key
{
    BOOL isAuthFieldKey = NO;
    
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldKeyAuthEmail];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldKeyPassword];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldKeyRegistrationCode];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldKeyRepeatPassword];
    
    return isAuthFieldKey;
}


- (ScTextField *)authFieldForKey:(NSString *)key
{
    CGFloat contentWidth = kCellWidth - kHorizontalPadding - _contentMargin;
    CGFloat textFieldWidth = kAuthFieldWidthFraction * contentWidth;
    
    ScTextField *textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(_contentMargin + (contentWidth - textFieldWidth) / 2.f, _verticalOffset) width:textFieldWidth];
    
    BOOL isPasswordField = [key isEqualToString:kTextFieldKeyRepeatPassword];
    isPasswordField = isPasswordField || [key isEqualToString:kTextFieldKeyPassword];
    
    if (isPasswordField) {
        textField.clearsOnBeginEditing = YES;
        textField.returnKeyType = UIReturnKeyJoin;
        textField.secureTextEntry = YES;
        
        if ([key isEqualToString:kTextFieldKeyPassword]) {
            textField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        } else if ([key isEqualToString:kTextFieldKeyRepeatPassword]) {
            textField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
        }
    } else if ([key isEqualToString:kTextFieldKeyAuthEmail]) {
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.placeholder = [ScStrings stringForKey:strAuthEmailPrompt];
    } else if ([key isEqualToString:kTextFieldKeyRegistrationCode]) {
        textField.placeholder = [ScStrings stringForKey:strActivationCodePrompt];
    }
    
    return textField;
}


- (UIDatePicker *)dateOfBirthPicker
{
    UIDatePicker *dateOfBirthPicker = [[UIDatePicker alloc] init];
    dateOfBirthPicker.datePickerMode = UIDatePickerModeDate;
    [dateOfBirthPicker setEarliestValidBirthDate];
    [dateOfBirthPicker setLatestValidBirthDate];
    [dateOfBirthPicker setToDefaultDate];
    [dateOfBirthPicker addTarget:_textFieldDelegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    return dateOfBirthPicker;
}


#pragma mark - Metadata

+ (CGFloat)defaultHeight
{
    return kDefaultCellHeight;
}


+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = [ScTableViewCell defaultHeight];
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin] ||
        [reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
        height = kVerticalPadding;
        height += [UIFont labelFont].lineHeight;
        height += 2.f * kLineSpacing;
        height += 2.f * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 1.5f * kVerticalPadding;
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = [ScTableViewCell defaultHeight];
    
    if (entityClass == ScMember.class) {
        height = 2 * kVerticalPadding + 2 * kLineSpacing;
        
        if ([ScState s].actionIsInput) {
            height += [UIFont editableTitleFont].lineHeightWhenEditing;
            height += 3 * [UIFont editableDetailFont].lineHeightWhenEditing;
            height += 2 * kLineSpacing;
        } else {
            height += [UIFont titleFont].lineHeight;
            height += kPhotoSideLength;
        }
    } else if (entityClass == ScScola.class) {
        height = 2 * kVerticalPadding + 2 * kLineSpacing;
        
        if ([ScState s].actionIsInput) {
            height += 3 * [UIFont editableDetailFont].lineHeightWhenEditing;
        } else {
            height += 3 * [UIFont detailFont].lineHeight;
        }
    }
    
    return height;
}


+ (CGFloat)heightForEntity:(ScCachedEntity *)entity
{
    CGFloat height = [ScTableViewCell heightForEntityClass:entity.class];
    
    if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        
        if (![scola hasLandline]) {
            if ([ScState s].actionIsInput) {
                height -= [UIFont editableDetailFont].lineHeightWhenEditing;
            } else {
                height -= [UIFont detailFont].lineHeight;
            }
            
            height -= kLineSpacing;
        }
    }
    
    return height;
}


#pragma mark - Adding labels

- (void)addLabel:(NSString *)labelText
{
    return [self addLabel:labelText width:0.f centred:NO];
}


- (void)addSingleLetterLabel:(NSString *)labelText
{
    return [self addLabel:labelText width:kSingleLetterLabelWidthFraction centred:NO];
}


- (void)addLabel:(NSString *)labelText width:(CGFloat)widthFraction
{
    return [self addLabel:labelText width:widthFraction centred:NO];
}


- (void)addLabel:(NSString *)labelText centred:(BOOL)centred
{
    return [self addLabel:labelText width:1.f centred:centred];
}


- (void)addLabel:(NSString *)labelText width:(CGFloat)widthFraction centred:(BOOL)centred
{
    UIFont *labelFont = [UIFont labelFont];
    
    CGFloat contentWidth = kCellWidth - kHorizontalPadding - _contentMargin;
    CGFloat labelWidth = (widthFraction > 0.f) ? widthFraction * contentWidth : kLabelWidth;
    CGFloat detailAlignmentPadding = centred ? 0.f : kLabelToDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(_contentOffset + _contentMargin, _verticalOffset + detailAlignmentPadding, labelWidth, labelFont.lineHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    
    [self.contentView addSubview:label];
    [_labels addObject:label];
    
    if (centred) {
        _verticalOffset += labelFont.lineHeight + kLineSpacing;
    } else {
        _contentMargin += labelWidth + kLabelDetailSpacing;
    }
}


#pragma mark - Adding text fields

- (ScTextField *)addTitleFieldWithText:(NSString *)text key:(NSString *)key
{
    CGFloat titleHeight = self.editing ? [UIFont editableTitleFont].lineHeightWhenEditing : [UIFont titleFont].lineHeight;
    
    UIView *titleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(-1.f, -1.f, kCellWidth + 2, kVerticalPadding + titleHeight + kLineSpacing)];
    titleBackgroundView.backgroundColor = [UIColor ashGrayColor];
    
    [self.contentView addSubview:titleBackgroundView];
    
    return [self addTextFieldWithText:text key:key width:1.f isTitle:YES];
}


- (ScTextField *)addTextFieldWithKey:(NSString *)key
{
    return [self addTextFieldWithText:nil key:key];
}


- (ScTextField *)addTextFieldWithText:(NSString *)text key:(NSString *)key
{
    return [self addTextFieldWithText:text key:key width:1.f isTitle:NO];
}


- (ScTextField *)addTextFieldWithDate:(NSDate *)date key:(NSString *)key
{
    ScTextField *textField = [self addTextFieldWithText:[date localisedDateString] key:key];
    
    if (date) {
        ((UIDatePicker *)textField.inputView).date = date;
    }
    
    return textField;
}


- (ScTextField *)addTextFieldWithText:(NSString *)text key:(NSString *)key width:(CGFloat)widthFraction
{
    return [self addTextFieldWithText:text key:key width:widthFraction isTitle:NO];
}


- (ScTextField *)addTextFieldWithText:(NSString *)text key:(NSString *)key width:(CGFloat)widthFraction isTitle:(BOOL)isTitle
{
    ScTextField *textField = nil;
    
    CGFloat contentWidth = kCellWidth - _contentOffset - _contentMargin - kHorizontalPadding;
    CGFloat textFieldWidth = widthFraction * contentWidth;
    
    if (text || self.editing) {
        if ([self isAuthFieldKey:key]) {
            textField = [self authFieldForKey:key];
        } else if (isTitle) {
            textField = [[ScTextField alloc] initForTitleAtOrigin:CGPointMake(_contentOffset + _contentMargin, _verticalOffset) width:textFieldWidth];
        } else {
            textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(_contentOffset + _contentMargin, _verticalOffset) width:textFieldWidth];
        }
        
        textField.delegate = _textFieldDelegate;
        textField.enabled = self.editing;
        textField.key = key;
        textField.text = text;
        
        if ([key isEqualToString:kTextFieldKeyName]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strNamePrompt];
        } else if ([key isEqualToString:kTextFieldKeyEmail]) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            
            if ([ScState s].actionIsRegister &&
                [ScState s].targetIsMember && [ScState s].aspectIsSelf) {
                textField.enabled = NO;
            }
        } else if ([key isEqualToString:kTextFieldKeyMobilePhone]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = [ScStrings stringForKey:strMobilePhonePrompt];
        } else if ([key isEqualToString:kTextFieldKeyDateOfBirth]) {
            textField.inputView = [self dateOfBirthPicker];
            textField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
        } else if ([key isEqualToString:kTextFieldKeyAddressLine1]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
        } else if ([key isEqualToString:kTextFieldKeyAddressLine2]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
        } else if ([key isEqualToString:kTextFieldKeyLandline]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            
            if ([ScState s].actionIsRegister && [ScState s].targetIsResidence) {
                textField.placeholder = [ScStrings stringForKey:strHouseholdLandlinePrompt];
            } else {
                textField.placeholder = [ScStrings stringForKey:strScolaLandlinePrompt];
            }
        } else if ([key isEqualToString:kTextFieldKeyScolaWebsite]) {
            textField.keyboardType = UIKeyboardTypeURL;
            textField.placeholder = [ScStrings stringForKey:strScolaWebsitePrompt];
        }
        
        [self.contentView addSubview:textField];
        [_textFields setObject:textField forKey:key];
        
        if (widthFraction == 1.f) {
            _verticalOffset += [textField lineHeight] + [textField lineSpacingBelow];
            _contentMargin = kHorizontalPadding;
        } else {
            _contentMargin += textFieldWidth;
        }
    }
        
    return textField;
}


#pragma mark - Adding photo frame

- (void)addPhotoFrame:(UIImage *)photo
{
    _imageButton = [[UIButton alloc] initWithFrame:CGRectMake(_contentMargin, _verticalOffset, kPhotoSideLength, kPhotoSideLength)];
    
    if (photo) {
        [_imageButton setImage:photo forState:UIControlStateNormal];
    } else {
        _imageButton.backgroundColor = [UIColor whiteColor];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(_imageButton.bounds, 3.f, 3.f)];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [ScStrings stringForKey:strPhotoPrompt];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
        
        [_imageButton addSubview:photoPrompt];
    }

    [_imageButton addShadowForPhotoFrame];
    [self.contentView addSubview:_imageButton];
    
    _contentOffset += kPhotoSideLength;
    _contentMargin = kHorizontalPadding;
}


#pragma mark - Cell population

- (void)setUpForMemberEntity:(ScMember *)member
{
    [self addTitleFieldWithText:member.name key:kTextFieldKeyName];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    
    if ([member hasEmailAddress] || [ScState s].actionIsInput) {
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
        [self addTextFieldWithText:member.entityId key:kTextFieldKeyEmail];
    }
    
    if ([member hasMobilePhone] || [ScState s].actionIsInput) {
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
        [self addTextFieldWithText:member.mobilePhone key:kTextFieldKeyMobilePhone];
    }
    
    [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterDateOfBirthLabel]];
    [self addTextFieldWithText:[member.dateOfBirth localisedDateString] key:kTextFieldKeyDateOfBirth];
    
    self.selectable = NO;
}


- (void)setUpForScolaEntity:(ScScola *)scola
{
    [self addLabel:[ScStrings stringForKey:strAddressLabel]];
    [self addTextFieldWithText:scola.addressLine1 key:kTextFieldKeyAddressLine1];
    [self addLabel:@""];
    [self addTextFieldWithText:scola.addressLine2 key:kTextFieldKeyAddressLine2];
    [self addLabel:[ScStrings stringForKey:strLandlineLabel]];
    [self addTextFieldWithText:scola.landline key:kTextFieldKeyLandline];
    
    self.selectable = ([ScState s].actionIsDisplay && [ScState s].targetIsMemberships);
}


- (void)setUpForEntityClass:(Class)entityClass entity:(ScCachedEntity *)entity
{
    if (entityClass == ScMember.class) {
        [self setUpForMemberEntity:(ScMember *)entity];
    } else if (entityClass == ScScola.class) {
        [self setUpForScolaEntity:(ScScola *)entity];
    }
}


#pragma mark - Initialisation

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _contentOffset = kDefaultContentOffset;
        _contentMargin = kHorizontalPadding;
        _verticalOffset = kVerticalPadding;
        
        _labels = [[NSMutableSet alloc] init];
        _textFields = [[NSMutableDictionary alloc] init];
        _textFieldDelegate = delegate;
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.font = [UIFont detailFont];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.textLabel.font = [UIFont titleFont];
        
        self.selectable = YES;
        self.editing = [ScState s].actionIsInput;
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            [self addLabel:[ScStrings stringForKey:strSignInOrRegisterLabel] centred:YES];
            [self addTextFieldWithKey:kTextFieldKeyAuthEmail];
            [self addTextFieldWithKey:kTextFieldKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            [self addLabel:[ScStrings stringForKey:strActivateLabel] centred:YES];
            [self addTextFieldWithKey:kTextFieldKeyRegistrationCode];
            [self addTextFieldWithKey:kTextFieldKeyRepeatPassword];
        }
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity
{
    return [self initWithEntity:entity delegate:nil];
}


- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:entity.entityId delegate:delegate];
    
    if (self) {
        [self setUpForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        self.editing = YES;
        
        [self setUpForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


#pragma mark - Embedded text field access

- (ScTextField *)textFieldWithKey:(NSString *)key
{
    return [_textFields objectForKey:key];
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


- (void)shakeWithVibration:(BOOL)doVibrate
{
    if (doVibrate) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    CGFloat translation = 3.f;
    
    CGAffineTransform translateRight = CGAffineTransformTranslate(CGAffineTransformIdentity, translation, 0.f);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -translation, 0.f);
    
    self.transform = translateLeft;
    
    [UIView animateWithDuration:0.05f delay:0.f options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:3.f];
        
        self.transform = translateRight;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.05f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:NULL];
    }];
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
    
    if (editing) {
        self.selectable = NO;
        
        for (ScTextField *textField in [_textFields allValues]) {
            textField.enabled = YES;
        }
    } else {
        for (ScTextField *textField in [_textFields allValues]) {
            textField.enabled = NO;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selectable) {
        [super setSelected:selected animated:animated];
        
        for (UILabel *label in _labels) {
            label.textColor = selected ? [UIColor selectedLabelTextColor] : [UIColor labelTextColor];
        }
        
        for (NSString *key in _textFields.allKeys) {
            [[_textFields objectForKey:key] setSelected:selected];
        }
    }
}

@end
