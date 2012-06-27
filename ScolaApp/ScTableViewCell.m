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
    label.font = labelFont;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor colorWithType:ScColorLabel];
    label.backgroundColor = [UIColor colorWithType:ScColorBackground];
    label.text = labelText;
    
    verticalOffset += labelLineHeight + kLineSpacing;
    
    [self.contentView addSubview:label];
}


- (ScTextField *)addEditableFieldWithOffset:(CGFloat)offset centred:(BOOL)centred
{
    isSelectable = NO;
    
    CGFloat fieldOriginX = centred ? kCellWidth * offset : kLabelOriginX;
    CGFloat fieldWidth = centred ? kCellWidth - 2 * fieldOriginX : kCellWidth - fieldOriginX - kLabelOriginX;
    
    ScTextField *field = [[ScTextField alloc] initWithOrigin:CGPointMake(fieldOriginX, verticalOffset) width:fieldWidth editable:YES];
    
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.keyboardType = UIKeyboardTypeDefault;
    field.returnKeyType = UIReturnKeyNext;
    
    [self.contentView addSubview:field];
    
    verticalOffset += [UIFont lineHeightForFontWithType:ScFontEditableDetail] + kLineSpacing;
    
    return field;
}


- (void)addAuthFieldOfType:(ScAuthFieldType)type delegate:(id)delegate
{
    NSString *textFieldKey = nil;
    
    ScTextField *field = [self addEditableFieldWithOffset:0.15f centred:YES];
    field.delegate = delegate;
    
    if (type == ScAuthEmailField) {
        textFieldKey = kTextFieldKeyEmail;
        field.placeholder = [ScStrings stringForKey:strEmailPrompt];
        field.keyboardType = UIKeyboardTypeEmailAddress;
    } else if ((type == ScAuthPasswordField) || (type == ScAuthRepeatPasswordField)) {
        if (type == ScAuthPasswordField) {
            textFieldKey = kTextFieldKeyPassword;
            field.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        } else {
            textFieldKey = kTextFieldKeyRepeatPassword;
            field.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
        }
        
        field.returnKeyType = UIReturnKeyJoin;
        field.secureTextEntry = YES;
        field.clearsOnBeginEditing = YES;
    } else if (type == ScAuthRegistrationCodeField) {
        textFieldKey = kTextFieldKeyRegistrationCode;
        field.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    }
    
    [textFields setObject:field forKey:textFieldKey];
}


- (void)addImage:(UIImage *)image
{
    imageButton = [[UIButton alloc] initWithFrame:CGRectMake(contentMargin, verticalOffset, kImageSideLength, kImageSideLength)];
    
    contentMargin += kImageSideLength + kContentMargin;
    
    if (image) {
        [imageButton setImage:image forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor ghostWhiteColor];
    }

    [imageButton addImageShadow];
    [self.contentView addSubview:imageButton];
}


#pragma mark - Cell population

- (void)setUpForEntityClass:(Class)entityClass delegate:delegate
{
    if (entityClass == ScMember.class) {
        [self addImage:nil];
    }
}


- (void)populateWithEntity:(ScCachedEntity *)entity delegate:(id)delegate
{
    BOOL editable = (delegate != nil);
    
    if ([entity isKindOfClass:ScMember.class]) {
        ScMember *member = (ScMember *)entity;
        
        [self addImage:[UIImage imageWithData:member.picture]];
    } else if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        
        [self addLabel:[ScStrings stringForKey:strAddress] withDetail:[scola multiLineAddress]editable:editable];
        
        if ([scola hasLandline]) {
            [self addLabel:[ScStrings stringForKey:strLandline] withDetail:scola.landline editable:editable];
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
    labelView.font = [UIFont fontWithType:ScFontLabel];
    labelView.textAlignment = UITextAlignmentRight;
    labelView.backgroundColor = [UIColor colorWithType:ScColorBackground];
    labelView.textColor = [UIColor colorWithType:ScColorLabel];
    labelView.text = label;
    
    UIView *detailView = nil;
    
    if (editable) {
        UITextField *detailField = [[ScTextField alloc] initWithFrame:detailFrame];
        detailField.text = detail;
        
        detailView = detailField;
    } else {
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.font = [UIFont fontWithType:ScFontDetail];
        detailLabel.textAlignment = UITextAlignmentLeft;
        detailLabel.backgroundColor = [UIColor colorWithType:ScColorBackground];
        detailLabel.textColor = [UIColor colorWithType:ScColorText];
        detailLabel.numberOfLines = 0;
        detailLabel.text = detail;
        
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
        isSelectable = YES;
        
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
            [self addCentredLabel:[ScStrings stringForKey:strSignInOrRegisterPrompt]];
            
            [self addAuthFieldOfType:ScAuthEmailField delegate:delegate];
            [self addAuthFieldOfType:ScAuthPasswordField delegate:delegate];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            [self addCentredLabel:[ScStrings stringForKey:strConfirmRegistrationPrompt]];
            
            [self addAuthFieldOfType:ScAuthRegistrationCodeField delegate:delegate];
            [self addAuthFieldOfType:ScAuthRepeatPasswordField delegate:delegate];
        }
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntity:(ScCachedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:entity.entityId];
    
    if (self) {
        [self populateWithEntity:entity delegate:delegate];
    }
    
    return self;
}


- (ScTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass)];
    
    if (self) {
        [self setUpForEntityClass:entityClass delegate:delegate];
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (isSelectable) {
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
