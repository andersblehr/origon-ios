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

typedef enum {
    ScAuthEmailField,
    ScAuthPasswordField,
    ScAuthRepeatPasswordField,
    ScAuthRegistrationCodeField,
} ScAuthFieldType;

NSString * const kReuseIdentifierDefault = @"ruiDefault";
NSString * const kReuseIdentifierUserLogin = @"ruiUserLogin";
NSString * const kReuseIdentifierUserConfirmation = @"ruiUserConfirmation";

NSString * const kTextFieldKeyEmail = @"email";
NSString * const kTextFieldKeyPassword = @"password";
NSString * const kTextFieldKeyRegistrationCode = @"registrationCode";
NSString * const kTextFieldKeyRepeatPassword = @"repeatPassword";

NSString * const kTextFieldKeyName = @"name";
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
static CGFloat const kDetailOriginX = 82.f;
static CGFloat const kDetailWidth = 113.f;

static CGFloat const kVerticalMargin = 12.f;
static CGFloat const kLabelFontVerticalOffset = 3.f;
static CGFloat const kLineSpacing = 5.f;
static CGFloat const kImageSideLength = 75.f;


@implementation ScTableViewCell

@synthesize imageButton;


#pragma mark - Metadata

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScMember.class]) {
        height = 100.f;
    } else if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        CGFloat lineHeight = [UIFont lineHeightForFontWithType:ScFontEditableDetail];
        
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
    height += [UIFont lineHeightForFontWithType:ScFontEditableDetail] * numberOfLabels;
    height += kLineSpacing * (numberOfLabels - 1);
    
    return height;
}


#pragma mark - Adding labels, fields & buttons

- (void)addCentredLabel:(NSString *)labelText
{
    UIFont *labelFont = [UIFont fontWithType:ScFontLabel];
    CGFloat labelLineHeight = [labelFont displayLineHeight];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kContentMargin, verticalOffset, kContentWidth, labelLineHeight)];
    label.backgroundColor = [UIColor colorWithType:ScColorBackground];
    label.font = labelFont;
    label.text = labelText;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor colorWithType:ScColorLabel];
    
    verticalOffset += labelLineHeight + kLineSpacing;
    
    [self.contentView addSubview:label];
}


- (ScTextField *)addTextFieldWithWidth:(CGFloat)widthFraction centred:(BOOL)centred
{
    CGFloat contentWidth = kCellWidth - kContentMargin - contentMargin;
    CGFloat fieldWidth = widthFraction * contentWidth;
    CGFloat fieldOriginX = centred ? contentMargin + (contentWidth - fieldWidth) / 2 : contentMargin;
    
    ScTextField *field = [[ScTextField alloc] initWithOrigin:CGPointMake(fieldOriginX, verticalOffset) width:fieldWidth editable:self.editing];
    field.keyboardType = UIKeyboardTypeDefault;
    field.returnKeyType = UIReturnKeyNext;
    
    [self.contentView addSubview:field];
    
    verticalOffset += [UIFont lineHeightForFontWithType:ScFontEditableDetail] + kLineSpacing;
    
    return field;
}


- (void)addAuthFieldOfType:(ScAuthFieldType)type delegate:(id)delegate
{
    NSString *authFieldKey = nil;
    
    ScTextField *authField = [self addTextFieldWithWidth:0.7f centred:YES];
    authField.delegate = delegate;
    
    if (type == ScAuthEmailField) {
        authFieldKey = kTextFieldKeyEmail;
        authField.keyboardType = UIKeyboardTypeEmailAddress;
        authField.placeholder = [ScStrings stringForKey:strEmailPrompt];
    } else if ((type == ScAuthPasswordField) || (type == ScAuthRepeatPasswordField)) {
        if (type == ScAuthPasswordField) {
            authFieldKey = kTextFieldKeyPassword;
            authField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        } else {
            authFieldKey = kTextFieldKeyRepeatPassword;
            authField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
        }
        
        authField.clearsOnBeginEditing = YES;
        authField.returnKeyType = UIReturnKeyJoin;
        authField.secureTextEntry = YES;
    } else if (type == ScAuthRegistrationCodeField) {
        authFieldKey = kTextFieldKeyRegistrationCode;
        authField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    }
    
    [textFields setObject:authField forKey:authFieldKey];
}


- (void)addImage:(UIImage *)image
{
    imageButton = [[UIButton alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset, kImageSideLength, kImageSideLength)];
    
    if (image) {
        [imageButton setImage:image forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor colorWithType:ScColorImagePlaceholder];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, kContentMargin, 2 * kContentMargin)];
        photoPrompt.backgroundColor = imageButton.backgroundColor;
        photoPrompt.font = [UIFont fontWithType:ScFontTitle];
        photoPrompt.text = [ScStrings stringForKey:strPhotoPrompt];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor colorWithType:ScColorImagePlaceholderText];;
        
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
    CGFloat detailLineHeight = [UIFont lineHeightForFontWithType:ScFontEditableDetail];
    
    if (detail && !editable) {
        numberOfLinesInDetail = [[NSMutableString stringWithString:detail] replaceOccurrencesOfString:@"\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, detail.length)] + 1;
    }
    
    CGRect labelFrame = CGRectMake(kLabelOriginX, verticalOffset + kLabelFontVerticalOffset, kLabelOriginX + kLabelWidth, [UIFont lineHeightForFontWithType:ScFontLabel]);
    CGRect detailFrame = CGRectMake(kDetailOriginX, verticalOffset, kDetailOriginX + kDetailWidth, detailLineHeight * numberOfLinesInDetail);
    
    verticalOffset += detailLineHeight * numberOfLinesInDetail + kLineSpacing;
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:labelFrame];
    labelView.backgroundColor = [UIColor colorWithType:ScColorBackground];
    labelView.font = [UIFont fontWithType:ScFontLabel];
    labelView.text = label;
    labelView.textAlignment = UITextAlignmentRight;
    labelView.textColor = [UIColor colorWithType:ScColorLabel];
    
    UIView *detailView = nil;
    
    if (editable) {
        UITextField *detailField = [[ScTextField alloc] initWithFrame:detailFrame];
        detailField.text = detail;
        
        detailView = detailField;
    } else {
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.backgroundColor = [UIColor colorWithType:ScColorBackground];
        detailLabel.font = [UIFont fontWithType:ScFontDetail];
        detailLabel.numberOfLines = 0;
        detailLabel.text = detail;
        detailLabel.textAlignment = UITextAlignmentLeft;
        detailLabel.textColor = [UIColor colorWithType:ScColorText];
        
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
        self.backgroundView.backgroundColor = [UIColor colorWithType:ScColorBackground];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithType:ScColorSelectedBackground];
        
        self.textLabel.backgroundColor = [UIColor colorWithType:ScColorBackground];
        self.detailTextLabel.backgroundColor = [UIColor colorWithType:ScColorBackground];
    }
    
    return self;
}


- (ScTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:reuseIdentifier];
    
    if (self) {
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            self.editing = YES;
            
            [self addCentredLabel:[ScStrings stringForKey:strSignInOrRegisterLabel]];
            [self addAuthFieldOfType:ScAuthEmailField delegate:delegate];
            [self addAuthFieldOfType:ScAuthPasswordField delegate:delegate];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            self.editing = YES;
            
            [self addCentredLabel:[ScStrings stringForKey:strConfirmRegistrationLabel]];
            [self addAuthFieldOfType:ScAuthRegistrationCodeField delegate:delegate];
            [self addAuthFieldOfType:ScAuthRepeatPasswordField delegate:delegate];
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
                labelView.textColor = [UIColor colorWithType:ScColorSelectedLabel];
                detailView.textColor = [UIColor colorWithType:ScColorSelectedText];
            } else {
                labelView.textColor = [UIColor colorWithType:ScColorLabel];
                detailView.textColor = [UIColor colorWithType:ScColorText];
            }
        }
        
        [super setSelected:selected animated:animated];
    }
}

@end
