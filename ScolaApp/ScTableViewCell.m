//
//  ScTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTableViewCell.h"

#import "UIColor+ScColorExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScStrings.h"
#import "ScTextField.h"

#import "ScCachedEntity.h"
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

static CGFloat const kCellWidth = 300.f;

static CGFloat const kLabelFontSize = 12.f;

static CGFloat const kLabelOriginX = 5.f;
static CGFloat const kLabelWidth = 63.f;
static CGFloat const kDetailOriginX = 82.f;
static CGFloat const kDetailWidth = 113.f;

static CGFloat const kVerticalMargin = 12.f;
static CGFloat const kLabelFontVerticalOffset = 3.f;
static CGFloat const kLineSpacing = 5.f;

static UIColor *backgroundColour = nil;
static UIColor *selectedBackgroundColour = nil;
static UIColor *labelColour = nil;
static UIColor *selectedLabelColour = nil;

static UIFont *labelFont = nil;


@implementation ScTableViewCell


#pragma mark - Auxiliary methods

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


- (void)populateWithEntity:(ScCachedEntity *)entity
{
    if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        NSString *addressLabel = [ScStrings stringForKey:strAddress];
        
        [self addLabel:addressLabel withDetail:[scola multiLineAddress]];
        
        if ([scola hasLandline]) {
            NSString *landlineLabel = [ScStrings stringForKey:strLandline];
            
            [self addLabel:landlineLabel withDetail:scola.landline];
        }
    }
}


#pragma mark - Table view defaults

+ (UIColor *)backgroundColour
{
    if (!backgroundColour) {
        backgroundColour = [UIColor isabellineColor];
    }
    
    return backgroundColour;
}


+ (UIColor *)selectedBackgroundColour
{
    if (!selectedBackgroundColour) {
        selectedBackgroundColour = [UIColor ashGrayColor];
    }
    
    return selectedBackgroundColour;
}


+ (UIColor *)labelColour
{
    if (!labelColour) {
        labelColour = [UIColor slateGrayColor];
    }
    
    return labelColour;
}


+ (UIColor *)selectedLabelColour
{
    if (!selectedLabelColour) {
        selectedLabelColour = [UIColor lightTextColor];
    }
    
    return selectedLabelColour;
}


+ (UIFont *)labelFont
{
    if (!labelFont) {
        labelFont = [UIFont boldSystemFontOfSize:kLabelFontSize];
    }
    
    return labelFont;
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        backgroundColour = [ScTableViewCell backgroundColour];
        selectedBackgroundColour = [ScTableViewCell selectedBackgroundColour];
        labelColour = [ScTableViewCell labelColour];
        selectedLabelColour = [ScTableViewCell selectedLabelColour];
        labelFont = [ScTableViewCell labelFont];
        
        isSelectable = YES;
        labelLineHeight = 2.5f * labelFont.xHeight;
        verticalOffset = kVerticalMargin;
        
        labels = [[NSMutableDictionary alloc] init];
        details = [[NSMutableDictionary alloc] init];
        textFields = [[NSMutableDictionary alloc] init];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = backgroundColour;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = selectedBackgroundColour;
        
        self.textLabel.backgroundColor = backgroundColour;
        self.detailTextLabel.backgroundColor = backgroundColour;
    }
    
    return self;
}


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:reuseIdentifier];
    
    if (self) {
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            [self addLabel:[ScStrings stringForKey:strSignInOrRegisterPrompt]];
            
            [self addAuthFieldOfType:ScAuthEmailField delegate:delegate];
            [self addAuthFieldOfType:ScAuthPasswordField delegate:delegate];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserConfirmation]) {
            [self addLabel:[ScStrings stringForKey:strConfirmRegistrationPrompt]];

            [self addAuthFieldOfType:ScAuthRegistrationCodeField delegate:delegate];
            [self addAuthFieldOfType:ScAuthRepeatPasswordField delegate:delegate];
        }
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}


- (id)initWithEntity:(ScCachedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:entity.entityId];
    
    if (self) {
        [self populateWithEntity:entity];
    }
    
    return self;
}


+ (ScTableViewCell *)defaultCellForTableView:(UITableView *)tableView
{
    ScTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifierDefault];
    
    if (!cell) {
        cell = [[ScTableViewCell alloc] initWithReuseIdentifier:kReuseIdentifierDefault];
    }
    
    return cell;
}


+ (ScTableViewCell *)entityCellForEntity:(ScCachedEntity *)entity tableView:(UITableView *)tableView
{
    ScTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:entity.entityId];
    
    if (!cell) {
        if ([entity isKindOfClass:ScScola.class]) {
            cell = [[ScTableViewCell alloc] initWithReuseIdentifier:entity.entityId];
            
            [cell populateWithEntity:entity];
        }
    }
    
    return cell;
}


#pragma mark - Embedded view access

- (ScTextField *)textFieldWithKey:(NSString *)key
{
    return [textFields objectForKey:key];
}


- (UILabel *)labelWithKey:(NSString *)key
{
    return [labels objectForKey:key];
}


#pragma mark - Cell population

- (void)addLabel:(NSString *)labelText
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLabelOriginX, verticalOffset, 280.f, labelLineHeight)];
    label.font = labelFont;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = labelColour;
    label.backgroundColor = backgroundColour;
    label.text = labelText;
    
    verticalOffset += labelLineHeight + kLineSpacing;
    
    [self.contentView addSubview:label];
}


- (void)addLabel:(NSString *)label withDetail:(NSString *)detail
{
    [self addLabel:label withDetail:detail editable:NO];
}


- (ScTextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail
{
    isSelectable = NO;
    
    return [self addLabel:label withDetail:detail editable:YES];
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
    
    verticalOffset += [ScTextField editingLineHeight] + kLineSpacing;
    
    return field;
}


- (id)addLabel:(NSString *)label withDetail:(NSString *)detail editable:(BOOL)editable
{
    NSUInteger numberOfLinesInDetail = 1;
    CGFloat detailLineHeight = [ScTextField editingLineHeight];
    
    if (detail && !editable) {
        numberOfLinesInDetail = [[NSMutableString stringWithString:detail] replaceOccurrencesOfString:@"\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, detail.length)] + 1;
    }
    
    CGRect labelFrame = CGRectMake(kLabelOriginX, verticalOffset + kLabelFontVerticalOffset, kLabelOriginX + kLabelWidth, labelLineHeight);
    CGRect detailFrame = CGRectMake(kDetailOriginX, verticalOffset, kDetailOriginX + kDetailWidth, detailLineHeight * numberOfLinesInDetail);
    
    verticalOffset += detailLineHeight * numberOfLinesInDetail + kLineSpacing;
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:labelFrame];
    labelView.font = labelFont;
    labelView.textAlignment = UITextAlignmentRight;
    labelView.backgroundColor = backgroundColour;
    labelView.textColor = labelColour;
    labelView.text = label;
    
    UIView *detailView = nil;
    
    if (editable) {
        UITextField *detailField = [[ScTextField alloc] initWithFrame:detailFrame];
        detailField.text = detail;
        
        detailView = detailField;
    } else {
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.font = [ScTextField displayFont];
        detailLabel.textAlignment = UITextAlignmentLeft;
        detailLabel.backgroundColor = backgroundColour;
        detailLabel.textColor = [ScTextField textColour];
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


#pragma mark - Metadata

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        CGFloat lineHeight = [ScTextField editingLineHeight];
        
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
    height += [ScTextField editingLineHeight] * numberOfLabels;
    height += kLineSpacing * (numberOfLabels - 1);
    
    return height;
}


#pragma mark - Overrides

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (isSelectable) {
        for (NSString *label in labels.allKeys) {
            UILabel *labelView = [labels objectForKey:label];
            UILabel *detailView = [details objectForKey:label];
            
            labelView.textColor = selected ? selectedLabelColour : labelColour;
            detailView.textColor = selected ? [ScTextField selectedTextColour] : [ScTextField textColour];
        }
        
        [super setSelected:selected animated:animated];
    }
}

@end
