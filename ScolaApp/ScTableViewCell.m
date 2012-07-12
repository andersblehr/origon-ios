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


@implementation ScTableViewCell

@synthesize selectable;
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
    CGFloat contentWidth = kCellWidth - kDefaultContentMargin - contentMargin;
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
    
    CGFloat contentWidth = kCellWidth - kDefaultContentMargin - contentMargin;
    CGFloat labelWidth = (widthFraction > 0.f) ? widthFraction * contentWidth : kLabelWidth;
    CGFloat detailAlignmentPadding = centred ? 0.f : kLabelToDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(hardContentMargin + contentMargin, verticalOffset + detailAlignmentPadding, labelWidth, labelFont.lineHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    
    [self.contentView addSubview:label];
    [labels addObject:label];
    
    if (centred) {
        verticalOffset += labelFont.lineHeight + kLineSpacing;
    } else {
        contentMargin += labelWidth + kLabelDetailSpacing;
    }
}


#pragma mark - Adding text fields

- (ScTextField *)addTitleFieldForKey:(NSString *)key text:(NSString *)text
{
    CGFloat titleHeight = self.editing ? [UIFont editableTitleFont].lineHeightWhenEditing : [UIFont titleFont].lineHeight;
    
    UIView *titleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kCellWidth, kInitialVerticalMargin + titleHeight + kLineSpacing)];
    titleBackgroundView.backgroundColor = [UIColor ashGrayColor];
    
    [self.contentView addSubview:titleBackgroundView];
    
    return [self addTextFieldForKey:key text:text width:1.f title:YES];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key text:(NSString *)text
{
    return [self addTextFieldForKey:key text:text width:1.f title:NO];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key text:(NSString *)text width:(CGFloat)widthFraction
{
    return [self addTextFieldForKey:key text:text width:widthFraction title:NO];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key text:(NSString *)text width:(CGFloat)widthFraction title:(BOOL)title
{
    ScTextField *textField = nil;
    
    CGFloat contentWidth = kCellWidth - hardContentMargin - contentMargin - kDefaultContentMargin;
    CGFloat textFieldWidth = widthFraction * contentWidth;
    
    if (text || self.editing) {
        if ([self isAuthFieldKey:key]) {
            textField = [self authFieldForKey:key];
        } else if (title) {
            textField = [[ScTextField alloc] initForTitleAtOrigin:CGPointMake(hardContentMargin + contentMargin, verticalOffset) width:textFieldWidth editing:self.editing];
        } else {
            textField = [[ScTextField alloc] initForDetailAtOrigin:CGPointMake(hardContentMargin + contentMargin, verticalOffset) width:textFieldWidth editing:self.editing];
        }
        
        textField.delegate = textFieldDelegate;
        textField.enabled = self.editing;
        textField.key = key;
        textField.text = text;
        
        if ([key isEqualToString:kTextFieldKeyName]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strNamePrompt];
            
            if ([ScMeta appState] == ScAppStateRegisterUser) {
                //textField.text = nil; // TODO: Bug, also blanks when member is registered
            }
        } else if ([key isEqualToString:kTextFieldKeyEmail]) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            
            if (self.editing && [ScMeta appState] == ScAppStateRegisterUser) {
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
            
            if ([ScMeta appState] == ScAppStateRegisterUserHousehold) {
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
        
        if (widthFraction == 1.f) {
            verticalOffset += [textField lineHeight] + [textField lineSpacingBelow];
            contentMargin = kDefaultContentMargin;
        } else {
            contentMargin += textFieldWidth;
        }
    }
        
    return textField;
}


#pragma mark - Adding photo frame

- (void)addPhotoFrame:(UIImage *)photo
{
    imageButton = [[UIButton alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset, kPhotoSideLength, kPhotoSideLength)];
    
    if (photo) {
        [imageButton setImage:photo forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor whiteColor];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, 3.f, 3.f)];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [ScStrings stringForKey:strPhotoPrompt];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
        
        [imageButton addSubview:photoPrompt];
    }

    [imageButton addShadowForPhotoFrame];
    [self.contentView addSubview:imageButton];
    
    hardContentMargin += kPhotoSideLength;
    contentMargin = kDefaultContentMargin;
}


#pragma mark - Cell population

- (void)setUpForMemberEntity:(ScMember *)member
{
    [self addTitleFieldForKey:kTextFieldKeyName text:member.name];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    
    if (self.editing) {
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
        [self addTextFieldForKey:kTextFieldKeyEmail text:member.entityId];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
        [self addTextFieldForKey:kTextFieldKeyMobilePhone text:member.mobilePhone];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterDateOfBirthLabel]];
        [self addTextFieldForKey:kTextFieldKeyDateOfBirth text:[member.dateOfBirth localisedDateString]];
    } else {
        ScScola *homeScola = [[ScMeta m].managedObjectContext fetchEntityWithId:member.scolaId];
        
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterAddressLabel]];
        [self addTextFieldForKey:kTextFieldKeyAddress text:[homeScola singleLineAddress]];
        
        if ([homeScola hasLandline]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterLandlineLabel]];
            
            if ([member hasMobilPhone]) {
                [self addTextFieldForKey:kTextFieldKeyMobilePhone text:homeScola.landline width:kPhoneFieldWidthFraction];
            } else {
                [self addTextFieldForKey:kTextFieldKeyMobilePhone text:homeScola.landline];
            }
        }
        
        if ([member hasMobilPhone]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
            [self addTextFieldForKey:kTextFieldKeyMobilePhone text:member.mobilePhone];
        }
        
        if ([member hasEmailAddress]) {
            [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
            [self addTextFieldForKey:kTextFieldKeyEmail text:member.entityId];
        }
    }
    
    self.selectable = NO;
}


- (void)setUpForScolaEntity:(ScScola *)scola
{
    [self addLabel:[ScStrings stringForKey:strAddressLabel]];
    [self addTextFieldForKey:kTextFieldKeyAddressLine1 text:scola.addressLine1];
    [self addLabel:@""];
    [self addTextFieldForKey:kTextFieldKeyAddressLine2 text:scola.addressLine2];
    [self addLabel:[ScStrings stringForKey:strLandlineLabel]];
    [self addTextFieldForKey:kTextFieldKeyLandline text:scola.landline];
    
    selectable =
        ([ScMeta appState] == ScAppStateDisplayUserHouseholdMemberships) ||
        ([ScMeta appState] == ScAppStateDisplayScolaMemberships) ||
        ([ScMeta appState] == ScAppStateDisplayScolaMemberHouseholdMemberships);
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
        hardContentMargin = kDefaultHardContentMargin;
        contentMargin = kDefaultContentMargin;
        verticalOffset = kInitialVerticalMargin;
        
        labels = [[NSMutableSet alloc] init];
        textFields = [[NSMutableDictionary alloc] init];
        
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
    return [textFields objectForKey:key];
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


#pragma mark - Accessors

- (void)setSelectable:(BOOL)isSelectable
{
    selectable = isSelectable;
    
    if (!selectable) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}


#pragma mark - Overrides

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    
    if (editing) {
        self.selectable = NO;
        
        for (ScTextField *textField in [textFields allValues]) {
            textField.enabled = YES;
        }
    } else {
        for (ScTextField *textField in [textFields allValues]) {
            textField.enabled = NO;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selectable) {
        [super setSelected:selected animated:animated];
        
        for (UILabel *label in labels) {
            label.textColor = selected ? [UIColor selectedLabelTextColor] : [UIColor labelTextColor];
        }
        
        for (NSString *key in textFields.allKeys) {
            [[textFields objectForKey:key] setSelected:selected];
        }
    }
}

@end
