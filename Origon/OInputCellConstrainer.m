//
//  OInputCellConstrainer.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OInputCellConstrainer.h"

static NSString * const kDelimitingSpace               = @"-10-";

static NSString * const kVConstraintsInitial           = @"V:|";
static NSString * const kVConstraintsInitialWithTitle  = @"V:|-44-";

static NSString * const kVConstraintsInlineCell        = @"V:|-10-[inlineCellContentField(25)]";
static NSString * const kHConstraintsInlineCell        = @"H:|-12-[inlineCellContentField]-12-|";

static NSString * const kVConstraintsElementTopmost    = @"[%@(%.f)]";
static NSString * const kVConstraintsElement           = @"-%.f-[%@(%.f)]";
static NSString * const kHConstraintsCentredLabel      = @"H:|-25-[%@]-25-|";
static NSString * const kHConstraintsCentredInputField = @"H:|-55-[%@]-55-|";

static NSString * const kVConstraintsTitleBanner       = @"V:|-(0)-[titleBanner(39)]";
static NSString * const kHConstraintsTitleBanner       = @"H:|-(0)-[titleBanner]-(0)-|";
static NSString * const kVConstraintsTitle             = @"[%@(24)]";
static NSString * const kHConstraintsTitle             = @"H:|-6-[%@]-6-|";
static NSString * const kHConstraintsTitleWithPhoto    = @"H:|-6-[%@]-6-[photoFrame(%.f)]-10-|";
static NSString * const kVConstraintsPhoto             = @"V:|-10-[photoFrame(%.f)]";
static NSString * const kVConstraintsPhotoPrompt       = @"V:|-3-[photoPrompt]-3-|";
static NSString * const kHConstraintsPhotoPrompt       = @"H:|-3-[photoPrompt]-3-|";

static NSString * const kVConstraintsLabel             = @"-%.f-[%@(%.f)]";
static NSString * const kVConstraintsInputField        = @"[%@(%.f)]";

static NSString * const kHConstraintsButtonInitial     = @"H:|-55-[%@]";
static NSString * const kHConstraintsButton            = @"-5-[%@(==%@)]";
static NSString * const kHConstraintsButtonFinal       = @"-55-|";

static NSString * const kHConstraints                  = @"H:|-10-[%@(%.f)]-3-[%@]-6-|";
static NSString * const kHConstraintsWithPhoto         = @"H:|-10-[%@(%.f)]-3-[%@]-6-[photoFrame]-10-|";

static CGFloat const kButtonHeight = 26.f;
static CGFloat const kButtonHeadroomHeight = 5.f;
static CGFloat const kPaddedPhotoFrameHeight = 75.f;
static CGFloat const kTitleOnlyInputCellOvershoot = 17.f;


@interface OInputCellConstrainer () {
@private
    OTableViewCell *_inputCell;
    
    id<OInputCellDelegate> _delegate;
}

@end


@implementation OInputCellConstrainer

#pragma mark - Auxiliary methods

- (CGFloat)widthWithKey:(NSString *)key prefix:(NSString *)prefix
{
    return [NSLocalizedString(key, prefix) sizeWithFont:[UIFont detailFont] maxWidth:CGFLOAT_MAX].width;
}


- (CGFloat)labelWidth
{
    CGFloat width = 0.f;
    
    for (NSString *key in _detailKeys) {
        if ([self shouldDisplayElementsForKey:key]) {
            width = MAX(width, [self widthWithKey:key prefix:kStringPrefixLabel]);
            
            if ([OValidator isAlternatingLabelKey:key]) {
                width = MAX(width, [self widthWithKey:key prefix:kStringPrefixAlternateLabel]);
            }
        }
    }
    
    return width + 1.f;
}


+ (CGFloat)heightOfInputCell:(OTableViewCell *)inputCell withConstrainer:(OInputCellConstrainer *)constrainer entity:(id<OEntity>)entity inputKeys:(NSArray *)inputKeys titleKey:(NSString *)titleKey delegate:(id)delegate
{
    CGFloat height = 2.f * kDefaultCellPadding;
    BOOL displaysDetailKeys = NO;
    
    for (NSString *key in inputKeys) {
        if ([key isEqualToString:titleKey]) {
            if (constrainer.blueprint.fieldsAreLabeled) {
                height += [UIFont titleFieldHeight] + kDefaultCellPadding;
            } else {
                height += [UIFont detailFieldHeight] + kDefaultCellPadding;
            }
        } else if ([delegate isReceivingInput] || [entity hasValueForKey:key]) {
            displaysDetailKeys = YES;
            
            if ([constrainer.blueprint.multiLineKeys containsObject:key]) {
                if (inputCell && inputCell.constrainer.didConstrain) {
                    height += [[inputCell inputFieldForKey:key] height];
                } else if ([entity hasValueForKey:key]) {
                    height += [OTextView heightWithText:[entity valueForKey:key] maxWidth:[constrainer labeledTextWidth]];
                } else {
                    height += [OTextView heightWithText:NSLocalizedString(key, kStringPrefixPlaceholder) maxWidth:[constrainer labeledTextWidth]];
                }
            } else {
                height += [UIFont detailFieldHeight];
            }
        }
    }
    
    if (constrainer.blueprint.buttonKeys) {
        height += kButtonHeight + kButtonHeadroomHeight;
    }
    
    if (constrainer.blueprint.hasPhoto) {
        height = MAX(height, kPaddedPhotoFrameHeight);
    } else if (constrainer.blueprint.fieldsAreLabeled && !displaysDetailKeys) {
        height -= kTitleOnlyInputCellOvershoot;
    }
    
    return height;
}


+ (id)displayableKeysFromKeys:(id)keys delegate:(id)delegate
{
    id displayableKeys = nil;
    BOOL needsArray = YES;
    
    if (keys) {
        if ([keys isKindOfClass:[NSString class]]) {
            keys = @[keys];
            needsArray = NO;
        }
        
        displayableKeys = [keys mutableCopy];
        
        if ([delegate respondsToSelector:@selector(isDisplayableFieldWithKey:)]) {
            for (NSString *key in keys) {
                if (![delegate isDisplayableFieldWithKey:key]) {
                    [displayableKeys removeObject:key];
                }
            }
        }
        
        if ([displayableKeys count] == 1 && !needsArray) {
            displayableKeys = displayableKeys[0];
        } else if (![displayableKeys count]) {
            displayableKeys = nil;
        }
    }
    
    return displayableKeys;
}


- (BOOL)shouldDisplayElementsForKey:(NSString *)key
{
    BOOL shouldDisplayElements = YES;
    
    if (_inputCell.entity) {
        id value = [_inputCell.entity valueForKey:key];
        
        if (value && [value isKindOfClass:[NSString class]]) {
            shouldDisplayElements = [value hasValue];
        } else if (!value) {
            shouldDisplayElements = NO;
        }
        
        shouldDisplayElements = shouldDisplayElements || [_inputCell.inputCellDelegate isReceivingInput];
    }
    
    return shouldDisplayElements;
}


- (void)configureElementsForKey:(NSString *)key
{
    OLabel *label = [_inputCell labelForKey:key];
    OInputField *inputField = [_inputCell inputFieldForKey:key];
    
    if (![inputField.text hasValue] && !inputField.didChange) {
        inputField.value = [_inputCell.entity valueForKey:key];
    }
    
    if ([self shouldDisplayElementsForKey:key]) {
        if (label && label.isHidden) {
            label.hidden = NO;
        }
        
        if (inputField && inputField.isHidden) {
            inputField.hidden = NO;
        }
    } else {
        if (label && !label.isHidden) {
            label.hidden = YES;
            label.frame = CGRectZero;
        }
        
        if (inputField && ![inputField isHidden]) {
            inputField.hidden = YES;
            inputField.frame = CGRectZero;
        }
    }
}


#pragma mark - Generating visual constraints strings

- (NSArray *)inlineCellConstraints
{
    NSArray *constraints = nil;
    
    if (_titleKey) {
        [self configureElementsForKey:_titleKey];
        
        constraints = @[kVConstraintsInlineCell, kHConstraintsInlineCell];
    }
    
    return constraints ? constraints : @[];
}


- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (_titleKey) {
        NSString *titleName = [_titleKey stringByAppendingString:kViewKeySuffixInputField];
        
        [self configureElementsForKey:_titleKey];
        
        [constraints addObject:kHConstraintsTitleBanner];
        [constraints addObject:kVConstraintsTitleBanner];
        
        if (_blueprint.hasPhoto) {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitleWithPhoto, titleName, kPhotoFrameWidth]];
            [constraints addObject:[NSString stringWithFormat:kVConstraintsPhoto, kPhotoFrameWidth]];
            [constraints addObject:kVConstraintsPhotoPrompt];
            [constraints addObject:kHConstraintsPhotoPrompt];
        } else {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitle, titleName]];
        }
    }
    
    return constraints;
}


- (NSArray *)labeledVerticalLabelConstraints
{
    NSString *constraints = nil;
    
    BOOL isTopmostLabel = YES;
    OInputField *precedingInputField = nil;

    for (NSString *key in _detailKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            if (!constraints) {
                if (_titleKey) {
                    constraints = kVConstraintsInitialWithTitle;
                } else {
                    constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
                }
            }
            
            NSString *constraint = nil;
            NSString *labelName = [key stringByAppendingString:kViewKeySuffixLabel];
            
            if (isTopmostLabel) {
                isTopmostLabel = NO;
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, labelName, [UIFont detailFieldHeight]];
            } else {
                CGFloat padding = 0.f;
                
                if (precedingInputField.supportsMultiLineText) {
                    padding = [precedingInputField height] - [UIFont detailFieldHeight];
                }
                
                constraint = [NSString stringWithFormat:kVConstraintsLabel, padding, labelName, [UIFont detailFieldHeight]];
            }
            
            precedingInputField = [_inputCell inputFieldForKey:key];
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : @[];
}


- (NSArray *)labeledVerticalInputFieldConstraints
{
    NSString *constraints = nil;
    
    if (_titleKey) {
        NSString *titleName = [_blueprint.titleKey stringByAppendingString:kViewKeySuffixInputField];
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTitle, titleName];
        
        constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    if (_detailKeys.count) {
        BOOL didInsertDelimiter = !_titleKey;
        
        for (NSString *key in _detailKeys) {
            [self configureElementsForKey:key];
            
            if ([self shouldDisplayElementsForKey:key]) {
                if (constraints && !didInsertDelimiter) {
                    constraints = [constraints stringByAppendingString:kDelimitingSpace];
                    didInsertDelimiter = YES;
                } else if (!constraints) {
                    constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
                }
                
                OInputField *inputField = [_inputCell inputFieldForKey:key];
                CGFloat inputFieldHeight = inputField.supportsMultiLineText ? [inputField height] : [UIFont detailFieldHeight];
                
                NSString *inputFieldName = [key stringByAppendingString:kViewKeySuffixInputField];
                NSString *constraint = [NSString stringWithFormat:kVConstraintsInputField, inputFieldName, inputFieldHeight];
                
                constraints = [constraints stringByAppendingString:constraint];
            }
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : @[];
}


- (NSArray *)labeledHorizontalConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    CGFloat labelWidth = [self labelWidth];
    NSInteger rowNumber = 0;
    
    for (NSString *key in _detailKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            NSString *labelName = [key stringByAppendingString:kViewKeySuffixLabel];
            NSString *inputFieldName = [key stringByAppendingString:kViewKeySuffixInputField];
            NSString *constraint = nil;
            
            if (_blueprint.hasPhoto && rowNumber++ < 2) {
                constraint = [NSString stringWithFormat:kHConstraintsWithPhoto, labelName, labelWidth, inputFieldName];
            } else {
                constraint = [NSString stringWithFormat:kHConstraints, labelName, labelWidth, inputFieldName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


- (NSArray *)centredVerticalConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    NSString *constraintsFormat = @"";
    
    BOOL isTopmostElement = YES;
    BOOL isBelowLabel = NO;
    
    for (NSString *key in _inputKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            if (![constraintsFormat hasValue]) {
                constraintsFormat = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
            }
            
            NSString *constraint = nil;
            NSString *elementName = nil;
            
            if ([_inputCell labelForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixLabel];
            } else if ([_inputCell inputFieldForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixInputField];
            }
            
            if (isTopmostElement) {
                isTopmostElement = NO;
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, elementName, [UIFont detailFieldHeight]];
            } else {
                CGFloat spacing = isBelowLabel ? kDefaultCellPadding / 3 : 1.f;
                constraint = [NSString stringWithFormat:kVConstraintsElement, spacing, elementName, [UIFont detailFieldHeight]];
            }
            
            constraintsFormat = [constraintsFormat stringByAppendingString:constraint];
            isBelowLabel = [elementName hasSuffix:kViewKeySuffixLabel];
        }
    }
    
    if (_blueprint.buttonKeys) {
        for (NSString *buttonKey in _blueprint.buttonKeys) {
            [constraints addObject:[constraintsFormat stringByAppendingString:[NSString stringWithFormat:kVConstraintsElement, kButtonHeadroomHeight, [buttonKey stringByAppendingString:kViewKeySuffixButton], [UIFont titleFieldHeight]]]];
        }
    } else {
        [constraints addObject:constraintsFormat];
    }
    
    return constraints;
}


- (NSArray *)centredHorizontalConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    for (NSString *key in _inputKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            NSString *constraint = nil;
            
            if ([_inputCell labelForKey:key]) {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixLabel];
                constraint = [NSString stringWithFormat:kHConstraintsCentredLabel, elementName];
            } else {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixInputField];
                constraint = [NSString stringWithFormat:kHConstraintsCentredInputField, elementName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    if (_blueprint.buttonKeys) {
        NSString *initialButtonKey = [[_blueprint.buttonKeys firstObject] stringByAppendingString:kViewKeySuffixButton];
        NSArray *postInitialButtonKeys = [_blueprint.buttonKeys subarrayWithRange:NSMakeRange(1, _blueprint.buttonKeys.count - 1)];
        
        NSString *buttonConstraints = [NSString stringWithFormat:kHConstraintsButtonInitial, initialButtonKey];
        
        for (NSString *buttonKey in postInitialButtonKeys) {
            buttonConstraints = [buttonConstraints stringByAppendingString:[NSString stringWithFormat:kHConstraintsButton, [buttonKey stringByAppendingString:kViewKeySuffixButton], initialButtonKey]];
        }
        
        [constraints addObject:[buttonConstraints stringByAppendingString:kHConstraintsButtonFinal]];
    }
    
    return constraints;
}


#pragma mark - Initialisation

- (instancetype)initWithCell:(OTableViewCell *)cell blueprint:(OInputCellBlueprint *)blueprint delegate:(id<OInputCellDelegate>)delegate
{
    self = [super init];
    
    if (self) {
        _inputCell = cell;
        _blueprint = blueprint;
        _delegate = delegate;
        
        _titleKey = [[self class] displayableKeysFromKeys:_blueprint.titleKey delegate:cell.inputCellDelegate];
        _detailKeys = [[self class] displayableKeysFromKeys:_blueprint.detailKeys delegate:cell.inputCellDelegate];
        
        if (_titleKey) {
            _inputKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _inputKeys = _detailKeys;
        }
    }
    
    return self;
}


#pragma mark - Retrieving constraints

- (NSDictionary *)constraintsWithAlignmentOptions
{
    NSMutableDictionary *constraints = [NSMutableDictionary dictionary];
    
    if (_blueprint) {
        NSNumber *allTrailingOption = @(NSLayoutFormatAlignAllTrailing);
        NSNumber *noAlignmentOption = @0;
        
        if (_blueprint.isInlineBlueprint) {
            constraints[noAlignmentOption] = [self inlineCellConstraints];
        } else if (_blueprint.fieldsAreLabeled) {
            NSMutableArray *allTrailingConstraints = [NSMutableArray array];
            [allTrailingConstraints addObjectsFromArray:[self labeledVerticalLabelConstraints]];
            
            NSMutableArray *nonAlignedConstraints = [NSMutableArray array];
            [nonAlignedConstraints addObjectsFromArray:[self titleConstraints]];
            [nonAlignedConstraints addObjectsFromArray:[self labeledVerticalInputFieldConstraints]];
            [nonAlignedConstraints addObjectsFromArray:[self labeledHorizontalConstraints]];
            
            constraints[allTrailingOption] = allTrailingConstraints;
            constraints[noAlignmentOption] = nonAlignedConstraints;
        } else {
            NSMutableArray *nonAlignedConstraints = [NSMutableArray array];
            [nonAlignedConstraints addObjectsFromArray:[self centredVerticalConstraints]];
            [nonAlignedConstraints addObjectsFromArray:[self centredHorizontalConstraints]];
            
            constraints[noAlignmentOption] = nonAlignedConstraints;
        }
        
        _didConstrain = YES;
        
//        int i = 0;
//        for (NSNumber *alignmentOptions in [constraints allKeys]) {
//            NSArray *constraintsWithOptions = [constraints objectForKey:alignmentOptions];
//            
//            for (NSString *visualConstraints in constraintsWithOptions) {
//                OLogDebug(@"\nVisual constraint (%d): %@", i++, visualConstraints);
//            }
//        }
    }
    
    return constraints;
}


#pragma mark - Dimensions computation

- (CGFloat)labeledTextWidth
{
    return [OMeta screenWidth] - 2 * kDefaultCellPadding - [self labelWidth] - kTextViewWidthAdjustment;
}


- (CGFloat)heightOfInputCell
{
    return [[self class] heightOfInputCell:_inputCell withConstrainer:self entity:_inputCell.entity inputKeys:_inputKeys titleKey:_titleKey delegate:_inputCell.inputCellDelegate];
}


+ (CGFloat)heightOfInputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate
{
    OInputCellBlueprint *blueprint = [delegate inputCellBlueprint];
    OInputCellConstrainer *constrainer = [[OInputCellConstrainer alloc] initWithCell:nil blueprint:blueprint delegate:delegate];
    
    NSString *titleKey = [self displayableKeysFromKeys:blueprint.titleKey delegate:delegate];
    NSArray *inputKeys = [self displayableKeysFromKeys:blueprint.inputKeys delegate:delegate];
    
    return [self heightOfInputCell:nil withConstrainer:constrainer entity:entity inputKeys:inputKeys titleKey:titleKey delegate:delegate];
}


#pragma mark - Input field instantiation

- (OInputField *)inputFieldWithKey:(NSString *)key
{
    OInputField *inputField = nil;
    
    if ([_blueprint.multiLineKeys containsObject:key]) {
        inputField = [[OTextView alloc] initWithKey:key constrainer:self delegate:_delegate];
    } else if ([_blueprint.inputKeys containsObject:key]) {
        inputField = [[OTextField alloc] initWithKey:key delegate:_delegate];
    }
    
    if (!inputField.isInlineField) {
        inputField.isTitleField = [key isEqualToString:_titleKey];
    }
    
    if ([OValidator isPhoneNumberKey:key]) {
        inputField.keyboardType = UIKeyboardTypePhonePad;
    } else if ([OValidator isEmailKey:key]) {
        inputField.keyboardType = UIKeyboardTypeEmailAddress;
    } else {
        inputField.keyboardType = UIKeyboardTypeDefault;
        
        if ([OValidator isNameKey:key]) {
            inputField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        } else if ([OValidator isPasswordKey:key]) {
            inputField.secureTextEntry = YES;
            ((OTextField *)inputField).clearsOnBeginEditing = YES;
        }
    }
    
    return inputField;
}

@end
