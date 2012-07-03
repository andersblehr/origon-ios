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
#import "UIColor+ScColorExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIFont+ScFontExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScStrings.h"
#import "ScTextField.h"

#import "ScCachedEntity.h"
#import "ScMember.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"

NSString * const kReuseIdentifierDefault = @"ruiDefault";
NSString * const kReuseIdentifierUserLogin = @"ruiUserLogin";
NSString * const kReuseIdentifierUserConfirmation = @"ruiUserConfirmation";

CGFloat const kScreenWidth = 320.f;
CGFloat const kCellWidth = 300.f;
CGFloat const kContentWidth = 280.f;
CGFloat const kContentMargin = 10.f;
CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kVerticalMargin = 11.f;
static CGFloat const kPhotoSideLength = 77.f;

static CGFloat const kLabelWidth = 63.f;
static CGFloat const kLabelToDetailAlignmentPadding = 3.f;
static CGFloat const kLabelDetailSpacing = 10.f;
static CGFloat const kLineSpacing = 5.f;

static CGFloat const kAuthFieldWidthFraction = 0.7f;
static CGFloat const kSingleLetterLabelWidthFraction = 0.08f;


@implementation ScTableViewCell

@synthesize imageButton;


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
    CGFloat contentWidth = kCellWidth - kContentMargin - contentMargin;
    CGFloat textFieldWidth = kAuthFieldWidthFraction * contentWidth;
    
    ScTextField *textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(contentMargin + (contentWidth - textFieldWidth) / 2.f, verticalOffset) width:textFieldWidth editing:YES];
    
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
    [dateOfBirthPicker addTarget:textFieldDelegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    return dateOfBirthPicker;
}


#pragma mark - Metadata

+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = 0.f;
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin] ||
        [reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
        height += kVerticalMargin;
        height += [UIFont labelFont].lineHeight;
        height += 2.f * kLineSpacing;
        height += 2.f * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 1.5f * kVerticalMargin;
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
            
            height -= (editingTitleHeight - titleHeight);
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
        height += kVerticalMargin;
        height += [UIFont editableTitleFont].lineHeightWhenEditing;
        height += 2 * kLineSpacing;
        height += kPhotoSideLength;
        height += kVerticalMargin;
    } else if (entityClass == ScScola.class) {
        height += kVerticalMargin;
        height += 3 * [UIFont editableDetailFont].lineHeightWhenEditing;
        height += 2 * kLineSpacing;
        height += kVerticalMargin;
    }
    
    return height;
}


#pragma mark - Adding labels

- (void)addSingleLetterLabel:(NSString *)labelText
{
    return [self addLabel:labelText width:kSingleLetterLabelWidthFraction centred:NO];
}


- (void)addLabel:(NSString *)labelText
{
    return [self addLabel:labelText width:0.f centred:NO];
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
    
    CGFloat contentWidth = kCellWidth - kContentMargin - contentMargin;
    labelWidth = (widthFraction > 0.f) ? widthFraction * contentWidth : kLabelWidth;
    CGFloat detailAlignmentPadding = centred ? 0.f : kLabelToDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset + detailAlignmentPadding, labelWidth, labelFont.lineHeight)];
    label.backgroundColor = [UIColor cellBackgroundColor];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    
    [self.contentView addSubview:label];
    [labels addObject:label];
    
    if (centred) {
        labelWidth = 0.f;
        verticalOffset += labelFont.lineHeight + kLineSpacing;
    } else {
        labelWidth += kLabelDetailSpacing;
    }
}


#pragma mark - Adding text fields

- (ScTextField *)addTextFieldForKey:(NSString *)key text:(NSString *)text
{
    return [self addTextFieldForKey:key width:1.f text:text];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key width:(CGFloat)widthFraction text:(NSString *)text
{
    ScTextField *textField = nil;
    
    CGFloat contentWidth = kCellWidth - kContentMargin - contentMargin - labelWidth;
    CGFloat textFieldWidth = widthFraction * contentWidth;
    
    if (text || self.editing) {
        if ([self isAuthFieldKey:key]) {
            textField = [self authFieldForKey:key];
        } else if ([key isEqualToString:kTextFieldKeyName]) {
            textField = [[ScTextField alloc] initForTitleAtOrigin:CGPointMake(contentMargin + labelWidth, verticalOffset) width:textFieldWidth editing:self.editing];
        } else {
            textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(contentMargin + labelWidth, verticalOffset) width:textFieldWidth editing:self.editing];
        }
        
        textField.delegate = textFieldDelegate;
        textField.enabled = self.editing;
        textField.key = key;
        textField.text = text;
        
        if ([key isEqualToString:kTextFieldKeyName]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strNamePrompt];
            
            if ([ScMeta m].appState == ScAppStateRegisterUser) {
                textField.text = nil;
            }
        } else if ([key isEqualToString:kTextFieldKeyEmail]) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            
            if (self.editing && [ScMeta m].appState == ScAppStateRegisterUser) {
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
            
            if ([ScMeta m].appState == ScAppStateRegisterUserHousehold) {
                textField.placeholder = [ScStrings stringForKey:strHouseholdLandlinePrompt];
            } else {
                textField.placeholder = [ScStrings stringForKey:strScolaLandlinePrompt];
            }
        } else if ([key isEqualToString:kTextFieldKeyScolaWebsite]) {
            textField.keyboardType = UIKeyboardTypeURL;
            textField.placeholder = [ScStrings stringForKey:strScolaWebsitePrompt];
        }
        
        [self.contentView addSubview:textField];
        [textFields setObject:textField forKey:key];
        
        labelWidth = 0.f;
        verticalOffset += [textField lineHeight] + [textField lineSpacingBelow];
    }
        
    return textField;
}


#pragma mark - Adding photo frame

- (void)addPhotoFrame:(UIImage *)image
{
    imageButton = [[UIButton alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset, kPhotoSideLength, kPhotoSideLength)];
    
    if (image) {
        [imageButton setImage:image forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor whiteColor];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, 3.f, 3.f)];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [ScStrings stringForKey:strPhotoPrompt];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];;
        
        [imageButton addSubview:photoPrompt];
    }

    [imageButton addShadowForPhotoFrame];
    [self.contentView addSubview:imageButton];
    
    contentMargin += kPhotoSideLength + kContentMargin;
}


#pragma mark - Cell population

- (void)setUpForEntityClass:(Class)entityClass entity:(ScCachedEntity *)entity delegate:(id)delegate
{
    selectable = !self.editing;
    
    if (entityClass == ScMember.class) {
        ScMember *member = (ScMember *)entity;
        
        [self addTextFieldForKey:kTextFieldKeyName text:member.name];
        [self addPhotoFrame:[UIImage imageWithData:member.photo]];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
        [self addTextFieldForKey:kTextFieldKeyEmail text:member.entityId];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
        [self addTextFieldForKey:kTextFieldKeyMobilePhone text:member.mobilePhone];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterDateOfBirthLabel]];
        [self addTextFieldForKey:kTextFieldKeyDateOfBirth text:[member.dateOfBirth localisedDateString]];
    } else if (entityClass == ScScola.class) {
        ScScola *scola = (ScScola *)entity;
        
        [self addLabel:[ScStrings stringForKey:strAddressLabel]];
        [self addTextFieldForKey:kTextFieldKeyAddressLine1 text:scola.addressLine1];
        [self addLabel:@""];
        [self addTextFieldForKey:kTextFieldKeyAddressLine2 text:scola.addressLine2];
        [self addLabel:[ScStrings stringForKey:strLandlineLabel]];
        [self addTextFieldForKey:kTextFieldKeyLandline text:scola.landline];
    }
}


#pragma mark - Initialisation

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        contentMargin = kContentMargin;
        verticalOffset = kVerticalMargin;
        
        labels = [[NSMutableSet alloc] init];
        textFields = [[NSMutableDictionary alloc] init];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        
        //self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
    }
    
    return self;
}


- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:reuseIdentifier];
    
    if (self) {
        textFieldDelegate = delegate;
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            self.editing = YES;
            
            [self addLabel:[ScStrings stringForKey:strSignInOrRegisterLabel] centred:YES];
            [self addTextFieldForKey:kTextFieldKeyAuthEmail text:nil];
            [self addTextFieldForKey:kTextFieldKeyPassword text:nil];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            self.editing = YES;
            
            [self addLabel:[ScStrings stringForKey:strConfirmRegistrationLabel] centred:YES];
            [self addTextFieldForKey:kTextFieldKeyRegistrationCode text:nil];
            [self addTextFieldForKey:kTextFieldKeyRepeatPassword text:nil];
        }
        
        selectable = !self.editing;
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
        
        [self setUpForEntityClass:entity.class entity:entity delegate:delegate];
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        self.editing = YES;
        
        [self setUpForEntityClass:entityClass entity:nil delegate:delegate];
    }
    
    return self;
}


#pragma mark - Embedded text field access

- (ScTextField *)textFieldWithKey:(NSString *)key
{
    return [textFields objectForKey:key];
}


#pragma mark - Cell effects

- (void)shake
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


#pragma mark - Overrides

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selectable) {
        [super setSelected:selected animated:animated];
        
        for (UILabel *label in labels) {
            if (selected) {
                label.textColor = [UIColor selectedLabelTextColor];
            } else {
                label.textColor = [UIColor labelTextColor];
            }
        }
        
        for (NSString *key in textFields.allKeys) {
            UITextField *textField = [textFields objectForKey:key];
            
            if (selected) {
                textField.backgroundColor = [UIColor selectedCellBackgroundColor];
                textField.textColor = [UIColor selectedDetailTextColor];
            } else {
                textField.backgroundColor = [UIColor cellBackgroundColor];
                textField.textColor = [UIColor detailTextColor];
            }
        }
    }
}

@end
