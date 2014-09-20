//
//  OTableViewCell.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewCell.h"

NSString * const kReuseIdentifierList = @"list";

NSString * const kViewKeySuffixLabel = @"Label";
NSString * const kViewKeySuffixInputField = @"Field";

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kViewKeyTitleBanner = @"titleBanner";
static NSString * const kViewKeyPhotoFrame = @"photoFrame";
static NSString * const kViewKeyPhotoPrompt = @"photoPrompt";

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@interface OTableViewCell () {
@private
    OState *_state;
    OInputCellBlueprint *_blueprint;
    
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
    
    [self.contentView addSubview:titleBannerView];
    [_views setObject:titleBannerView forKey:kViewKeyTitleBanner];
    
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
            
            [photoButton addSubview:photoPrompt];
            [_views setObject:photoPrompt forKey:kViewKeyPhotoPrompt];
        }
        
        [self.contentView addSubview:photoButton];
        [_views setObject:photoButton forKey:kViewKeyPhotoFrame];
    }
}


- (void)addLabelForKey:(NSString *)key centred:(BOOL)centred
{
    OLabel *label = [[OLabel alloc] initWithKey:key centred:centred];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (void)addInputFieldForKey:(NSString *)key
{
    OInputField *inputField = [_constrainer inputFieldWithKey:key];
    
    [self.contentView addSubview:inputField];
    [_views setObject:inputField forKey:[key stringByAppendingString:kViewKeySuffixInputField]];
}


#pragma mark - Cell composition

- (void)addCellElements
{
    _views = [NSMutableDictionary dictionary];
    
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
    
    self.editable = [_state actionIs:kActionInput];
}


#pragma mark - Initialisation

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier state:(OState *)state
{
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _state = state;
        
        if ([self isListCell]) {
            _selectable = ![_state actionIs:kActionInput];
        }
    }
    
    return self;
}


- (instancetype)initWithEntity:(id<OEntity>)entity delegate:(id)delegate
{
    OState *state = ((OTableViewController *)delegate).state;
    
    self = [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([entity entityClass]) state:state];
    
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
    
    if (self && ![self isListCell]) {
        _inputCellDelegate = delegate;
        _blueprint = [_inputCellDelegate inputCellBlueprint];
        _constrainer = [[OInputCellConstrainer alloc] initWithCell:self blueprint:_blueprint delegate:delegate];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


#pragma mark - Label & input view access

- (OLabel *)labelForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (OInputField *)inputFieldForKey:(NSString *)key
{
    return _views[[key stringByAppendingString:kViewKeySuffixInputField]];
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


#pragma mark - Meta & validation

- (BOOL)isListCell
{
    return [self.reuseIdentifier hasPrefix:kReuseIdentifierList];
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
    if (![self isListCell]) {
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
    if (![self isListCell] && _editable) {
        for (NSString *key in _constrainer.inputKeys) {
            [self inputFieldForKey:key].value = nil;
        }
    }
}


- (void)redrawIfNeeded
{
    if (![self isListCell]) {
        CGFloat desiredHeight = [_constrainer heightOfInputCell];
        
        if (abs(self.frame.size.height - desiredHeight) > 0.5f) {
            [self setNeedsUpdateConstraints];
            
            if ([[UIDevice currentDevice].systemVersion hasPrefix:@"7"]) {
                [self layoutIfNeeded];
            }
            
            [UIView animateWithDuration:kCellAnimationDuration animations:^{
                if (![[UIDevice currentDevice].systemVersion hasPrefix:@"7"]) {
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
        } completion:NULL];
    }];
}


#pragma mark - Data & input handling

- (void)readData
{
    if ([self isListCell]) {
        NSIndexPath *indexPath = [_state.viewController.tableView indexPathForCell:self];
        NSInteger sectionKey = [_state.viewController sectionKeyForIndexPath:indexPath];
        
        [_state.viewController reloadSectionWithKey:sectionKey];
    } else {
        for (NSString *key in _constrainer.inputKeys) {
            [self inputFieldForKey:key].value = [_entity valueForKey:key];
        }
        
        [self redrawIfNeeded];
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


#pragma mark - Custom accessors

- (void)setDestinationId:(NSString *)destinationId
{
    [self setDestinationId:destinationId selectableDuringInput:NO];
}


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
    
    if (![self isListCell]) {
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
    
    if (_checked) {
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


#pragma mark - OEntityObserver conformance

- (void)observeData
{
    [self readData];
    [self redrawIfNeeded];
    
    if (_observer) {
        [_observer observeData];
    }
}

@end
