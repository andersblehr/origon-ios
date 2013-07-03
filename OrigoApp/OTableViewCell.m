//
//  OTableViewCell.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCell.h"

#import <AudioToolbox/AudioToolbox.h>

#import "UIColor+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCellBlueprint.h"
#import "OTableViewCellConstrainer.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OTableViewController.h"

NSString * const kReuseIdentifierList = @"list";
NSString * const kReuseIdentifierUserSignIn = @"signIn";
NSString * const kReuseIdentifierUserActivation = @"activate";

NSString * const kViewKeySuffixLabel = @"Label";
NSString * const kViewKeySuffixTextField = @"Field";

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kViewKeyTitleBanner = @"titleBanner";
static NSString * const kViewKeyPhotoFrame = @"photoFrame";
static NSString * const kViewKeyPhotoPrompt = @"photoPrompt";

static CGFloat const kLabelDetailSpacing = 3.f;
static CGFloat const kImplicitFramePadding = 2.f;

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@interface OTableViewCell ()

@property (strong, nonatomic) OState *state;

@end


@implementation OTableViewCell

#pragma mark - Auxiliary methods

- (BOOL)isListCell
{
    return [self.reuseIdentifier hasPrefix:kReuseIdentifierList];
}


- (id)initCommonsForReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath
{
    UITableViewCellStyle style = UITableViewCellStyleSubtitle;
    
    if ([reuseIdentifier hasPrefix:kReuseIdentifierList]) {
        id listDelegate = (id<OTableViewListDelegate>)[OState s].viewController;
        
        if ([listDelegate respondsToSelector:@selector(styleForIndexPath:)]) {
            style = [listDelegate styleForIndexPath:indexPath];
        }
    }
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.detailTextLabel.font = [UIFont detailFont];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textLabel.backgroundColor = [UIColor cellBackgroundColor];
        self.textLabel.font = [UIFont titleFont];
        
        _state = [OState s].viewController.state;
        
        if ([self isListCell]) {
            _indexPath = indexPath;
            _selectable = YES;
            _listDelegate = (id<OTableViewListDelegate>)_state.viewController;
            
            [_listDelegate populateListCell:self atIndexPath:_indexPath];
        } else {
            _views = [[NSMutableDictionary alloc] init];
            _selectable = [_state actionIs:kActionList];
            _inputDelegate = (id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate>)_state.viewController;
        }
        
        if (_selectable) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return self;
}


#pragma mark - Adding elements

- (void)addTitleField
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColor];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_views setObject:titleBannerView forKey:kViewKeyTitleBanner];
    
    [self addTextFieldForKey:_blueprint.titleKey];
    
    if (_blueprint.hasPhoto) {
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
        NSData *photo = [_entity asMember].photo;
        
        if (photo) {
            [imageButton setImage:[UIImage imageWithData:photo] forState:UIControlStateNormal];
        } else {
            imageButton.backgroundColor = [UIColor whiteColor];
            [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
            photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColor];
            photoPrompt.font = [UIFont labelFont];
            photoPrompt.text = [OStrings stringForKey:strPlaceholderPhoto];
            photoPrompt.textAlignment = NSTextAlignmentCenter;
            photoPrompt.textColor = [UIColor imagePlaceholderTextColor];
            [photoPrompt setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [imageButton addSubview:photoPrompt];
            [_views setObject:photoPrompt forKey:kViewKeyPhotoPrompt];
        }
        
        [self.contentView addSubview:imageButton];
        [_views setObject:imageButton forKey:kViewKeyPhotoFrame];
    }
}


- (void)addLabelForKey:(NSString *)key centred:(BOOL)centred
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont labelFont];
    label.hidden = YES;
    label.text = [OStrings labelForKey:key];
    label.textAlignment = centred ? NSTextAlignmentCenter : NSTextAlignmentRight;
    label.textColor = [UIColor labelTextColor];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (void)addTextFieldForKey:(NSString *)key
{
    id textField = [_blueprint textFieldWithKey:key delegate:_inputDelegate];
    
    [self.contentView addSubview:textField];
    [_views setObject:textField forKey:[key stringByAppendingString:kViewKeySuffixTextField]];
}


#pragma mark - Cell composition

- (void)addCellElements
{
    if (_blueprint.titleKey) {
        if (_blueprint.fieldsAreLabeled) {
            [self addTitleField];
        } else {
            [self addLabelForKey:_blueprint.titleKey centred:YES];
        }
    }
    
    for (NSString *detailKey in _blueprint.detailKeys) {
        if (_blueprint.fieldsAreLabeled) {
            [self addLabelForKey:detailKey centred:NO];
        }
        
        [self addTextFieldForKey:detailKey];
    }
}


#pragma mark - Initialisation

- (id)initWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    self = [self initCommonsForReuseIdentifier:NSStringFromClass(entityClass) indexPath:nil];
    
    if (self) {
        self.entity = entity;
        self.editing = !_selectable;
        
        _entityClass = entityClass;
        _blueprint = [OTableViewCellBlueprint blueprintWithEntityClass:entityClass];
        _constrainer = [[OTableViewCellConstrainer alloc] initWithBlueprint:_blueprint cell:self];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath
{
    self = [self initCommonsForReuseIdentifier:reuseIdentifier indexPath:indexPath];
    
    if (self && ![self isListCell]) {
        _blueprint = [OTableViewCellBlueprint blueprintWithReuseIdentifier:reuseIdentifier];
        _constrainer = [[OTableViewCellConstrainer alloc] initWithBlueprint:_blueprint cell:self];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


#pragma mark - Text field & text view access

- (id)textFieldForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixTextField]];
}


- (id)labelForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (id)nextInputField
{
    NSArray *keys = _blueprint.allTextFieldKeys;
    NSInteger indexOfTextField = _inputField ? [keys indexOfObject:[_inputField key]] : -1;
    NSString *inputFieldKey = nil;
    UIView *inputField = nil;
    
    BOOL inputFieldIsEditable = NO;
    
    for (int i = indexOfTextField + 1; ((i < [keys count]) && !inputFieldIsEditable); i++) {
        inputFieldKey = [keys[i] stringByAppendingString:kViewKeySuffixTextField];
        inputField = _views[inputFieldKey];
        
        if ([inputField isKindOfClass:OTextField.class]) {
            inputFieldIsEditable = ((OTextField *)inputField).enabled;
        } else if ([inputField isKindOfClass:OTextView.class]) {
            inputFieldIsEditable = ((OTextView *)inputField).editable;
        }
    }
    
    return inputFieldIsEditable ? inputField : nil;
}


#pragma mark - Meta & validation

- (BOOL)isTitleKey:(NSString *)key
{
    return [key isEqualToString:_blueprint.titleKey];
}


- (BOOL)hasValueForKey:(NSString *)key
{
    return [[self textFieldForKey:key] hasValue];
}


- (BOOL)hasValidValueForKey:(NSString *)key
{
    return [[self textFieldForKey:key] hasValidValue];
}


#pragma mark - Cell display & effects

- (void)willAppearTrailing:(BOOL)trailing
{
    [self.backgroundView addDropShadowForTableViewCellTrailing:trailing];
    
    if (_blueprint.hasPhoto) {
        [_views[kViewKeyPhotoFrame] addDropShadowForPhotoFrame];
    }
    
    if (_editable && !_blueprint.fieldsShouldDeemphasiseOnEndEdit) {
        for (NSString *key in [_views allKeys]) {
            id view = _views[key];
            
            if ([view isKindOfClass:OTextField.class] || [view isKindOfClass:OTextView.class]) {
                [view setHasEmphasis:YES];
            }
        }
    }
}


- (void)toggleEditMode
{
    [_state toggleAction:@[kActionDisplay, kActionEdit]];
    
    self.editing = [_state actionIs:kActionEdit] || _editable;
}


- (void)redrawIfNeeded
{
    if (_entity || _entityClass) {
        CGFloat desiredHeight = [_blueprint heightForCell:self];
        
        if (abs(self.frame.size.height - (desiredHeight + kImplicitFramePadding)) > 0.5f) {
            [UIView animateWithDuration:kCellAnimationDuration animations:^{
                [(UITableView *)self.superview beginUpdates];
                CGRect frame = self.frame;
                frame.size.height = desiredHeight + kImplicitFramePadding;
                self.frame = frame;
                [(UITableView *)self.superview endUpdates];
                
                [self setNeedsUpdateConstraints];
                [self layoutIfNeeded];
                [self.backgroundView redrawDropShadow];
            }];
        }
    }
}


- (void)shakeCellVibrate:(BOOL)vibrate
{
    if (vibrate) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    
    CGAffineTransform translateRight = CGAffineTransformTranslate(CGAffineTransformIdentity, kShakeTranslationX, kShakeTranslationY);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -kShakeTranslationX, kShakeTranslationY);
    
    self.transform = translateLeft;
    
    [UIView animateWithDuration:kShakeDuration delay:kShakeDelay options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:kShakeRepeatCount];
        
        self.transform = translateRight;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:kShakeDuration delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:NULL];
    }];
}


- (void)processInput
{
    if ([_inputDelegate inputIsValid]) {
        if (![_state actionIs:kActionEdit]) {
            [_state.viewController.view endEditing:YES];
        }
        
        [_inputDelegate processInput];
    } else {
        [self shakeCellVibrate:NO];
    }
}


#pragma mark - Synchronising cell content with entity

- (void)readEntity
{
    if ([self isListCell]) {
        [_listDelegate populateListCell:self atIndexPath:_indexPath];
    } else {
        for (NSString *key in _blueprint.allTextFieldKeys) {
            id textField = [self textFieldForKey:key];
            id value = [_entity valueForKey:key];
            
            if (value) {
                if ([value isKindOfClass:NSString.class]) {
                    [textField setText:value];
                } else if ([value isKindOfClass:NSDate.class]) {
                    [textField setDate:value];
                }
            } else {
                [textField setText:@""];
            }
        }
        
        [self redrawIfNeeded];
    }
}


- (void)writeEntity
{
    if (!_entity) {
        _entity = [_inputDelegate targetEntity];
    }
    
    for (NSString *key in _blueprint.allTextFieldKeys) {
        id textField = [self textFieldForKey:key];
        
        if ([textField hasValue]) {
            if ([textField isDateField]) {
                [_entity setValue:[textField date] forKey:key];
            } else {
                [_entity setValue:[textField textValue] forKey:key];
            }
        }
    }
    
    for (NSString *key in _blueprint.indirectKeys) {
        [_entity setValue:[_inputDelegate inputValueForIndirectKey:key] forKey:key];
    }
}


#pragma mark - Custom accessors

- (void)setInputField:(id)inputField
{
    if (_inputField && [_inputField hasEmphasis] && _blueprint.fieldsShouldDeemphasiseOnEndEdit) {
        [_inputField setHasEmphasis:NO];
    }

    _inputField = inputField;
    
    if (_inputField && ![_inputField hasEmphasis]) {
        [_inputField setHasEmphasis:YES];
    }
    
    [self redrawIfNeeded];
}


- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    self.editing = editable;
}


- (void)setChecked:(BOOL)checked
{
    if (checked) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}


#pragma mark - UIView overrides

- (void)updateConstraints
{
    [super updateConstraints];

    if (![self isListCell]) {
        [self.contentView removeConstraints:[self.contentView constraints]];
        
        NSDictionary *alignedConstraints = [_constrainer constraintsWithAlignmentOptions];
        
        for (NSNumber *alignmentOptions in [alignedConstraints allKeys]) {
            NSUInteger options = [alignmentOptions integerValue];
            NSArray *constraintsWithOptions = alignedConstraints[alignmentOptions];
            
            for (NSString *visualConstraints in constraintsWithOptions) {
                [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraints options:options metrics:nil views:_views]];
            }
        }
    }
}


#pragma mark - UITableViewCell custom accessors

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    
    for (UIView *view in [_views allValues]) {
        if ([view isKindOfClass:OTextField.class]) {
            ((OTextField *)view).enabled = editing;
        } else if ([view isKindOfClass:OTextView.class]) {
            ((OTextView *)view).editable = editing;
            ((OTextView *)view).userInteractionEnabled = editing;
        }
    }
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (_selectable) {
        [super setHighlighted:highlighted animated:animated];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selectable) {
        [super setSelected:selected animated:animated];
        
        for (UIView *view in [_views allValues]) {
            if ([view isKindOfClass:UILabel.class]) {
                if (selected) {
                    ((UILabel *)view).textColor = [UIColor selectedLabelTextColor];
                } else {
                    ((UILabel *)view).textColor = [UIColor labelTextColor];
                }
            } else if ([view isKindOfClass:OTextField.class]) {
                ((OTextField *)view).selected = selected;
            } else if ([view isKindOfClass:OTextView.class]) {
                ((OTextView *)view).selected = selected;
            }
        }
    }
}


#pragma mark - OEntityObservingDelegate conformance

- (void)entityDidChange
{
    [self readEntity];
    [self redrawIfNeeded];
    
    if (_observer) {
        [_observer entityDidChange];
    }
}

@end
