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

static CGFloat const kDefaultLabelWidth = 63.f;
static CGFloat const kLabelToDetailAlignmentPadding = 3.f;
static CGFloat const kLabelDetailSpacing = 3.f;

static CGFloat const kLabelExtentDefault = 0.f;
static CGFloat const kLabelExtentCentred = 1.f;
static CGFloat const kFieldExtentGreedy = 1.f;

static CGFloat const kAuthFieldExtent = 0.7f;
static CGFloat const kSingleLetterLabelExtent = 0.09f;

static NSString * const kLabelSignIn = @"signInLabel";
static NSString * const kLabelActivate = @"activationLabel";
static NSString * const kLabelMobilePhone = @"mobilePhoneLabel";
static NSString * const kLabelEmail = @"emailLabel";
static NSString * const kLabelDateOfBirth = @"dateOfBirthLabel";
static NSString * const kLabelAddress = @"addressLabel";
static NSString * const kLabelTelephone = @"telephoneLabel";


@implementation OTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)isAuthFieldName:(NSString *)name
{
    BOOL isAuthFieldName = NO;
    
    isAuthFieldName = isAuthFieldName || [name isEqualToString:kTextFieldAuthEmail];
    isAuthFieldName = isAuthFieldName || [name isEqualToString:kTextFieldPassword];
    isAuthFieldName = isAuthFieldName || [name isEqualToString:kTextFieldActivationCode];
    isAuthFieldName = isAuthFieldName || [name isEqualToString:kTextFieldRepeatPassword];
    
    return isAuthFieldName;
}


- (NSString *)stringForLabelWithName:(NSString *)name
{
    NSString *stringKey = @"";
    
    if ([name isEqualToString:kLabelSignIn]) {
        stringKey = strLabelSignIn;
    } else if ([name isEqualToString:kLabelActivate]) {
        stringKey = strLabelActivate;
    } else if ([name isEqualToString:kLabelMobilePhone]) {
        stringKey = strLabelMobilePhone;
    } else if ([name isEqualToString:kLabelEmail]) {
        stringKey = strLabelEmail;
    } else if ([name isEqualToString:kLabelDateOfBirth]) {
        stringKey = strLabelDateOfBirth;
    } else if ([name isEqualToString:kLabelAddress]) {
        stringKey = strTermAddress;
    } else if ([name isEqualToString:kLabelTelephone]) {
        stringKey = strLabelTelephone;
    }
    
    return [OStrings stringForKey:stringKey];
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


#pragma mark - Addint title & photo

- (UIView *)addTitleBanner
{
    CGFloat bannerWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding + 2;
    CGFloat bannerHeight = kDefaultPadding + [UIFont titleFont].lineHeight + kLineSpacing;
    
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectMake(-1.f, -1.f, bannerWidth, bannerHeight)];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    
    [self.contentView addSubview:titleBannerView];

    return titleBannerView;
}


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


#pragma mark - Adding labels

- (UILabel *)addNamedLabel:(NSString *)name
{
    return [self addNamedLabel:name extent:kLabelExtentDefault];
}


- (UILabel *)addNamedLabel:(NSString *)name extent:(CGFloat)extent
{
    BOOL centred = (extent == kLabelExtentCentred);
    UIFont *font = [UIFont labelFont];
    
    CGFloat cellWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding;
    CGFloat contentWidth = cellWidth - kDefaultPadding - _contentMargin;
    CGFloat labelWidth = (extent > 0.f) ? extent * contentWidth : kDefaultLabelWidth;
    CGFloat detailAlignmentPadding = centred ? 0.f : kLabelToDetailAlignmentPadding;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(_contentOffset + _contentMargin, _verticalOffset + detailAlignmentPadding, labelWidth, font.lineHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.font = font;
    label.text = [self stringForLabelWithName:name];
    label.textAlignment = centred ? UITextAlignmentCenter : UITextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [_namedViews setObject:label forKey:name];
    
    [self.contentView addSubview:label];
    
    if (centred) {
        _verticalOffset += font.lineHeight + kLineSpacing;
    } else {
        _contentMargin += labelWidth + kLabelDetailSpacing;
    }
    
    return label;
}


#pragma mark - Adding text fields

- (OTextField *)addNamedTextField:(NSString *)name text:(NSString *)text
{
    return [self addNamedTextField:name text:text extent:kFieldExtentGreedy];
}


- (OTextField *)addNamedTextField:(NSString *)name date:(NSDate *)date
{
    OTextField *textField = [self addNamedTextField:name text:[date localisedDateString]];
    
    if (date) {
        ((UIDatePicker *)textField.inputView).date = date;
    }
    
    return textField;
}


- (OTextField *)addNamedTextField:(NSString *)name extent:(CGFloat)extent
{
    return [self addNamedTextField:name text:@"" extent:extent];
}


- (OTextField *)addNamedTextField:(NSString *)name text:(NSString *)text extent:(CGFloat)extent
{
    OTextField *textField = nil;
    
    if (text || [OState s].actionIsInput) {
        CGPoint origin;
        CGFloat cellWidth = self.contentView.bounds.size.width - 2 * kDefaultPadding;
        CGFloat fieldWidth = extent * (cellWidth - kDefaultPadding - _contentOffset - _contentMargin);
        
        if ([self isAuthFieldName:name]) {
            origin = CGPointMake((cellWidth - fieldWidth) / 2.f, _verticalOffset);
        } else {
            origin = CGPointMake(_contentOffset + _contentMargin, _verticalOffset);
        }
        
        textField = [[OTextField alloc] initWithName:name text:text delegate:_textFieldDelegate];
        [textField setOrigin:origin];
        [textField setWidth:fieldWidth];
        [_namedViews setObject:textField forKey:name];
        
        [self.contentView addSubview:textField];
        
        CGFloat lineSpacing = textField.isTitle ? 2 * kLineSpacing : kLineSpacing;
        
        _verticalOffset += textField.font.lineHeight + lineSpacing;
        _contentMargin = kDefaultPadding;
    }
    
    return textField;
}


#pragma mark - Cell composition

- (void)layoutForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    if (entityClass == OMember.class) {
        [self layoutForMemberEntity:(OMember *)entity];
    } else if (entityClass == OOrigo.class) {
        [self layoutForOrigoEntity:(OOrigo *)entity];
    }
}


- (void)layoutForMemberEntity:(OMember *)member
{
    [self addTitleBanner];
    [self addNamedTextField:kTextFieldName text:member.name];
    [self addPhotoFrame:[UIImage imageWithData:member.photo]];
    [self.contentView bringSubviewToFront:[self textFieldWithName:kTextFieldName]];
    
    if ([member hasMobilePhone] || [OState s].actionIsInput) {
        [self addNamedLabel:kLabelMobilePhone];
        [self addNamedTextField:kTextFieldMobilePhone text:member.mobilePhone];
    }
    
    if ([member hasEmail] || [OState s].actionIsInput) {
        [self addNamedLabel:kLabelEmail];
        [self addNamedTextField:kTextFieldEmail text:member.entityId];
    }
    
    [self addNamedLabel:kLabelDateOfBirth];
    [self addNamedTextField:kTextFieldDateOfBirth date:member.dateOfBirth];
    
    _selectable = NO;
}


- (void)layoutForOrigoEntity:(OOrigo *)origo
{
    [self addNamedLabel:kLabelAddress];
    [self addNamedTextField:kTextFieldAddressLine1 text:origo.addressLine1];
    [self addNamedLabel:@""];
    [self addNamedTextField:kTextFieldAddressLine2 text:origo.addressLine2];
    
    if ([origo hasTelephone] || [OState s].actionIsInput) {
        [self addNamedLabel:kLabelTelephone];
        [self addNamedTextField:kTextFieldTelephone text:origo.telephone];
    }
    
    _selectable = ([OState s].actionIsList);
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

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _contentOffset = 0.f;
        _contentMargin = kDefaultPadding;
        _verticalOffset = kDefaultPadding;
        
        _namedViews = [[NSMutableDictionary alloc] init];
        _textFieldDelegate = delegate;
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.font = [UIFont detailFont];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.textLabel.font = [UIFont titleFont];
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserLogin]) {
            [self addNamedLabel:kLabelSignIn extent:kLabelExtentCentred];
            [self addNamedTextField:kTextFieldAuthEmail extent:kAuthFieldExtent];
            [self addNamedTextField:kTextFieldPassword extent:kAuthFieldExtent];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            [self addNamedLabel:kLabelActivate extent:kLabelExtentCentred];
            [self addNamedTextField:kTextFieldActivationCode extent:kAuthFieldExtent];
            [self addNamedTextField:kTextFieldRepeatPassword extent:kAuthFieldExtent];
        } else {
            _selectable = YES;
        }
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:NSStringFromClass(entityClass) delegate:delegate];
    
    if (self) {
        [self layoutForEntityClass:entityClass entity:nil];
    }
    
    return self;
}


- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    self = [self initWithReuseIdentifier:[entity reuseIdentifier] delegate:delegate];
    
    if (self) {
        [self layoutForEntityClass:entity.class entity:entity];
    }
    
    return self;
}


#pragma mark - Embedded text field access

- (OTextField *)textFieldWithName:(NSString *)name
{
    return [_namedViews objectForKey:name];
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

    for (UIView *view in [_namedViews allValues]) {
        if ([view isKindOfClass:OTextField.class]) {
            ((OTextField *)view).enabled = editing;
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selectable) {
        [super setSelected:selected animated:animated];
        
        for (UIView *view in [_namedViews allValues]) {
            if ([view isKindOfClass:UILabel.class]) {
                if (selected) {
                    ((UILabel *)view).textColor = [UIColor selectedLabelTextColor];
                } else {
                    ((UILabel *)view).textColor = [UIColor labelTextColor];
                }
            } else if ([view isKindOfClass:OTextField.class]) {
                ((OTextField *)view).selected = selected;
            }
        }
    }
}


#pragma mark - Autolayout overrides

- (void)updateConstraints
{
    [super updateConstraints];
    
    //NSLayoutFormatOptions layoutFormatOptions = NSLayoutFormatAlignAllLeading;
    
    //[NSLayoutConstraint constraintsWithVisualFormat:<#(NSString *)#> options:<#(NSLayoutFormatOptions)#> metrics:<#(NSDictionary *)#> views:<#(NSDictionary *)#>]
}

@end
