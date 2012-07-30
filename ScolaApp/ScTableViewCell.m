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

NSString * const kReuseIdentifierDefault = @"ruiDefault";
NSString * const kReuseIdentifierUserLogin = @"ruiUserLogin";
NSString * const kReuseIdentifierUserConfirmation = @"ruiUserConfirmation";

CGFloat const kScreenWidth = 320.f;
CGFloat const kCellWidth = 300.f;
CGFloat const kContentWidth = 280.f;
CGFloat const kDefaultContentMargin = 10.f;
CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kDefaultHardContentMargin = 0.f;
static CGFloat const kInitialVerticalMargin = 11.f;
static CGFloat const kPhotoSideLength = 63.f;

static CGFloat const kLabelWidth = 63.f;
static CGFloat const kLabelToDetailAlignmentPadding = 3.f;
static CGFloat const kLabelDetailSpacing = 5.f;
static CGFloat const kLineSpacing = 5.f;

static CGFloat const kAuthFieldWidthFraction = 0.7f;
static CGFloat const kSingleLetterLabelWidthFraction = 0.09f;
static CGFloat const kPhoneFieldWidthFraction = 0.45f;


@interface ScTableViewCell () {
    CGFloat _hardContentMargin;
    CGFloat _contentMargin;
    CGFloat _verticalOffset;
    
    NSMutableSet *_labels;
    NSMutableDictionary *_textFields;
    
    id<UITextFieldDelegate> _textFieldDelegate;
}

- (BOOL)isAuthFieldKey:(NSString *)key;
- (ScTextField *)authFieldForKey:(NSString *)key;

- (UIDatePicker *)dateOfBirthPicker;

@end


@implementation ScTableViewCell

#pragma mark - Private methods

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
    CGFloat contentWidth = kCellWidth - kDefaultContentMargin - _contentMargin;
    CGFloat textFieldWidth = kAuthFieldWidthFraction * contentWidth;
    
    ScTextField *textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(_contentMargin + (contentWidth - textFieldWidth) / 2.f, _verticalOffset) width:textFieldWidth editing:YES];
    
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
        textField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    }
    
    return textField;
}


- (UIDatePicker *)dateOfBirthPicker
{
    UIDatePicker *dateOfBirthPicker = [[UIDatePicker alloc] init];
    dateOfBirthPicker.datePickerMode = UIDatePickerModeDate;
    [dateOfBirthPicker setEarliestValidBirthDate];
    [dateOfBirthPicker setLatestValidBirthDate];
    [dateOfBirthPicker setTo01April1976];
    [dateOfBirthPicker addTarget:_textFieldDelegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    return dateOfBirthPicker;
}


#pragma mark - Metadata

+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = 0.f;
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin] ||
        [reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
        height += kInitialVerticalMargin;
        height += [UIFont labelFont].lineHeight;
        height += 2.f * kLineSpacing;
        height += 2.f * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 1.5f * kInitialVerticalMargin;
    }
    
    return height;
}


+ (CGFloat)heightForEntity:(ScCachedEntity *)entity editing:(BOOL)editing
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScMember.class]) {
        height = [ScTableViewCell heightForEntityClass:ScMember.class];
        
        if (!editing) {
            CGFloat titleHeight = [UIFont titleFont].lineHeight;
            CGFloat editingTitleHeight = [UIFont editableTitleFont].lineHeightWhenEditing;
            CGFloat detailHeight = [UIFont detailFont].lineHeight;
            CGFloat editingDetailHeight = [UIFont editableDetailFont].lineHeightWhenEditing;
            
            height -= (editingTitleHeight - titleHeight);
            height -= 3 * (editingDetailHeight - detailHeight);
        }
    } else if ([entity isKindOfClass:ScScola.class]) {
        height = [ScTableViewCell heightForEntityClass:ScScola.class];
        
        if (!editing) {
            CGFloat detailHeight = [UIFont detailFont].lineHeight;
            CGFloat editingDetailHeight = [UIFont editableDetailFont].lineHeightWhenEditing;
            
            height -= 3 * (editingDetailHeight - detailHeight);
        }
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = 0.f;
    
    if (entityClass == ScMember.class) {
        height += kInitialVerticalMargin;
        height += [UIFont editableTitleFont].lineHeightWhenEditing;
        height += 2 * kLineSpacing;
        height += 3 * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 2 * kLineSpacing;
        height += kInitialVerticalMargin;
    } else if (entityClass == ScScola.class) {
        height += kInitialVerticalMargin;
        height += 3 * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 2 * kLineSpacing;
        height += kInitialVerticalMargin;
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
    
    CGFloat contentWidth = kCellWidth - kDefaultContentMargin - _contentMargin;
    CGFloat labelWidth = (widthFraction > 0.f) ? widthFraction * contentWidth : kLabelWidth;
    CGFloat detailAlignmentPadding = centred ? 0.f : kLabelToDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(_hardContentMargin + _contentMargin, _verticalOffset + detailAlignmentPadding, labelWidth, labelFont.lineHeight)];
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
    
    UIView *titleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kCellWidth, kInitialVerticalMargin + titleHeight + kLineSpacing)];
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
    
    CGFloat contentWidth = kCellWidth - _hardContentMargin - _contentMargin - kDefaultContentMargin;
    CGFloat textFieldWidth = widthFraction * contentWidth;
    
    if (text || self.editing) {
        if ([self isAuthFieldKey:key]) {
            textField = [self authFieldForKey:key];
        } else if (isTitle) {
            textField = [[ScTextField alloc] initForTitleAtOrigin:CGPointMake(_hardContentMargin + _contentMargin, _verticalOffset) width:textFieldWidth editing:self.editing];
        } else {
            textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(_hardContentMargin + _contentMargin, _verticalOffset) width:textFieldWidth editing:self.editing];
        }
        
        textField.delegate = _textFieldDelegate;
        textField.enabled = self.editing;
        textField.key = key;
        textField.text = text;
        
        ScState *state = [ScMeta state];
        
        if ([key isEqualToString:kTextFieldKeyName]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strNamePrompt];
        } else if ([key isEqualToString:kTextFieldKeyEmail]) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            
            if (self.editing && (state.actionIsRegister && state.targetIsUser)) {
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
            
            if (state.actionIsRegister && state.targetIsHousehold) {
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
            _contentMargin = kDefaultContentMargin;
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
    
    _hardContentMargin += kPhotoSideLength;
    _contentMargin = kDefaultContentMargin;
}


#pragma mark - Cell population

- (void)setUpForMemberEntity:(ScMember *)member
{
    [self addTitleFieldWithText:member.name key:kTextFieldKeyName];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    
    if (self.editing) {
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
        [self addTextFieldWithText:member.entityId key:kTextFieldKeyEmail];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
        [self addTextFieldWithText:member.mobilePhone key:kTextFieldKeyMobilePhone];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterDateOfBirthLabel]];
        [self addTextFieldWithText:[member.dateOfBirth localisedDateString] key:kTextFieldKeyDateOfBirth];
    } else {
        ScScola *homeScola = [[ScMeta m].managedObjectContext fetchEntityWithId:member.scolaId];
        
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterAddressLabel]];
        [self addTextFieldWithText:[homeScola singleLineAddress] key:kTextFieldKeyAddress];
        
        if ([homeScola hasLandline]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterLandlineLabel]];
            
            if ([member hasMobilPhone]) {
                [self addTextFieldWithText:homeScola.landline key:kTextFieldKeyMobilePhone width:kPhoneFieldWidthFraction];
            } else {
                [self addTextFieldWithText:homeScola.landline key:kTextFieldKeyMobilePhone];
            }
        }
        
        if ([member hasMobilPhone]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
            [self addTextFieldWithText:member.mobilePhone key:kTextFieldKeyMobilePhone];
        }
        
        if ([member hasEmailAddress]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
            [self addTextFieldWithText:member.entityId key:kTextFieldKeyEmail];
        }
    }
    
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
    
    self.selectable = ([ScMeta state].actionIsDisplay && [ScMeta state].targetIsMemberships);
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

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _hardContentMargin = kDefaultHardContentMargin;
        _contentMargin = kDefaultContentMargin;
        _verticalOffset = kInitialVerticalMargin;
        
        _labels = [[NSMutableSet alloc] init];
        _textFields = [[NSMutableDictionary alloc] init];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        
        self.selectable = YES;
    }
    
    return self;
}


- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:reuseIdentifier];
    
    if (self) {
        _textFieldDelegate = delegate;
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            self.editing = YES;
            
            [self addLabel:[ScStrings stringForKey:strSignInOrRegisterLabel] centred:YES];
            [self addTextFieldWithKey:kTextFieldKeyAuthEmail];
            [self addTextFieldWithKey:kTextFieldKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            self.editing = YES;
            
            [self addLabel:[ScStrings stringForKey:strConfirmRegistrationLabel] centred:YES];
            [self addTextFieldWithKey:kTextFieldKeyRegistrationCode];
            [self addTextFieldWithKey:kTextFieldKeyRepeatPassword];
        }
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity
{
    return [self initWithEntity:entity editing:NO delegate:nil];
}


- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity editing:(BOOL)editing delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:entity.entityId delegate:delegate];
    
    if (self) {
        self.editing = editing;
        
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
    
    CGAffineTransform translateRight  = CGAffineTransformTranslate(CGAffineTransformIdentity, translation, translation);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -translation, -translation);
    
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
