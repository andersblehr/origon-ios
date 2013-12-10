//
//  OTableViewCell.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCell.h"

NSString * const kReuseIdentifierList = @"list";
NSString * const kReuseIdentifierUserSignIn = @"signIn";
NSString * const kReuseIdentifierUserActivation = @"activate";

NSString * const kViewKeySuffixLabel = @"Label";
NSString * const kViewKeySuffixInputField = @"Field";

CGFloat const kCellAnimationDuration = 0.3f;

static NSString * const kViewKeyTitleBanner = @"titleBanner";
static NSString * const kViewKeyPhotoFrame = @"photoFrame";
static NSString * const kViewKeyPhotoPrompt = @"photoPrompt";

static CGFloat const kImplicitFramePadding_iOS6x = 2.f;

static CGFloat const kShakeDuration = 0.05f;
static CGFloat const kShakeDelay = 0.f;
static CGFloat const kShakeTranslationX = 3.f;
static CGFloat const kShakeTranslationY = 0.f;
static CGFloat const kShakeRepeatCount = 3.f;


@implementation OTableViewCell

#pragma mark - Auxiliary methods

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
        _state = [OState s].viewController.state;
        
        if ([OMeta systemIs_iOS6x]) {
            self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            self.backgroundView.backgroundColor = [UIColor cellBackgroundColour];
            self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            self.selectedBackgroundView.backgroundColor = [UIColor selectedCellBackgroundColour];
            self.textLabel.backgroundColor = [UIColor clearColor];
            self.textLabel.textColor = [UIColor textColour];
            self.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            if (style == UITableViewCellStyleSubtitle) {
                self.textLabel.font = [UIFont listTextFont];
                self.detailTextLabel.font = [UIFont listDetailFont];
                self.detailTextLabel.textColor = [UIColor textColour];
            } else if (style == UITableViewCellStyleValue1) {
                self.textLabel.font = [UIFont alternateListFont];
                self.detailTextLabel.font = [UIFont alternateListFont];
                self.detailTextLabel.textColor = [UIColor lightGrayColor];
            }
        }
        
        if ([self isListCell]) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            _indexPath = indexPath;
            _listDelegate = (id<OTableViewListDelegate>)_state.viewController;

            [_listDelegate populateListCell:self atIndexPath:_indexPath];
        } else {
            _views = [NSMutableDictionary dictionary];
            _inputDelegate = (id<OTableViewInputDelegate>)_state.viewController;
        }
    }
    
    return self;
}


#pragma mark - Adding elements

- (void)addTitleField
{
    UIView *titleBannerView = [[UIView alloc] initWithFrame:CGRectZero];
    titleBannerView.backgroundColor = [UIColor titleBackgroundColour];
    [titleBannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:titleBannerView];
    [_views setObject:titleBannerView forKey:kViewKeyTitleBanner];
    
    [self addInputFieldForKey:_blueprint.titleKey];
    
    if (_blueprint.hasPhoto) {
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSData *photo = [_entity asMember].photo;
        
        if (photo) {
            [imageButton setImage:[UIImage imageWithData:photo] forState:UIControlStateNormal];
        } else {
            imageButton.backgroundColor = [UIColor whiteColor];
            
            UILabel *photoPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
            photoPrompt.backgroundColor = [UIColor imagePlaceholderBackgroundColour];
            photoPrompt.font = [UIFont detailFont];
            photoPrompt.text = [OStrings stringForKey:strPlaceholderPhoto];
            photoPrompt.textAlignment = NSTextAlignmentCenter;
            photoPrompt.textColor = [UIColor imagePlaceholderTextColour];
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
    OLabel *label = [[OLabel alloc] initWithKey:key centred:centred];
    
    [self.contentView addSubview:label];
    [_views setObject:label forKey:[key stringByAppendingString:kViewKeySuffixLabel]];
}


- (void)addInputFieldForKey:(NSString *)key
{
    OInputField *inputField = [_blueprint inputFieldWithKey:key delegate:_inputDelegate];
    
    [self.contentView addSubview:inputField];
    [_views setObject:inputField forKey:[key stringByAppendingString:kViewKeySuffixInputField]];
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
        
        [self addInputFieldForKey:detailKey];
    }
}


#pragma mark - Initialisation

- (id)initWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    self = [self initCommonsForReuseIdentifier:NSStringFromClass(entityClass) indexPath:nil];
    
    if (self) {
        _entity = entity;
        _entityClass = entityClass;
        _blueprint = [[OTableViewCellBlueprint alloc] initWithState:_state];
        _constrainer = [[OTableViewCellConstrainer alloc] initWithCell:self blueprint:_blueprint];
        
        [self addCellElements];
        [self.contentView setNeedsUpdateConstraints];
    }
    
    return self;
}


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath
{
    self = [self initCommonsForReuseIdentifier:reuseIdentifier indexPath:indexPath];
    
    if (self && ![self isListCell]) {
        _blueprint = [[OTableViewCellBlueprint alloc] initWithReuseIdentifier:reuseIdentifier];
        _constrainer = [[OTableViewCellConstrainer alloc] initWithCell:self blueprint:_blueprint];
        
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
    BOOL ignoreField = (_inputField != nil);
    
    for (NSString *key in _blueprint.displayableInputFieldKeys) {
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
    
    for (NSString *key in _blueprint.displayableInputFieldKeys) {
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
    return ([self inputFieldForKey:key].value != nil);
}


- (BOOL)hasValidValueForKey:(NSString *)key
{
    return [[self inputFieldForKey:key] hasValidValue];
}


- (BOOL)hasInvalidInputField
{
    return ([self nextInvalidInputField] != nil);
}


#pragma mark - Cell display

- (void)didLayoutSubviews
{
    if (![self isListCell]) {
        if (_blueprint.hasPhoto) {
            [_views[kViewKeyPhotoFrame] addDropShadowForPhotoFrame];
        }
        
        if (_editable) {
            for (NSString *key in _blueprint.displayableInputFieldKeys) {
                OInputField *inputField = [self inputFieldForKey:key];
                
                if (!_blueprint.fieldsShouldDeemphasiseOnEndEdit) {
                    inputField.hasEmphasis = YES;
                }
                
                if (!inputField.supportsMultiLineText) {
                    [inputField protectAgainstUnwantedAutolayoutAnimation:NO]; // Bug workaround
                }
            }
        }
        
        self.editing = [_state actionIs:kActionInput];
    }
}


- (void)toggleEditMode
{
    if ([_state actionIs:kActionRegister]) {
        [_state toggleAction:@[kActionDisplay, kActionRegister]];
    } else {
        [_state toggleAction:@[kActionDisplay, kActionEdit]];
    }
    
    self.editing = [_state actionIs:kActionEdit];
}


- (void)redrawIfNeeded
{
    if (_entity || _entityClass) {
        CGFloat implicitFramePadding = [OMeta systemIs_iOS6x] ? kImplicitFramePadding_iOS6x : 0.f;
        CGFloat desiredHeight = [_blueprint cellHeightWithEntity:_entity cell:self];
        
        if (abs(self.frame.size.height - (desiredHeight + implicitFramePadding)) > 0.5f) {
            [self setNeedsUpdateConstraints];
            
            [UIView animateWithDuration:kCellAnimationDuration animations:^{
                [self layoutIfNeeded];
                
                [_state.viewController.tableView beginUpdates];
                [_state.viewController.tableView endUpdates];
                
                CGRect frame = self.frame;
                frame.size.height = desiredHeight + implicitFramePadding;
                self.frame = frame;
                
                if ([OMeta systemIs_iOS6x]) {
                    [self.backgroundView redrawSeparatorsForTableViewCell];
                }
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


#pragma mark - Input handling

- (void)prepareForInput
{
    for (NSString *key in _blueprint.allInputFieldKeys) {
        OInputField *inputField = [self inputFieldForKey:key];
        
        if ([inputField respondsToSelector:@selector(prepareForInput)]) {
            [inputField prepareForInput];
        }
    }
}


- (void)processInput
{
    if ([_inputDelegate inputIsValid]) {
        if (![_state actionIs:kActionEdit]) {
            [self endEditing:YES];
        }
        
        [_inputDelegate processInput];
    } else {
        [self shakeCellVibrate:NO];
    }
}


#pragma mark - Content synchronising

- (void)readEntity
{
    if ([self isListCell]) {
        if ([_state isCurrent]) {
            [_listDelegate populateListCell:self atIndexPath:_indexPath];
        } else {
            [_state.viewController.dirtySections addObject:@(_indexPath.section)];
        }
    } else {
        for (NSString *key in _blueprint.allInputFieldKeys) {
            [self inputFieldForKey:key].value = [_entity valueForKey:key];
        }
        
        [self redrawIfNeeded];
    }
}


- (void)writeEntity
{
    if (!_entity) {
        _entity = [_inputDelegate inputEntity];
    }
    
    for (NSString *key in _blueprint.allInputFieldKeys) {
        [_entity setValue:[self inputFieldForKey:key].value forKey:key];
    }
    
    for (NSString *key in _blueprint.indirectKeys) {
        [_entity setValue:[_inputDelegate inputValueForIndirectKey:key] forKey:key];
    }
}


#pragma mark - Custom accessors

- (void)setInputField:(id)inputField
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


- (void)setFrame:(CGRect)frame
{
    if ([OMeta systemIs_iOS6x]) {
        frame.origin.x = -kDefaultCellPadding;
        frame.size.width = kScreenWidth + 2.f * kDefaultCellPadding;
    }
    
    [super setFrame:frame];
}


#pragma mark - UITableViewCell custom accessors

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    
    if (![self isListCell]) {
        for (NSString *key in _blueprint.allInputFieldKeys) {
            [self inputFieldForKey:key].editable = editing;
            
            if ([OValidator isAlternatingLabelKey:key]) {
                [self labelForKey:key].useAlternateText = editing;
            }
        }
    }
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if ([self isListCell]) {
        [super setHighlighted:highlighted animated:animated];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if ([self isListCell]) {
        [super setSelected:selected animated:animated];
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
