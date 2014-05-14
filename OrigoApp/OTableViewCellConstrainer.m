//
//  OTableViewCellConstrainer.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewCellConstrainer.h"

static NSString * const kDelimitingSpace               = @"-10-";

static NSString * const kVConstraintsInitial           = @"V:|";
static NSString * const kVConstraintsInitialWithTitle  = @"V:|-44-";

static NSString * const kVConstraintsElementTopmost    = @"[%@(%.f)]";
static NSString * const kVConstraintsElement           = @"-%.f-[%@(%.f)]";
static NSString * const kHConstraintsCentredLabel      = @"H:|-25-[%@]-25-|";
static NSString * const kHConstraintsCentredInputField = @"H:|-55-[%@]-55-|";

static NSString * const kVConstraintsTitleBanner_iOS6x = @"V:|-(-1)-[titleBanner(39)]";
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

static NSString * const kHConstraints                  = @"H:|-10-[%@(%.f)]-3-[%@]-6-|";
static NSString * const kHConstraintsWithPhoto         = @"H:|-10-[%@(%.f)]-3-[%@]-6-[photoFrame]-10-|";

static CGFloat const kPaddedPhotoFrameHeight = 75.f;


@interface OTableViewCellConstrainer () {
@private
    OTableViewCellBlueprint *_blueprint;
    OTableViewCell *_cell;
    
    CGFloat _labelWidth;
}

@end


@implementation OTableViewCellConstrainer

#pragma mark - Auxiliary methods

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
        
        if (([displayableKeys count] == 1) && !needsArray) {
            displayableKeys = displayableKeys[0];
        } else if (![displayableKeys count]) {
            displayableKeys = nil;
        }
    }

    return displayableKeys;
}


+ (CGFloat)heightOfCell:(OTableViewCell *)cell withBlueprint:(OTableViewCellBlueprint *)blueprint entity:(id<OEntity>)entity inputKeys:(NSArray *)inputKeys titleKey:(NSString *)titleKey delegate:(id)delegate
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    for (NSString *key in inputKeys) {
        if ([key isEqualToString:titleKey]) {
            if (blueprint.fieldsAreLabeled) {
                height += [UIFont titleFieldHeight] + kDefaultCellPadding;
            } else {
                height += [UIFont detailFieldHeight] + kDefaultCellPadding;
            }
        } else if ([delegate isReceivingInput] || [entity hasValueForKey:key]) {
            if ([blueprint.multiLineTextKeys containsObject:key]) {
                if (cell) {
                    height += [[cell inputFieldForKey:key] height];
                } else if ([entity hasValueForKey:key]) {
                    height += [OTextView heightWithText:[entity valueForKey:key] blueprint:blueprint];
                } else {
                    height += [OTextView heightWithText:NSLocalizedString(key, kStringPrefixPlaceholder) blueprint:blueprint];
                }
            } else {
                height += [UIFont detailFieldHeight];
            }
        }
    }
    
    if (blueprint.hasPhoto) {
        height = MAX(height, kPaddedPhotoFrameHeight);
    }
    
    return height;
}


- (BOOL)shouldDisplayElementsForKey:(NSString *)key
{
    BOOL shouldDisplayElements = YES;
    
    if (_cell.entity) {
        id value = [_cell.entity valueForKey:key];
        
        if (value && [value isKindOfClass:[NSString class]]) {
            shouldDisplayElements = [value hasValue];
        } else if (!value) {
            shouldDisplayElements = NO;
        }
        
        shouldDisplayElements = shouldDisplayElements || [_cell.inputDelegate isReceivingInput];
    }
    
    return shouldDisplayElements;
}


- (void)configureElementsForKey:(NSString *)key
{
    OLabel *label = [_cell labelForKey:key];
    OInputField *inputField = [_cell inputFieldForKey:key];
    
    if (!inputField.value) {
        inputField.value = [_cell.entity valueForKey:key];
    }
    
    if ([self shouldDisplayElementsForKey:key]) {
        if (label && label.isHidden) {
            label.hidden = NO;
        }
        
        if (inputField && inputField.isHidden) {
            inputField.hidden = NO;
            
            if (!inputField.supportsMultiLineText) {
                [inputField protectAgainstUnwantedAutolayoutAnimation:YES]; // Bug workaround
            }
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

- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (_titleKey) {
        NSString *titleName = [_titleKey stringByAppendingString:kViewKeySuffixInputField];
        
        [self configureElementsForKey:_titleKey];
        
        [constraints addObject:kHConstraintsTitleBanner];
        [constraints addObject:[OMeta systemIs_iOS6x] ? kVConstraintsTitleBanner_iOS6x : kVConstraintsTitleBanner];
        
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
            
            precedingInputField = [_cell inputFieldForKey:key];
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : [NSArray array];
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
    
    if ([_detailKeys count]) {
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
                
                OInputField *inputField = [_cell inputFieldForKey:key];
                CGFloat inputFieldHeight = inputField.supportsMultiLineText ? [inputField height] : [UIFont detailFieldHeight];
                
                NSString *inputFieldName = [key stringByAppendingString:kViewKeySuffixInputField];
                NSString *constraint = [NSString stringWithFormat:kVConstraintsInputField, inputFieldName, inputFieldHeight];
                
                constraints = [constraints stringByAppendingString:constraint];
            }
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : [NSArray array];
}


- (NSArray *)labeledHorizontalConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSInteger rowNumber = 0;
    
    for (NSString *key in _detailKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            NSString *labelName = [key stringByAppendingString:kViewKeySuffixLabel];
            NSString *inputFieldName = [key stringByAppendingString:kViewKeySuffixInputField];
            NSString *constraint = nil;
            
            if (_blueprint.hasPhoto && (rowNumber++ < 2)) {
                constraint = [NSString stringWithFormat:kHConstraintsWithPhoto, labelName, _labelWidth, inputFieldName];
            } else {
                constraint = [NSString stringWithFormat:kHConstraints, labelName, _labelWidth, inputFieldName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


- (NSArray *)centredVerticalConstraints
{
    NSString *constraints = nil;
    
    BOOL isTopmostElement = YES;
    BOOL isBelowLabel = NO;
    
    for (NSString *key in _inputKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            if (!constraints) {
                constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
            }
            
            NSString *constraint = nil;
            NSString *elementName = nil;
            
            if ([_cell labelForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixLabel];
            } else if ([_cell inputFieldForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixInputField];
            }
            
            if (isTopmostElement) {
                isTopmostElement = NO;
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, elementName, [UIFont detailFieldHeight]];
            } else {
                CGFloat spacing = isBelowLabel ? kDefaultCellPadding / 3 : 1.f;
                constraint = [NSString stringWithFormat:kVConstraintsElement, spacing, elementName, [UIFont detailFieldHeight]];
            }
            
            constraints = [constraints stringByAppendingString:constraint];
            isBelowLabel = [elementName hasSuffix:kViewKeySuffixLabel];
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : [NSArray array];
}


- (NSArray *)centredHorizontalConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    for (NSString *key in _inputKeys) {
        [self configureElementsForKey:key];
        
        if ([self shouldDisplayElementsForKey:key]) {
            NSString *constraint = nil;
            
            if ([_cell labelForKey:key]) {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixLabel];
                constraint = [NSString stringWithFormat:kHConstraintsCentredLabel, elementName];
            } else {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixInputField];
                constraint = [NSString stringWithFormat:kHConstraintsCentredInputField, elementName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


#pragma mark - Initialisation

- (instancetype)initWithCell:(OTableViewCell *)cell blueprint:(OTableViewCellBlueprint *)blueprint
{
    self = [super init];
    
    if (self) {
        _cell = cell;
        _blueprint = blueprint;
        
        _titleKey = [[self class] displayableKeysFromKeys:_blueprint.titleKey delegate:cell.inputDelegate];
        _detailKeys = [[self class] displayableKeysFromKeys:_blueprint.detailKeys delegate:cell.inputDelegate];
        
        if (_titleKey) {
            _inputKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _inputKeys = _detailKeys;
        }
        
        if (_blueprint.fieldsAreLabeled) {
            _labelWidth = [OLabel widthWithBlueprint:_blueprint];
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
        
        if (_blueprint.fieldsAreLabeled) {
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


#pragma mark - Cell height computation

- (CGFloat)heightOfCell
{
    return [[self class] heightOfCell:_cell withBlueprint:_blueprint entity:_cell.entity inputKeys:_inputKeys titleKey:_titleKey delegate:_cell.inputDelegate];
}


+ (CGFloat)heightOfCellWithReuseIdentifier:(NSString *)reuseIdentifier entity:(id)entity delegate:(id)delegate
{
    OTableViewCellBlueprint *blueprint = [[OTableViewCellBlueprint alloc] initWithReuseIdentifier:reuseIdentifier];
    
    NSString *titleKey = [self displayableKeysFromKeys:blueprint.titleKey delegate:delegate];
    NSArray *inputKeys = [self displayableKeysFromKeys:blueprint.inputKeys delegate:delegate];
    
    return [self heightOfCell:nil withBlueprint:blueprint entity:entity inputKeys:inputKeys titleKey:titleKey delegate:delegate];
}

@end
