//
//  OTableViewCellConstrainer.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellConstrainer.h"

static NSString * const kDelimitingSpace              = @"-10-";

static NSString * const kVConstraintsInitial          = @"V:|";
static NSString * const kVConstraintsInitialWithTitle = @"V:|-44-";

static NSString * const kVConstraintsElementTopmost   = @"[%@(%.f)]";
static NSString * const kVConstraintsElement          = @"-%.f-[%@(%.f)]";
static NSString * const kHConstraintsCentredLabel     = @"H:|-25-[%@]-25-|";
static NSString * const kHConstraintsCentredTextField = @"H:|-55-[%@]-55-|";

static NSString * const kVConstraintsTitleBanner      = @"V:|-(-1)-[titleBanner(39)]";
static NSString * const kHConstraintsTitleBanner      = @"H:|-(-1)-[titleBanner]-(-1)-|";
static NSString * const kVConstraintsTitle            = @"[%@(24)]";
static NSString * const kHConstraintsTitle            = @"H:|-6-[%@]-6-|";
static NSString * const kHConstraintsTitleWithPhoto   = @"H:|-6-[%@]-6-[photoFrame(%.f)]-10-|";
static NSString * const kVConstraintsPhoto            = @"V:|-10-[photoFrame(%.f)]";
static NSString * const kVConstraintsPhotoPrompt      = @"V:|-3-[photoPrompt]-3-|";
static NSString * const kHConstraintsPhotoPrompt      = @"H:|-3-[photoPrompt]-3-|";

static NSString * const kVConstraintsLabel            = @"-%.f-[%@(%.f)]";
static NSString * const kVConstraintsTextField        = @"[%@(%.f)]";

static NSString * const kHConstraints                 = @"H:|-10-[%@(%.f)]-3-[%@]-6-|";
static NSString * const kHConstraintsWithPhoto        = @"H:|-10-[%@(%.f)]-3-[%@]-6-[photoFrame]-10-|";


@implementation OTableViewCellConstrainer

#pragma mark - Auxiliary methods

- (BOOL)elementsAreVisibleForKey:(NSString *)key
{
    BOOL elementsAreVisible = YES;
    
    if (_cell.entity) {
        NSArray *entityAttributeKeys = [[[_cell.entity entity] attributesByName] allKeys];
        
        if ([entityAttributeKeys containsObject:key]) {
            id value = [_cell.entity valueForKey:key];
            
            if (value && [value isKindOfClass:[NSString class]]) {
                elementsAreVisible = [value hasValue];
            } else if (!value) {
                elementsAreVisible = NO;
            }
            
            elementsAreVisible = elementsAreVisible || [_cell.state actionIs:kActionInput];
        }
    }
    
    return elementsAreVisible;
}


- (void)configureElementsForKey:(NSString *)key
{
    id label = [_cell labelForKey:key];
    id textField = [_cell textFieldForKey:key];
    
    if ([self elementsAreVisibleForKey:key]) {
        if (label && [label isHidden]) {
            [label setHidden:NO];
        }
        
        if (textField && [textField isHidden]) {
            [textField setHidden:NO];
            
            id value = [_cell.entity valueForKey:key];
            
            if (value && ![textField textValue]) {
                if ([value isKindOfClass:[NSDate class]]) {
                    [textField setDate:value];
                } else {
                    [textField setText:value];
                }
            }
            
            if ([textField isKindOfClass:[OTextField class]]) {
                [textField raiseGuardAgainstUnwantedAutolayoutAnimation:NO]; // Bug workaround
            }
        }
    } else {
        if (label && ![label isHidden]) {
            [label setHidden:YES];
            [label setFrame:CGRectZero];
        }
        
        if (textField && ![textField isHidden]) {
            [textField setHidden:YES];
            [textField setFrame:CGRectZero];
        }
    }
}


#pragma mark - Generating visual constraints strings

- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (_blueprint.titleKey) {
        NSString *titleName = [_blueprint.titleKey stringByAppendingString:kViewKeySuffixTextField];
        
        [self configureElementsForKey:_blueprint.titleKey];
        
        [constraints addObject:kVConstraintsTitleBanner];
        [constraints addObject:kHConstraintsTitleBanner];
        
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
    id precedingTextField = nil;

    for (NSString *key in _blueprint.detailKeys) {
        [self configureElementsForKey:key];
        
        if ([self elementsAreVisibleForKey:key]) {
            if (!constraints) {
                if (_blueprint.titleKey) {
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
                
                if (precedingTextField && [precedingTextField isKindOfClass:[OTextView class]]) {
                    padding = [precedingTextField height] - [UIFont detailFieldHeight];
                }
                
                constraint = [NSString stringWithFormat:kVConstraintsLabel, padding, labelName, [UIFont detailFieldHeight]];
            }
            
            precedingTextField = [_cell textFieldForKey:key];
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints ? [NSArray arrayWithObject:constraints] : [NSArray array];
}


- (NSArray *)labeledVerticalTextFieldConstraints
{
    NSString *constraints = nil;
    
    if (_blueprint.titleKey) {
        NSString *titleName = [_blueprint.titleKey stringByAppendingString:kViewKeySuffixTextField];
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTitle, titleName];
        
        constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    if ([_blueprint.detailKeys count]) {
        BOOL didInsertDelimiter = !_blueprint.titleKey;
        
        for (NSString *key in _blueprint.detailKeys) {
            [self configureElementsForKey:key];
            
            if ([self elementsAreVisibleForKey:key]) {
                if (constraints && !didInsertDelimiter) {
                    constraints = [constraints stringByAppendingString:kDelimitingSpace];
                    
                    didInsertDelimiter = YES;
                } else if (!constraints) {
                    constraints = [kVConstraintsInitial stringByAppendingString:kDelimitingSpace];
                }
                
                id textField = [_cell textFieldForKey:key];
                
                CGFloat textFieldHeight = [UIFont detailFieldHeight];
                
                if ([textField isKindOfClass:[OTextView class]]) {
                    textFieldHeight = [textField height];
                }
                
                NSString *textFieldName = [key stringByAppendingString:kViewKeySuffixTextField];
                NSString *constraint = [NSString stringWithFormat:kVConstraintsTextField, textFieldName, textFieldHeight];
                
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
    
    for (NSString *key in _blueprint.detailKeys) {
        [self configureElementsForKey:key];
        
        if ([self elementsAreVisibleForKey:key]) {
            NSString *labelName = [key stringByAppendingString:kViewKeySuffixLabel];
            NSString *textFieldName = [key stringByAppendingString:kViewKeySuffixTextField];
            NSString *constraint = nil;
            
            if (_blueprint.hasPhoto && (rowNumber++ < 2)) {
                constraint = [NSString stringWithFormat:kHConstraintsWithPhoto, labelName, _labelWidth, textFieldName];
            } else {
                constraint = [NSString stringWithFormat:kHConstraints, labelName, _labelWidth, textFieldName];
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
    
    for (NSString *key in _blueprint.allTextFieldKeys) {
        [self configureElementsForKey:key];
        
        if ([self elementsAreVisibleForKey:key]) {
            if (!constraints) {
                constraints = kVConstraintsInitial;
            }
            
            NSString *constraint = nil;
            NSString *elementName = nil;
            
            if ([_cell labelForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixLabel];
            } else if ([_cell textFieldForKey:key]) {
                elementName = [key stringByAppendingString:kViewKeySuffixTextField];
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
    
    for (NSString *key in _blueprint.allTextFieldKeys) {
        [self configureElementsForKey:key];
        
        if ([self elementsAreVisibleForKey:key]) {
            NSString *constraint = nil;
            
            if ([_cell labelForKey:key]) {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixLabel];
                constraint = [NSString stringWithFormat:kHConstraintsCentredLabel, elementName];
            } else {
                NSString *elementName = [key stringByAppendingString:kViewKeySuffixTextField];
                constraint = [NSString stringWithFormat:kHConstraintsCentredTextField, elementName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


#pragma mark - Initialisation

- (id)initWithCell:(OTableViewCell *)cell blueprint:(OTableViewCellBlueprint *)blueprint;
{
    self = [super init];
    
    if (self) {
        _cell = cell;
        _blueprint = blueprint;
        
        if (_blueprint.fieldsAreLabeled) {
            _labelWidth = [OTextView labelWidthWithBlueprint:_blueprint];
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
            [nonAlignedConstraints addObjectsFromArray:[self labeledVerticalTextFieldConstraints]];
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

@end
