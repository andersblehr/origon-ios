//
//  ScTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTableViewCell.h"

#import "UIColor+ScColorExtensions.h"
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

NSString * const kTextFieldKeyAddressLine1 = @"addressLine1";
NSString * const kTextFieldKeyAddressLine2 = @"addressLine2";
NSString * const kTextFieldKeyPostCodeAndCity = @"postCodeAndCity";
NSString * const kTextFieldKeyLandline = @"landline";

CGFloat const kScreenWidth = 320.f;
CGFloat const kCellWidth = 300.f;
CGFloat const kContentWidth = 280.f;
CGFloat const kContentMargin = 10.f;
CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kLabelOriginX = 5.f;
static CGFloat const kLabelWidth = 63.f;
static CGFloat const kDetailMargin = 82.f;
static CGFloat const kDetailWidth = 113.f;

static CGFloat const kVerticalMargin = 12.f;
static CGFloat const kLabelFontVerticalOffset = 3.f;
static CGFloat const kLineSpacing = 5.f;
static CGFloat const kImageSideLength = 75.f;

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


#pragma mark - Adding labels, fields & buttons

- (void)addLabel:(NSString *)labelText centred:(BOOL)centred
{
    UIFont *labelFont = [UIFont labelFont];
    CGFloat labelLineHeight = [labelFont lineHeight];
    CGFloat labelWidth = centred ? kContentWidth : kLabelWidth;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kContentMargin, verticalOffset, labelWidth, labelLineHeight)];
    label.backgroundColor = [UIColor cellBackgroundColor];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    
    if (centred) {
        verticalOffset += labelLineHeight + kLineSpacing;
    } else {
        contentMargin = kDetailMargin;
    }
    
    [self.contentView addSubview:label];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key
{
    return [self addTextFieldForKey:key width:1.f text:nil];
}


- (ScTextField *)addTextFieldForKey:(NSString *)key width:(CGFloat)widthFraction text:(NSString *)text
{
    ScTextField *textField = nil;
    
    CGFloat contentWidth = kCellWidth - kContentMargin - contentMargin;
    CGFloat textFieldWidth = widthFraction * contentWidth;
    
    if (text || self.editing) {
        if ([self isAuthFieldKey:key]) {
            textField = [self authFieldForKey:key];
        } else if ([key isEqualToString:kTextFieldKeyName]) {
            textField = [[ScTextField alloc] initForTitleAtOrigin:CGPointMake(contentMargin, verticalOffset) width:textFieldWidth editing:self.editing];
        }
        
        verticalOffset += [[UIFont editableDetailFont] lineHeightWhenEditing] + kLineSpacing;
        
        textField.delegate = textFieldDelegate;
        [textFields setObject:textField forKey:key];
        [self.contentView addSubview:textField];
    }
        
    return textField;
}


- (void)addImage:(UIImage *)image
{
    imageButton = [[UIButton alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset, kImageSideLength, kImageSideLength)];
    
    if (image) {
        [imageButton setImage:image forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, kContentMargin, 2 * kContentMargin)];
        photoPrompt.backgroundColor = imageButton.backgroundColor;
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [ScStrings stringForKey:strPhotoPrompt];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];;
        
        [imageButton addSubview:photoPrompt];
    }

    [imageButton addImageShadow];
    [self.contentView addSubview:imageButton];
    
    contentMargin += kImageSideLength + kContentMargin;
}


#pragma mark - Cell population

- (void)setUpForEntityClass:(Class)entityClass entity:(ScCachedEntity *)entity delegate:(id)delegate
{
    selectable = NO;
    
    if (entityClass == ScMember.class) {
        ScMember *member = (ScMember *)entity;
        
        [self addImage:[UIImage imageWithData:member.picture]];
        [self addTextFieldForKey:kTextFieldKeyName width:1.f text:member.name];
        //[self addTitle:member.name];
    } else if (entityClass == ScScola.class) {
        ScScola *scola = (ScScola *)entity;
        
        [self addLabel:[ScStrings stringForKey:strAddressLabel] withDetail:[scola multiLineAddress] editable:self.editing];
        
        if ([scola hasLandline]) {
            [self addLabel:[ScStrings stringForKey:strLandlineLabel] withDetail:scola.landline editable:self.editing];
        }
    }
}


- (id)addLabel:(NSString *)label withDetail:(NSString *)detail editable:(BOOL)editable
{
    NSUInteger numberOfLinesInDetail = 1;
    CGFloat detailLineHeight = [[UIFont detailFont] lineHeight];
    
    if (detail && !editable) {
        numberOfLinesInDetail = [[NSMutableString stringWithString:detail] replaceOccurrencesOfString:@"\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, detail.length)] + 1;
    }
    
    CGRect labelFrame = CGRectMake(kLabelOriginX, verticalOffset + kLabelFontVerticalOffset, kLabelOriginX + kLabelWidth, [[UIFont labelFont] lineHeight]);
    CGRect detailFrame = CGRectMake(kDetailMargin, verticalOffset, kDetailMargin + kDetailWidth, detailLineHeight * numberOfLinesInDetail);
    
    verticalOffset += detailLineHeight * numberOfLinesInDetail + kLineSpacing;
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:labelFrame];
    labelView.backgroundColor = [UIColor cellBackgroundColor];
    labelView.font = [UIFont labelFont];
    labelView.text = label;
    labelView.textAlignment = UITextAlignmentRight;
    labelView.textColor = [UIColor labelTextColor];
    
    UIView *detailView = nil;
    
    if (editable) {
        UITextField *detailField = [[ScTextField alloc] initWithFrame:detailFrame];
        detailField.text = detail;
        
        detailView = detailField;
    } else {
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.backgroundColor = [UIColor cellBackgroundColor];
        detailLabel.font = [UIFont detailFont];
        detailLabel.numberOfLines = 0;
        detailLabel.text = detail;
        detailLabel.textAlignment = UITextAlignmentLeft;
        detailLabel.textColor = [UIColor detailTextColor];
        
        detailView = detailLabel;
    }
    
    [self.contentView addSubview:labelView];
    [self.contentView addSubview:detailView];
    
    [labels setObject:labelView forKey:label];
    [details setObject:detailView forKey:label];
    
    return detailView;
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
            [self addTextFieldForKey:kTextFieldKeyAuthEmail];
            [self addTextFieldForKey:kTextFieldKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            self.editing = YES;
            
            [self addLabel:[ScStrings stringForKey:strConfirmRegistrationLabel] centred:YES];
            [self addTextFieldForKey:kTextFieldKeyRegistrationCode];
            [self addTextFieldForKey:kTextFieldKeyRepeatPassword];
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
    self = [self initWithReuseIdentifier:entity.entityId];
    
    if (self) {
        self.editing = editing;
        
        [self setUpForEntityClass:entity.class entity:entity delegate:delegate];
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass)];
    
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


#pragma mark - Metadata

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScMember.class]) {
        height = 100.f;
    } else if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        CGFloat lineHeight = [[UIFont editableDetailFont] lineHeightWhenEditing];
        
        height += kVerticalMargin;
        height += lineHeight * [scola numberOfLinesInAddress];
        
        if ([scola hasLandline]) {
            height += kLineSpacing;
            height += lineHeight;
        }
        
        height += kVerticalMargin;
    }
    
    return height;
}


+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels
{
    CGFloat height = 0.f;
    
    height += kVerticalMargin * 2;
    height += [[UIFont editableDetailFont] lineHeightWhenEditing] * numberOfLabels;
    height += kLineSpacing * (numberOfLabels - 1);
    
    return height;
}

@end
