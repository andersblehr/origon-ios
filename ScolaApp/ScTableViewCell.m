//
//  ScTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTableViewCell.h"

#import "UIColor+ScColorExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIFont+ScFontExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScStrings.h"
#import "ScTextField.h"

#import "ScCachedEntity.h"
#import "ScMember.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"

NSString * const kReuseIdentifierDefault = @"ruiDefault";
NSString * const kReuseIdentifierUserLogin = @"ruiUserLogin";
NSString * const kReuseIdentifierUserConfirmation = @"ruiUserConfirmation";

NSString * const kTextFieldKeyAuthEmail = @"authEmail";
NSString * const kTextFieldKeyPassword = @"password";
NSString * const kTextFieldKeyRegistrationCode = @"registrationCode";
NSString * const kTextFieldKeyRepeatPassword = @"repeatPassword";

NSString * const kTextFieldKeyName = @"name";
NSString * const kTextFieldKeyEmail = @"email";
NSString * const kTextFieldKeyMobilePhone = @"mobilePhone";
NSString * const kTextFieldKeyDateOfBirth = @"dateOfBirth";
NSString * const kTextFieldKeyUserWebsite = @"userWebsite";

NSString * const kTextFieldKeyAddress = @"address";
NSString * const kTextFieldKeyLandline = @"landline";
NSString * const kTextFieldKeyScolaWebsite = @"scolaWebsite";

CGFloat const kScreenWidth = 320.f;
CGFloat const kCellWidth = 300.f;
CGFloat const kContentWidth = 280.f;
CGFloat const kContentMargin = 10.f;
CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kLabelWidth = 63.f;
static CGFloat const kSingleLetterLabelWidth = 0.08f;
static CGFloat const kDetailMargin = 87.f;
static CGFloat const kDetailWidth = 193.f;
static CGFloat const kPhotoSideLength = 77.f;

static CGFloat const kVerticalMargin = 11.f;
static CGFloat const kDetailAlignmentPadding = 3.f;
static CGFloat const kLineSpacing = 5.f;
static CGFloat const kLabelDetailSpacing = 5.f;

static CGFloat const kAuthFieldWidthFraction = 0.7f;


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
    [dateOfBirthPicker setTo01April1976];
    [dateOfBirthPicker addTarget:textFieldDelegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    return dateOfBirthPicker;
}


#pragma mark - Metadata

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity whenEditing:(BOOL)editing
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScMember.class]) {
        CGFloat titleHeight = editing ? [UIFont editableTitleFont].lineHeightWhenEditing : [UIFont titleFont].lineHeight;
        
        height += kVerticalMargin;
        height += titleHeight;
        height += 2 * kLineSpacing;
        height += kPhotoSideLength;
        height += kVerticalMargin;
    } else if ([entity isKindOfClass:ScScola.class]) {
        CGFloat lineHeight = editing ? [UIFont editableDetailFont].lineHeightWhenEditing : [UIFont detailFont].lineHeight;
        
        height += kVerticalMargin;
        height += lineHeight;
        height += kLineSpacing;
        height += kPhotoSideLength;
        height += kVerticalMargin;
    }
    
    return height;
}


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


#pragma mark - Adding labels

- (void)addSingleLetterLabel:(NSString *)labelText
{
    return [self addLabel:labelText width:kSingleLetterLabelWidth centred:NO];
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
    CGFloat detailAlignmentPadding = centred ? 0.f : kDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset + detailAlignmentPadding, labelWidth, labelFont.lineHeight)];
    label.backgroundColor = [UIColor cellBackgroundColor];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    
    [self.contentView addSubview:label];
    
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
        
        if ([key isEqualToString:kTextFieldKeyName]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.placeholder = [ScStrings stringForKey:strNamePrompt];
        } else if ([key isEqualToString:kTextFieldKeyEmail]) {
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.placeholder = [ScStrings stringForKey:strEmailPrompt];
        } else if ([key isEqualToString:kTextFieldKeyMobilePhone]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = [ScStrings stringForKey:strMobilePhonePrompt];
        } else if ([key isEqualToString:kTextFieldKeyDateOfBirth]) {
            textField.inputView = [self dateOfBirthPicker];
            textField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
        } else if ([key isEqualToString:kTextFieldKeyAddress]) {
            textField.autocapitalizationType = UITextAutocorrectionTypeDefault;
            textField.placeholder = [ScStrings stringForKey:strAddressPrompt];
        } else if ([key isEqualToString:kTextFieldKeyLandline]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = [ScStrings stringForKey:strLandlinePrompt];
        } else if ([key isEqualToString:kTextFieldKeyScolaWebsite]) {
            textField.keyboardType = UIKeyboardTypeURL;
            textField.placeholder = [ScStrings stringForKey:strScolaWebsitePrompt];
        }
        
        textField.delegate = textFieldDelegate;
        textField.text = text;
        
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
    selectable = NO;
    
    if (entityClass == ScMember.class) {
        ScMember *member = (ScMember *)entity;
        
        [self addTextFieldForKey:kTextFieldKeyName text:member.name];
        [self addPhotoFrame:[UIImage imageWithData:member.photo]];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterEmailLabel]];
        [self addTextFieldForKey:kTextFieldKeyEmail text:member.entityId];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterMobilePhoneLabel]];
        [self addTextFieldForKey:kTextFieldKeyMobilePhone text:member.mobilePhone];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterDateOfBirthLabel]];
        [self addTextFieldForKey:kTextFieldKeyDateOfBirth text:nil];
    } else if (entityClass == ScScola.class) {
        ScScola *scola = (ScScola *)entity;
        
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterAddressLabel]];
        [self addTextFieldForKey:kTextFieldKeyAddress text:scola.address];
        [self addPhotoFrame:[UIImage imageWithData:scola.photo]];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterLandlineLabel]];
        [self addTextFieldForKey:kTextFieldKeyLandline text:scola.landline];
        [self addSingleLetterLabel:[ScStrings stringForKey:strSingleLetterWebsiteLabel]];
        [self addTextFieldForKey:kTextFieldKeyScolaWebsite text:scola.website];
    }
}


#pragma mark - Initialisation

- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        selectable = YES;
        
        contentMargin = kContentMargin;
        verticalOffset = kVerticalMargin;
        
        labels = [[NSMutableDictionary alloc] init];
        details = [[NSMutableDictionary alloc] init];
        textFields = [[NSMutableDictionary alloc] init];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
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
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
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
        for (NSString *label in labels.allKeys) {
            UILabel *labelView = [labels objectForKey:label];
            UILabel *detailView = [details objectForKey:label];
            
            if (selected) {
                labelView.textColor = [UIColor selectedLabelTextColor];
                detailView.textColor = [UIColor selectedDetailTextColor];
            } else {
                labelView.textColor = [UIColor labelTextColor];
                detailView.textColor = [UIColor detailTextColor];
            }
        }
        
        [super setSelected:selected animated:animated];
    }
}

@end
