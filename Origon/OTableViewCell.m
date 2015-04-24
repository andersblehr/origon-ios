//
//  OTableViewCell.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewCell.h"

UITableViewCellStyle const kTableViewCellStyleDefault = UITableViewCellStyleSubtitle;
UITableViewCellStyle const kTableViewCellStyleValueList = UITableViewCellStyleValue1;
UITableViewCellStyle const kTableViewCellStyleInline = UITableViewCellStyleDefault;

NSString * const kReuseIdentifierList = @"list";

NSString * const kViewKeySuffixLabel = @"Label";
NSString * const kViewKeySuffixInputField = @"Field";
NSString * const kViewKeySuffixButton = @"Button";

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kViewKeyTitleBanner = @"titleBanner";
static NSString * const kViewKeyPhotoFrame = @"photoFrame";
static NSString * const kViewKeyPhotoPrompt = @"photoPrompt";

static NSString * const kButtonActionFormat = @"perform%@Action";

static CGFloat const kAccessoryWidth = 25.f;

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@interface OTableViewCell () {
@private
    OState *_state;
    OInputCellBlueprint *_blueprint;
    UITableViewCellStyle _style;
    
    NSMutableDictionary *_views;
    OInputField *_lastInputField;
}

@end


@implementation OTableViewCell

#pragma mark - Adding elements

- (void)addTitleField
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColour];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _views[kViewKeyTitleBanner] = titleBannerView;
    [self.contentView addSubview:titleBannerView];
    
    [self addInputFieldForKey:_constrainer.titleKey];
    
    if (_blueprint.hasPhoto) {
        UIButton *photoButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [photoButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSData *photo = [_entity valueForKey:kPropertyKeyPhoto];
        
        if (photo) {
            [photoButton setImage:[UIImage imageWithData:photo] forState:UIControlStateNormal];
        } else {
            photoButton.backgroundColor = [UIColor whiteColor];
            
            UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
            photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColour];
            photoPrompt.font = [UIFont detailFont];
            photoPrompt.text = NSLocalizedString(kPropertyKeyPhoto, kStringPrefixPlaceholder);
            photoPrompt.textAlignment = NSTextAlignmentCenter;
            photoPrompt.textColor = [UIColor imagePlaceholderTextColour];
            [photoPrompt setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            _views[kViewKeyPhotoPrompt] = photoPrompt;
            [photoButton addSubview:photoPrompt];
        }
        
        _views[kViewKeyPhotoFrame] = photoButton;
        [self.contentView addSubview:photoButton];
    }
}


- (void)addLabelForKey:(NSString *)key centred:(BOOL)centred
{
    OLabel *label = [[OLabel alloc] initWithKey:key centred:centred];
    
    _views[[key stringByAppendingString:kViewKeySuffixLabel]] = label;
    [self.contentView addSubview:label];
}


- (void)addInputFieldForKey:(NSString *)key
{
    OInputField *inputField = [_constrainer inputFieldWithKey:key];
    
    _views[[key stringByAppendingString:kViewKeySuffixInputField]] = inputField;
    [self.contentView addSubview:inputField];
}


- (void)addButtonForKey:(NSString *)key
{
    OButton *button = [[OButton alloc] initWithTitle:NSLocalizedString(key, kStringPrefixTitle) target:_inputCellDelegate action:NSSelectorFromString([NSString stringWithFormat:kButtonActionFormat, [key stringByCapitalisingFirstLetter]])];
    
    _views[[key stringByAppendingString:kViewKeySuffixButton]] = button;
    [self.contentView addSubview:button];
}


#pragma mark - Cell composition

- (void)addCellElements
{
    _views = [NSMutableDictionary dictionary];
    
    if (_isInputCell) {
        if (_constrainer.titleKey) {
            if (_blueprint.fieldsAreLabeled) {
                [self addTitleField];
            } else {
                [self addLabelForKey:_constrainer.titleKey centred:YES];
            }
        }
        
        for (NSString *detailKey in _constrainer.detailKeys) {
            if (_blueprint.fieldsAreLabeled) {
                [self addLabelForKey:detailKey centred:NO];
            }
            
            [self addInputFieldForKey:detailKey];
        }
        
        for (NSString *buttonKey in _blueprint.buttonKeys) {
            [self addButtonForKey:buttonKey];
        }
        
        self.editable = [_state actionIs:kActionInput];
    } else if (_isInlineCell) {
        [self addInputFieldForKey:_constrainer.titleKey];
    }
}


#pragma mark - Initialisation

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier state:(OState *)state
{
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _state = state;
        _style = style;
        _isInputCell = ![reuseIdentifier hasPrefix:kReuseIdentifierList];
        
        if (!_isInputCell) {
            _isInlineCell = style == kTableViewCellStyleInline;
            _selectable = ![_state actionIs:kActionInput];
        }
    }
    
    return self;
}


- (instancetype)initWithEntity:(id<OEntity>)entity delegate:(id)delegate
{
    OState *state = ((OTableViewController *)delegate).state;
    
    self = [self initWithStyle:kTableViewCellStyleDefault reuseIdentifier:NSStringFromClass([entity entityClass]) state:state];
    
    if (self) {
        _entity = entity;
        _inputCellDelegate = delegate;
        _blueprint = [_inputCellDelegate inputCellBlueprint];
        _constrainer = [[OInputCellConstrainer alloc] initWithCell:self blueprint:_blueprint delegate:delegate];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    OState *state = ((OTableViewController *)delegate).state;
    
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier state:state];
    
    if (self && (_isInputCell || _isInlineCell)) {
        if (_isInputCell) {
            _inputCellDelegate = delegate;
            _blueprint = [_inputCellDelegate inputCellBlueprint];
        } else if (_isInlineCell) {
            _blueprint = [OInputCellBlueprint inlineCellBlueprint];
        }
        
        _constrainer = [[OInputCellConstrainer alloc] initWithCell:self blueprint:_blueprint delegate:delegate];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


#pragma mark - UI element access

- (OLabel *)labelForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (OInputField *)inputFieldForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixInputField]];
}


- (OButton *)buttonForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixButton]];
}


- (OInputField *)nextInputField
{
    OInputField *inputField = nil;
    BOOL ignoreField = _inputField ? YES : NO;
    
    for (NSString *key in _constrainer.inputKeys) {
        if (ignoreField) {
            ignoreField = ![key isEqualToString:_inputField.key];
        } else {
            if (!inputField && [self inputFieldForKey:key].editable) {
                inputField = [self inputFieldForKey:key];
            }
        }
    }
    
    return inputField;
}


- (OInputField *)nextInvalidInputField
{
    OInputField *invalidInputField = nil;
    
    for (NSString *key in _constrainer.inputKeys) {
        OInputField *inputField = [self inputFieldForKey:key];
        
        if (!invalidInputField && ![inputField hasValidValue]) {
            invalidInputField = inputField;
        }
    }
    
    return invalidInputField;
}


- (OInputField *)inlineField
{
    return _isInlineCell ? [self inputFieldForKey:_constrainer.titleKey] : nil;
}


#pragma mark - Meta & validation

- (BOOL)styleIsDefault
{
    return _style == kTableViewCellStyleDefault;
}


- (BOOL)hasInputField:(id)inputField
{
    return [[_views allValues] containsObject:inputField];
}


- (BOOL)hasValueForKey:(NSString *)key
{
    return [self inputFieldForKey:key].value ? YES : NO;
}


- (BOOL)hasValidValueForKey:(NSString *)key
{
    return [[self inputFieldForKey:key] hasValidValue];
}


#pragma mark - Cell behaviour

- (void)prepareForDisplay
{
    if (_isInputCell) {
        if (_blueprint.hasPhoto) {
            [_views[kViewKeyPhotoFrame] addDropShadowForPhotoFrame];
        }
        
        if (_editable) {
            for (NSString *key in _constrainer.inputKeys) {
                OInputField *inputField = [self inputFieldForKey:key];
                
                if (!_blueprint.fieldsShouldDeemphasiseOnEndEdit) {
                    inputField.hasEmphasis = YES;
                }
            }
        }
    }
}


- (void)toggleEditMode
{
    if ([_state actionIs:kActionRegister]) {
        [_state toggleAction:@[kActionDisplay, kActionRegister]];
    } else {
        [_state toggleAction:@[kActionDisplay, kActionEdit]];
    }
    
    self.editable = [_state actionIs:kActionEdit];
}


- (void)clearInputFields
{
    if (_isInputCell && _editable) {
        for (NSString *key in _constrainer.inputKeys) {
            [self inputFieldForKey:key].value = nil;
        }
    }
}


- (void)redrawIfNeeded
{
    if (_isInputCell) {
        CGFloat desiredHeight = [_constrainer heightOfInputCell];
        
        if (fabs(self.frame.size.height - desiredHeight) > 0.5f) {
            [self setNeedsUpdateConstraints];
            
            if ([OMeta iOSVersionIs:@"7"]) {
                [self layoutIfNeeded];
            }
            
            [UIView animateWithDuration:kCellAnimationDuration animations:^{
                if (![OMeta iOSVersionIs:@"7"]) {
                    [self layoutIfNeeded];
                }
                
#if !CGFLOAT_IS_DOUBLE // Compiled for 32-bit
                [_state.viewController.tableView beginUpdates];
                [_state.viewController.tableView endUpdates];
#endif
                CGRect frame = self.frame;
                frame.size.height = desiredHeight;
                self.frame = frame;
                
#if CGFLOAT_IS_DOUBLE // Compiled for 64-bit
                [_state.viewController.tableView beginUpdates];
                [_state.viewController.tableView endUpdates];
#endif
            }];
        }
    }
}


- (void)resumeFirstResponder
{
    [_lastInputField becomeFirstResponder];
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
        } completion:nil];
    }];
}


#pragma mark - Data & input handling

- (void)readData
{
    if (_isInputCell) {
        for (NSString *key in _constrainer.inputKeys) {
            [self inputFieldForKey:key].value = [_entity valueForKey:key];
        }
        
        [self redrawIfNeeded];
    } else {
        NSIndexPath *indexPath = [_state.viewController.tableView indexPathForCell:self];
        NSInteger sectionKey = [_state.viewController sectionKeyForIndexPath:indexPath];
        
        [_state.viewController reloadSectionWithKey:sectionKey];
    }
}


- (void)prepareForInput
{
    for (NSString *key in _constrainer.inputKeys) {
        OInputField *inputField = [self inputFieldForKey:key];
        
        if ([inputField respondsToSelector:@selector(prepareForInput)]) {
            [inputField prepareForInput];
        }
    }
}


- (void)processInputShouldValidate:(BOOL)shouldValidate
{
    BOOL inputIsValid = !shouldValidate || [_inputCellDelegate inputIsValid];
    
    if (inputIsValid) {
        if (![_state actionIs:kActionEdit]) {
            [self endEditing:YES];
        }
        
        [_inputCellDelegate processInput];
    } else {
        [self shakeCellVibrate:NO];
    }
}


- (void)writeInput
{
    for (NSString *key in _constrainer.inputKeys) {
        [_entity setValue:[self inputFieldForKey:key].value forKey:key];
    }
    
    if (![_entity isCommitted]) {
        BOOL shouldCommit = YES;
        
        if ([_inputCellDelegate respondsToSelector:@selector(shouldCommitEntity:)]) {
            shouldCommit = [_inputCellDelegate shouldCommitEntity:_entity];
        }
        
        if (shouldCommit) {
            [_entity commit];
            
            if ([_inputCellDelegate respondsToSelector:@selector(didCommitEntity:)]) {
                [_inputCellDelegate didCommitEntity:_entity];
            }
        }
    }
}


#pragma mark - Miscellaneous

- (void)setDestinationId:(NSString *)destinationId selectableDuringInput:(BOOL)selectableDuringInput
{
    if (!_destinationId || ![destinationId isEqualToString:_destinationId]) {
        BOOL destinationIsEligible = ![_state actionIs:kActionInput] || selectableDuringInput;
        
        if (destinationIsEligible && _entity) {
            NSString *destinationStateId = [OState stateIdForViewControllerWithIdentifier:destinationId target:_entity];
            
            destinationIsEligible = [_state isValidDestinationStateId:destinationStateId];
        }
        
        if (destinationIsEligible) {
            _destinationId = destinationId;
            _selectableDuringInput = selectableDuringInput;
            _selectable = YES;
            
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            _selectable = NO;
            
            self.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}


- (void)bumpCheckedState
{
    if (_partiallyChecked) {
        self.partiallyChecked = NO;
    } else {
        self.checkedState = ++_checkedState % _checkedStateAccessoryViews.count;
    }
}


#pragma mark - Custom accessors

- (void)setDestinationId:(NSString *)destinationId
{
    if (destinationId) {
        [self setDestinationId:destinationId selectableDuringInput:NO];
    } else {
        _destinationId = nil;
        
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}


- (void)setInputField:(OInputField *)inputField
{
    if (_inputField.hasEmphasis && _blueprint.fieldsShouldDeemphasiseOnEndEdit) {
        _inputField.hasEmphasis = NO;
    }

    _lastInputField = _inputField;
    _inputField = inputField;
    
    if (_inputField && !_inputField.hasEmphasis) {
        _inputField.hasEmphasis = YES;
    }
    
    [self redrawIfNeeded];
}


- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    if (_isInputCell) {
        for (NSString *key in _constrainer.inputKeys) {
            [self inputFieldForKey:key].editable = editable;
            
            if ([OValidator isAlternatingLabelKey:key]) {
                [self labelForKey:key].useAlternateText = editable;
            }
        }
    }
}


- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    _partiallyChecked = NO;
    
    if (_checked) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    self.tintColor = [UIColor globalTintColour];
}


- (void)setPartiallyChecked:(BOOL)partiallyChecked
{
    _partiallyChecked = partiallyChecked;
    
    if (_partiallyChecked) {
        if (self.accessoryType == UITableViewCellAccessoryNone) {
            self.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
        self.tintColor = [UIColor tonedDownTextColour];
    } else {
        self.tintColor = [UIColor globalTintColour];
    }
}


- (void)setCheckedState:(NSInteger)checkedState
{
    if (checkedState < _checkedStateAccessoryViews.count) {
        _checkedState = checkedState;
        
        if (_checkedStateAccessoryViews[checkedState] != [NSNull null]) {
            self.accessoryView = _checkedStateAccessoryViews[checkedState];
        } else {
            self.accessoryView = nil;
        }
        
        if ([self.accessoryView isKindOfClass:[UILabel class]]) {
            ((UILabel *)self.accessoryView).textColor = self.tintColor;
        }
    }
}


- (void)setNotificationView:(UIView *)notificationView
{
    if (_notificationView && !notificationView) {
        [_notificationView removeFromSuperview];
    }
    
    _notificationView = notificationView;
    
    if (_notificationView) {
        if ([_notificationView isKindOfClass:[UILabel class]]) {
            UILabel *notificationLabel = (UILabel *)_notificationView;
            notificationLabel.font = [UIFont notificationFont];
            notificationLabel.textColor = [UIColor notificationColour];
        } else {
            _notificationView.tintColor = [UIColor notificationColour];
        }
        
        CGRect contentFrame = self.contentView.frame;
        CGRect notificationFrame = _notificationView.frame;
        notificationFrame.origin.x = contentFrame.size.width - notificationFrame.size.width - kDefaultCellPadding;
        notificationFrame.origin.y = (contentFrame.size.height - notificationFrame.size.height) / 2.f;
        
        if (self.accessoryView) {
            notificationFrame.origin.x -= self.accessoryView.frame.size.width;
        } else if (self.accessoryType != UITableViewCellAccessoryNone) {
            notificationFrame.origin.x -= kAccessoryWidth;
        }
        
        _notificationView.frame = notificationFrame;
        
        [self.contentView addSubview:_notificationView];
    }
}


- (void)setEmbeddedButton:(OButton *)actionButton
{
    _embeddedButton = actionButton;
    _embeddedButton.embeddingCell = self;
    
    if (actionButton) {
        [_embeddedButton addTarget:self.state.viewController action:@selector(didTapEmbeddedButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    self.notificationView = _embeddedButton;
}


#pragma mark - UITableViewCell custom accessors

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
    }
}


- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    if ([self.accessoryView isKindOfClass:[UILabel class]]) {
        ((UILabel *)self.accessoryView).textColor = tintColor;
    }
}


#pragma mark - UIView overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_notificationView && [self styleIsDefault]) {
        for (UILabel *textLabel in @[self.textLabel, self.detailTextLabel]) {
            CGRect textLabelFrame = textLabel.frame;
            textLabelFrame.size.width += kDefaultCellPadding;
            
            CGRect intersection = CGRectIntersection(textLabelFrame, _notificationView.frame);
            
            if (!CGRectIsNull(intersection)) {
                textLabelFrame = textLabel.frame;
                textLabelFrame.size.width -= intersection.size.width;
                textLabel.frame = textLabelFrame;
            }
        }
    }
}


- (void)updateConstraints
{
    [super updateConstraints];
    
    if (_isInputCell || _isInlineCell) {
        [self removeConstraints:[self constraints]];
        
        NSDictionary *alignedConstraints = [_constrainer constraintsWithAlignmentOptions];
        
        for (NSNumber *alignmentOptions in [alignedConstraints allKeys]) {
            NSUInteger options = [alignmentOptions integerValue];
            NSArray *constraintsWithOptions = alignedConstraints[alignmentOptions];
            
            for (NSString *visualConstraints in constraintsWithOptions) {
                [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraints options:options metrics:nil views:_views]];
            }
        }
    }
}

@end
