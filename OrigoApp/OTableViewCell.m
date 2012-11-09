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
#import "UIColor+OColorExtensions.h"
#import "UIDatePicker+ODatePickerExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTextField.h"

#import "OMember.h"
#import "OOrigo.h"
#import "OReplicatedEntity.h"

#import "OMember+OMemberExtensions.h"
#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

NSString * const kReuseIdentifierDefault = @"idDefaultCell";
NSString * const kReuseIdentifierUserLogin = @"idUserLoginCell";
NSString * const kReuseIdentifierUserActivation = @"idUserActivationCell";

CGFloat const kDefaultPadding = 10.f;

static CGFloat const kDefaultCellHeight = 45.f;
static CGFloat const kPhotoSideLength = 64.f;

static CGFloat const kLabelWidth = 63.f;
static CGFloat const kLabelToDetailAlignmentPadding = 2.f;
static CGFloat const kLabelDetailSpacing = 3.f;

static CGFloat const kAuthFieldExtent = 0.7f;
static CGFloat const kSingleLetterLabelWidthFraction = 0.09f;


@implementation OTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)isAuthFieldKey:(NSString *)key
{
    BOOL isAuthFieldKey = NO;
    
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldAuthEmail];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldPassword];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldActivationCode];
    isAuthFieldKey = isAuthFieldKey || [key isEqualToString:kTextFieldRepeatPassword];
    
    return isAuthFieldKey;
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


#pragma mark - Adding labels

- (UILabel *)addLabel:(NSString *)labelText
{
    return [self addLabel:labelText extent:0.f centred:NO];
}


- (UILabel *)addSingleLetterLabel:(NSString *)labelText
{
    return [self addLabel:labelText extent:kSingleLetterLabelWidthFraction centred:NO];
}


- (UILabel *)addLabel:(NSString *)labelText extent:(CGFloat)extent
{
    return [self addLabel:labelText extent:extent centred:NO];
}


- (UILabel *)addLabel:(NSString *)labelText centred:(BOOL)centred
{
    return [self addLabel:labelText extent:1.f centred:centred];
}


- (UILabel *)addLabel:(NSString *)labelText extent:(CGFloat)extent centred:(BOOL)centred
{
    UIFont *labelFont = [UIFont labelFont];
    
    CGFloat cellWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding;
    CGFloat contentWidth = cellWidth - kDefaultPadding - _contentMargin;
    CGFloat labelWidth = (extent > 0.f) ? extent * contentWidth : kLabelWidth;
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
    
    return label;
}


#pragma mark - Adding text fields

- (OTextField *)addTitleFieldWithKey:(NSString *)key text:(NSString *)text
{
    CGFloat bannerWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding + 2;
    CGFloat bannerHeight = kDefaultPadding + [UIFont titleFont].lineHeight + kLineSpacing;
    
    UIView *titleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(-1.f, -1.f, bannerWidth, bannerHeight)];
    titleBackgroundView.backgroundColor = [UIColor titleBackgroundColor];
    
    [self.contentView addSubview:titleBackgroundView];
    
    return [self addTextFieldWithKey:key extent:1.f text:text];
}


- (OTextField *)addTextFieldWithKey:(NSString *)key text:(NSString *)text
{
    return [self addTextFieldWithKey:key extent:1.f text:text];
}


- (OTextField *)addTextFieldWithKey:(NSString *)key date:(NSDate *)date
{
    OTextField *textField = [self addTextFieldWithKey:key text:[date localisedDateString]];
    
    if (date) {
        ((UIDatePicker *)textField.inputView).date = date;
    }
    
    return textField;
}


- (OTextField *)addTextFieldWithKey:(NSString *)key extent:(CGFloat)extent text:(NSString *)text
{
    OTextField *textField = nil;
    
    if (text || [OState s].actionIsInput) {
        CGPoint origin;
        CGFloat cellWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding;
        CGFloat fieldWidth = extent * (cellWidth - kDefaultPadding - _contentOffset - _contentMargin);
        
        if ([self isAuthFieldKey:key]) {
            origin = CGPointMake((cellWidth - fieldWidth) / 2.f, _verticalOffset);
        } else {
            origin = CGPointMake(_contentOffset + _contentMargin, _verticalOffset);
        }
        
        textField = [[OTextField alloc] initWithKey:key text:text delegate:_textFieldDelegate];
        [textField setOrigin:origin];
        [textField setWidth:fieldWidth];
        
        [self.contentView addSubview:textField];
        [_textFields setObject:textField forKey:key];
        
        CGFloat lineSpacing = textField.isTitle ? 2 * kLineSpacing : kLineSpacing;
        
        _verticalOffset += textField.font.lineHeight + lineSpacing;
        _contentMargin = kDefaultPadding;
    }
    
    return textField;
}


#pragma mark - Adding photo frame

- (UIButton *)addPhotoFrame:(UIImage *)photo
{
    UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(_contentMargin, _verticalOffset, kPhotoSideLength, kPhotoSideLength)];
    
    if (photo) {
        [imageButton setImage:photo forState:UIControlStateNormal];
    } else {
        imageButton.backgroundColor = [UIColor whiteColor];
        
        UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectInset(imageButton.bounds, 3.f, 3.f)];
        photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
        photoPrompt.font = [UIFont titleFont];
        photoPrompt.text = [OStrings stringForKey:strPromptPhoto];
        photoPrompt.textAlignment = UITextAlignmentCenter;
        photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
        
        [imageButton addSubview:photoPrompt];
    }

    [imageButton addDropShadowForPhotoFrame];
    [self.contentView addSubview:imageButton];
    
    _contentOffset += kPhotoSideLength;
    _contentMargin = kDefaultPadding;
    
    return imageButton;
}


#pragma mark - Cell composition

- (void)setUpForMemberEntity:(OMember *)member
{
    [self addTitleFieldWithKey:kTextFieldName text:member.name];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    [self.contentView bringSubviewToFront:[self textFieldForKey:kTextFieldName]];
    
    if ([member hasMobilePhone] || [OState s].actionIsInput) {
        [self addSingleLetterLabel:[OStrings stringForKey:strLabelAbbreviatedMobilePhone]];
        [self addTextFieldWithKey:kTextFieldMobilePhone text:member.mobilePhone];
    }
    
    if ([member hasEmail] || [OState s].actionIsInput) {
        [self addSingleLetterLabel:[OStrings stringForKey:strLabelAbbreviatedEmail]];
        [self addTextFieldWithKey:kTextFieldEmail text:member.entityId];
    }
    
    [self addSingleLetterLabel:[OStrings stringForKey:strLabelAbbreviatedDateOfBirth]];
    [self addTextFieldWithKey:kTextFieldDateOfBirth date:member.dateOfBirth];
    
    self.selectable = NO;
}


- (void)setUpForOrigoEntity:(OOrigo *)origo
{
    [self addLabel:[OStrings stringForKey:strTermAddress]];
    [self addTextFieldWithKey:kTextFieldAddressLine1 text:origo.addressLine1];
    [self addLabel:@""];
    [self addTextFieldWithKey:kTextFieldAddressLine2 text:origo.addressLine2];
    
    if ([origo hasTelephone] || [OState s].actionIsInput) {
        [self addLabel:[OStrings stringForKey:strLabelTelephone]];
        [self addTextFieldWithKey:kTextFieldTelephone text:origo.telephone];
    }
    
    self.selectable = ([OState s].actionIsList);
}


- (void)setUpForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    if (entityClass == OMember.class) {
        [self setUpForMemberEntity:(OMember *)entity];
    } else if (entityClass == OOrigo.class) {
        [self setUpForOrigoEntity:(OOrigo *)entity];
    }
}


#pragma mark - Cell height

+ (CGFloat)defaultHeight
{
    return kDefaultCellHeight;
}


+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin] ||
        [reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
        height = kDefaultPadding;
        height += [UIFont labelFont].lineHeight;
        height += 2.f * kLineSpacing;
        height += 2.f * [UIFont detailFont].lineHeight;
        height += 1.5f * kDefaultPadding;
    }
    
    return height;
}


+ (CGFloat)heightForEntityClass:(Class)entityClass
{
    CGFloat height = [OTableViewCell defaultHeight];
    
    if (entityClass == OMember.class) {
        height = 2 * kDefaultPadding + 2 * kLineSpacing;
        
        if ([OState s].actionIsInput) {
            height += [UIFont titleFont].lineHeight;
            height += 3 * [UIFont detailFont].lineHeight;
            height += 2 * kLineSpacing;
        } else {
            height += [UIFont titleFont].lineHeight;
            height += kPhotoSideLength;
        }
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

- (OTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _contentOffset = 0.f;
        _contentMargin = kDefaultPadding;
        _verticalOffset = kDefaultPadding;
        
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
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            [self addLabel:[OStrings stringForKey:strLabelSignInOrRegister] centred:YES];
            [self addTextFieldWithKey:kTextFieldAuthEmail extent:kAuthFieldExtent text:@""];
            [self addTextFieldWithKey:kTextFieldPassword extent:kAuthFieldExtent text:@""];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            [self addLabel:[OStrings stringForKey:strLabelActivate] centred:YES];
            [self addTextFieldWithKey:kTextFieldActivationCode extent:kAuthFieldExtent text:@""];
            [self addTextFieldWithKey:kTextFieldRepeatPassword extent:kAuthFieldExtent text:@""];
        }
    }
    
    return self;
}


- (OTableViewCell *)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:[entity reuseIdentifier] delegate:delegate];
    
    if (self) {
        [self setUpForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


- (OTableViewCell *)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        [self setUpForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


#pragma mark - Embedded text field access

- (OTextField *)textFieldForKey:(NSString *)key
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
        
        for (OTextField *textField in [_textFields allValues]) {
            textField.enabled = YES;
        }
    } else {
        for (OTextField *textField in [_textFields allValues]) {
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
